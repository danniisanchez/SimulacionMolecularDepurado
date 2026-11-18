param(
    [double]$Eta = 1.0,
    [decimal]$AMin = 0.25,
    [decimal]$AMax = 1.50,
    [decimal]$AStep = 0.25,
    # Todos los tiempos de este bloque son UNIDADES DE TIEMPO SIMULADO,
    # no numero de iteraciones. Con h=0.001, 300000 -> 300000000 pasos.
    [double]$TermMin = 100000,
    [double]$TermMax = 300000,
    [double]$MedMin = 300000,
    [double]$MedMax = 1000000,
    [double]$H = 0.001,
    [switch]$SinGraficas
)

# BARRIDO NUEVO tau(A) CON eta FIJO, F=0.
# NO importa O2_master.ps1. NO modifica src/ ni results/O2/ ni plots/O2/.
# Copia el C actual (incluido RAN2 si ya esta instalado) a una carpeta unica.
# Cada corrida crea resultados propios en experimentos/O2_barrido_A_eta_fija/...

$ErrorActionPreference = 'Stop'
$cultura = [System.Globalization.CultureInfo]::InvariantCulture
$raiz = $PSScriptRoot

function Num([double]$v) { return $v.ToString('G17', $cultura) }
function Nombre([double]$v) { return $v.ToString('G', $cultura) }
function CNum([double]$v) {
    $s = $v.ToString('G17', $cultura)
    if ($s -notmatch '[.eE]') { $s += '.0' }
    return $s
}
function Fija-Define([string]$texto, [string]$nombre, [string]$valor) {
    $patron = '(?m)^#define\s+' + [regex]::Escape($nombre) + '\s+\S+'
    if (-not [regex]::IsMatch($texto, $patron)) {
        throw "No existe #define $nombre en la copia de head.h. No se modifica ningun archivo original."
    }
    return [regex]::Replace($texto, $patron, "#define $nombre $valor")
}
function NumPasos([double]$tiempo, [double]$h) {
    $n = [Math]::Round($tiempo / $h)
    if ($n -lt 1 -or $n -ge 9223372036854770000.0) { throw "Presupuesto no valido: t=$tiempo, h=$h" }
    return [long]$n
}
function Leer-Caso([string]$ruta) {
    $lineas = @(Get-Content -LiteralPath $ruta | Where-Object { $_.Trim() -and -not $_.Trim().StartsWith('#') })
    if ($lineas.Count -ne 1) { throw "Se esperaba una unica fila de datos en $ruta" }
    $v = @($lineas[0].Trim() -split '\s+')
    if ($v.Count -ne 28) { throw "Resumen incompatible ($($v.Count) columnas, esperadas 28): $ruta" }
    return ,$v
}
function GP([string]$p) { return ([System.IO.Path]::GetFullPath($p)).Replace('\', '/') }

if ($Eta -le 0 -or $H -le 0 -or $AMin -le 0 -or $AMax -lt $AMin -or $AStep -le 0) {
    throw 'Parametros invalidos: eta>0, h>0 y 0<AMin<=AMax, AStep>0.'
}
if ($AStep -lt [decimal]0.01) { throw 'Para evitar colisiones del formato de nombres C (%g), usa AStep>=0.01.' }
if ($TermMin -le 0 -or $MedMin -le 0 -or $TermMax -lt $TermMin -or $MedMax -lt $MedMin) {
    throw 'Se requiere 0<TermMin<=TermMax y 0<MedMin<=MedMax.'
}
$termMinPasos = NumPasos $TermMin $H
$termMaxPasos = NumPasos $TermMax $H
$medMinPasos = NumPasos $MedMin $H
$medMaxPasos = NumPasos $MedMax $H

$listaA = @()
$valor = $AMin
while ($valor -le ($AMax + [decimal]0.00000001)) {
    $listaA += [double]$valor
    if ($listaA.Count -gt 100) { throw 'Demasiados valores de A; limita el barrido a 100.' }
    $valor += $AStep
}
if ($listaA.Count -lt 2) { throw 'Se necesitan al menos dos valores de A para un barrido.' }

$fuentes = @('head.h', 'main.c', 'funciones.c', 'random.c')
foreach ($f in $fuentes) {
    $p = Join-Path $raiz "src\$f"
    if (-not (Test-Path -LiteralPath $p)) { throw "Falta $p. Coloca este PS1 en la raiz del proyecto." }
}
$gcc = Get-Command 'gcc' -ErrorAction SilentlyContinue
if (-not $gcc) { throw 'No se encuentra gcc en PATH. Instalalo o agrega su carpeta bin al PATH.' }

# Usar carpeta irrepetible, sin borrar ni limpiar proyectos ni experimentos previos.
$ident = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
$run = Join-Path $raiz "experimentos\O2_barrido_A_eta_fija\$ident"
$srcCopia = Join-Path $run 'src'
$datos = Join-Path $run 'results\O2'
$datosCaso = Join-Path $datos 'Verlet'
$figuras = Join-Path $run 'plots\O2'
foreach ($directorio in @($srcCopia, $datosCaso, $figuras, (Join-Path $run 'logs'))) {
    New-Item -ItemType Directory -Path $directorio -Force | Out-Null
}
foreach ($f in $fuentes) {
    Copy-Item -LiteralPath (Join-Path $raiz "src\$f") -Destination (Join-Path $srcCopia $f)
}
$headBase = Get-Content -LiteralPath (Join-Path $srcCopia 'head.h') -Raw

$manifest = @(
    "# Barrido A independiente. Fecha: $(Get-Date -Format o)",
    '# Origen: los src/*.c actuales del proyecto; no se modifica el origen.',
    "# eta=$(Num $Eta) F=0 h=$(Num $H) A=$($listaA -join ',')",
    "# TERM_MIN=$termMinPasos TERM_MAX=$termMaxPasos MED_MIN=$medMinPasos MED_MAX=$medMaxPasos",
    '# Nota: TERM y MED del simulador usan parada adaptativa; limites maximos no son pasos forzosos.'
)
foreach ($f in $fuentes) {
    $sha = (Get-FileHash -LiteralPath (Join-Path $srcCopia $f) -Algorithm SHA256).Hash
    $manifest += "# src/$f SHA256=$sha"
}
$manifest | Set-Content -LiteralPath (Join-Path $run 'PROCEDENCIA.txt') -Encoding UTF8

$tabla = Join-Path $datos 'tau_vs_A_eta_fija.dat'
'# A tau_global tau_izq tau_der transiciones est_izq est_der TERM_usado MED_usado termOK statsOK globalOK P_izq P_der relerr_izq relerr_der err_ocupacion eta F' |
    Set-Content -LiteralPath $tabla -Encoding Ascii

Write-Host ''
Write-Host '======== NUEVO BARRIDO INDEPENDIENTE tau(A) ========' -ForegroundColor Cyan
Write-Host "Valores de A: $($listaA -join ', ')"
Write-Host "eta=$Eta, F=0, h=$H"
Write-Host "TERM: $TermMin .. $TermMax ; MED: $MedMin .. $MedMax (tiempo simulado)"
Write-Host "Carpeta nueva: $run"
Write-Host 'Los resultados previos de O2 y el barrido de fuerza NO se modifican.'
Write-Host ''

Push-Location -LiteralPath $run
try {
    foreach ($a in $listaA) {
        $head = $headBase
        $reemplazos = @{
            'A' = (CNum $a)
            'KBT' = '0.2'
            'eta' = (CNum $Eta)
            'FEXT' = '0.0'
            'paso_h' = (CNum $H)
            'flag' = '2'
            'flag_Objetivo' = '2'
            'TERM_MIN_STEPS' = "${termMinPasos}L"
            'termSteps' = "${termMaxPasos}L"
            'MEASURE_MIN_STEPS' = "${medMinPasos}L"
            'numberSteps' = "${medMaxPasos}L"
            'TERM_FIXED_STEPS_MODE' = '0'
            'MEASURE_FORCE_MAX' = '0'
        }
        foreach ($key in $reemplazos.Keys) { $head = Fija-Define $head $key $reemplazos[$key] }
        $enc = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText((Join-Path $srcCopia 'head.h'), $head, $enc)
        $tag = Nombre $a
        Copy-Item -LiteralPath (Join-Path $srcCopia 'head.h') -Destination (Join-Path $run "logs\head_A${tag}.h")

        Write-Host "[COMPILANDO] A=$tag, eta=$(Nombre $Eta), F=0" -ForegroundColor Yellow
        & $gcc.Source 'src/main.c' 'src/funciones.c' 'src/random.c' '-O2' '-std=c11' '-lm' '-o' 'O2_barrido_A.exe'
        if ($LASTEXITCODE -ne 0) { throw "Fallo de compilacion para A=$tag" }
        $registro = Join-Path $run "logs\A${tag}.log"
        Write-Host "[SIMULANDO] A=$tag"
        & '.\O2_barrido_A.exe' 2>&1 | Tee-Object -FilePath $registro | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Fallo ejecutando A=$tag. Registro: $registro" }

        $encontrados = @(Get-ChildItem -LiteralPath $datosCaso -Filter "resumen_h*_A${tag}_eta$(Nombre $Eta)_F0_XC*.txt" -File)
        if ($encontrados.Count -ne 1) {
            throw "No se ha encontrado un resumen UNICO para A=$tag, eta=$Eta, F=0; encontrados=$($encontrados.Count)"
        }
        $c = Leer-Caso $encontrados[0].FullName
        $resA = [double]::Parse($c[1], $cultura)
        $resEta = [double]::Parse($c[2], $cultura)
        $resF = [double]::Parse($c[13], $cultura)
        if ([Math]::Abs($resA-$a) -gt 1e-8 -or [Math]::Abs($resEta-$Eta) -gt 1e-8 -or [Math]::Abs($resF) -gt 1e-10) {
            throw "Los parametros no coinciden en resumen A=$tag."
        }
        $indices = @(11,9,10,6,7,8,14,15,16,17,27,4,5,25,26,24,2,13)
        $fila = @($tag)
        foreach ($i in $indices) { $fila += $c[$i] }
        ($fila -join ' ') | Add-Content -LiteralPath $tabla -Encoding Ascii

        if ($c[16] -ne '1' -or $c[17] -ne '1' -or $c[27] -ne '1') {
            Write-Warning "A=${tag}: convergencia incompleta (TERM=$($c[16]), STATS=$($c[17]), GLOBAL=$($c[27])). Se conserva y etiqueta."
        }
        Write-Host "[OK] A=$tag; tau_global=$($c[11]); transiciones=$($c[6]); TERM=$($c[14]) pasos; MED=$($c[15]) pasos" -ForegroundColor Green
    }
} finally {
    Pop-Location
}

# Graficas y datos derivados viven exclusivamente en la carpeta nueva.
$plts = Join-Path $figuras 'tau_vs_A_eta_fija.plt'
$gcode = @'
reset
set terminal pngcairo size 1450,850 enhanced font 'Arial,14'
set grid
set key left top
set xlabel 'A (altura de la barrera)'
set ylabel 'Tiempo medio de estancia tau'
set title 'O2: tau(A) con eta=__ETA__, F=0'
set datafile commentschars '#'
set output '__PLOT_LOG__'
set logscale y
plot '__DATA__' using 1:($2>0 && $10==1 && $11==1 && $12==1 ? $2 : 1/0) with linespoints lw 2 pt 7 ps 1.5 title 'Convergencia completa', \
     '__DATA__' using 1:($2>0 && ($10!=1 || $11!=1 || $12!=1) ? $2 : 1/0) with points pt 4 ps 2 lw 2 title 'Convergencia insuficiente'
unset logscale y
set output '__PLOT_LIN__'
plot '__DATA__' using 1:($2>0 && $10==1 && $11==1 && $12==1 ? $2 : 1/0) with linespoints lw 2 pt 7 ps 1.5 title 'Convergencia completa', \
     '__DATA__' using 1:($2>0 && ($10!=1 || $11!=1 || $12!=1) ? $2 : 1/0) with points pt 4 ps 2 lw 2 title 'Convergencia insuficiente'
unset output
'@
$gcode = $gcode.Replace('__ETA__', (Nombre $Eta)).Replace('__DATA__', (GP $tabla))
$gcode = $gcode.Replace('__PLOT_LOG__', (GP (Join-Path $figuras 'tau_vs_A_log.png')))
$gcode = $gcode.Replace('__PLOT_LIN__', (GP (Join-Path $figuras 'tau_vs_A_lineal.png')))
$gcode | Set-Content -LiteralPath $plts -Encoding Ascii

if (-not $SinGraficas) {
    $gnu = Get-Command gnuplot -ErrorAction SilentlyContinue
    $gnuExe = if ($gnu) { $gnu.Source } else { 'C:\Program Files\gnuplot\bin\gnuplot.exe' }
    if (Test-Path -LiteralPath $gnuExe) {
        & $gnuExe $plts
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Gnuplot ha fallado. Los datos y el .plt siguen guardados.' }
    } else {
        Write-Warning 'Gnuplot no encontrado. Se ha creado el .plt para lanzarlo mas adelante.'
    }
}
Write-Host ''
Write-Host "[TERMINADO] Tabla: $tabla" -ForegroundColor Green
Write-Host "[TERMINADO] Graficas (si hay Gnuplot): $figuras" -ForegroundColor Green
Write-Host '[PROTECCION] O2_master, los fuentes originales y results/O2/resumen_F.dat siguen intactos.'
