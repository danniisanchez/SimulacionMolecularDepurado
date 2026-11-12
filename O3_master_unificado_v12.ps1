param(
    [switch]$SoloGraficas,
    [switch]$SinGraficas,
    [switch]$SoloTermalizacion,
    [switch]$SaltarEstudioTermalizacion,
    [switch]$SoloEta,
    [double]$AetaFixed = 0.0
)

# ============================================================
# OBJETIVO 2 - PRODUCCION LARGA AUDITADA v13 - SIEMPRE DATOS NUEVOS
#
# Ejecutar desde la raiz del repositorio:
#   .\O2_master.ps1
#
# Modos:
#   .\O2_master.ps1 -SoloGraficas
#   .\O2_master.ps1 -SinGraficas
#
# Nucleo esperado:
#   src/main.c
#   src/funciones.c
#   src/random.c
#   src/head.h
#
# Resultados canonicos generados:
#   results/O2/resumen_A.dat
#   results/O2/resumen_eta.dat
#   results/O2/resumen_F.dat
#   results/O2/analisis/*
#
# Los .plt auditados leen SOLO esos nombres estables.
# IMPORTANTE: esta version NO reutiliza resultados anteriores al simular.
# Cada caso borra sus salidas previas y se ejecuta de nuevo.
# ============================================================

$ErrorActionPreference = "Stop"

# Ruta absoluta a Gnuplot
$gnuplotExe = "C:\Program Files\gnuplot\bin\gnuplot.exe"
$projectRoot = $PSScriptRoot
$scriptDirO2 = Join-Path $projectRoot "scriptsGnuplot\O2"

$headPath = "src\head.h"
$exe = "O2_master.exe"
$metodo = "Verlet"

$h = 0.001
$XC = 0.2

# Barridos v8: mas extremos + mas puntos intermedios.
# A: desde barrera muy baja (0.25) hasta barrera rara (2.2).
$Avals = @(0.25,0.35,0.5,0.6,0.7,0.8,0.9,1.0,1.1,1.2,1.3,1.4,1.5,1.6,1.8,2.0,2.2)

# eta revisado para estudiar tau(eta) en ejes lineales.
# Incluye el rango literal del enunciado [0.01,5] y la zona de baja friccion.
# Para A=2, los extremos pueden dar estadistica insuficiente: se registrara tal cual.
$Etavals = @(0.01,0.03,0.05,0.1,0.2,0.3,0.5,0.75,1.0,1.25,1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0)
$EtaFitMin = 1.0

# Campaña controlada de termalización.
$TermScanSteps = @(1000000L,5000000L,10000000L,20000000L,50000000L)
$TermMinProduccion = 100000000L

# Presupuesto MANUAL comun para los tres barridos tau(eta).
# Se mantiene idéntico para A=0.5, 1 y 2 para que A=2 pueda fallar
# honestamente bajo el mismo coste computacional.
$EtaManualTermMax    = 300000000L
$EtaManualMeasureMax = 1000000000L


# Fuerza: paso 0.05 desde -0.5 hasta +0.5.
# Para A_force=0.5 el barrido de fuerza se mantiene como estaba; NO elimina
# matematicamente uno de los pozos (Fcrit ~= 0.7698).
$Fvals = @(-0.50,-0.45,-0.40,-0.35,-0.30,-0.25,-0.20,-0.15,-0.10,-0.05,
           0.00,
           0.05,0.10,0.15,0.20,0.25,0.30,0.35,0.40,0.45,0.50)

$eta_ASweep = 1.0
$A_force = 0.5
$eta_force = 1.0

# Caso canonico para energia, histograma, trayectoria y distribucion de estancias.
# Caso de referencia mantenido como antes: A=0.5, eta=1, F=0.
$Aref = 0.5
$Etaref = 1.0
$Fref = 0.0

function G([double]$x) {
    # Formato para nombres de archivo: compacto, sin cambiar 1.0 -> 1
    return $x.ToString("G17",[System.Globalization.CultureInfo]::InvariantCulture)
}

function CFloat([double]$x) {
    # Literal C SIEMPRE de punto flotante.
    # Evita que eta=1 se convierta en macro entero y rompa printf("%g", eta).
    $s=$x.ToString("G17",[System.Globalization.CultureInfo]::InvariantCulture)
    if(($s -notmatch '[\.eE]')) { $s += ".0" }
    return $s
}

function FName([double]$x) {
    # Convencion de nombres compatible con %g de C para los valores del barrido.
    return $x.ToString("G",[System.Globalization.CultureInfo]::InvariantCulture)
}

function Ensure-Dirs {
    @(
      "results\O2",
      "results\O2\Verlet",
      "results\O2\analisis",
      "plots\O2",
      "plots\O2\Verlet",
      "plots\O2\Trayectorias",
      "results\O2\termalizacion_scan",
      "plots\O2\TermalizacionScan"
    ) | ForEach-Object {
        New-Item -ItemType Directory -Force -Path $_ | Out-Null
    }
}

function Get-Limits([double]$Aval,[double]$Etaval,[double]$Fval) {
    # Configuracion larga actualmente usada.
    [long]$termMax = 300000000
    [long]$measMax = 1000000000
    $clase = "normal"

    if(($Aval -ge 1.4) -or ($Etaval -le 0.03) -or ($Etaval -ge 5.0)) {
        $termMax = 600000000
        $measMax = 1000000000
        $clase = "dificil"
    }

    # Para los barridos manuales eta esta rama NO se usa: se impone
    # el mismo presupuesto a A=0.5, 1 y 2.
    if(($Aval -ge 1.8) -or ($Etaval -le 0.01) -or ($Etaval -ge 10.0)) {
        $termMax = 600000000
        $measMax = 1000000000
        $clase = "extremo"
    }

    return [PSCustomObject]@{
        TermMax = $termMax
        MeasureMax = $measMax
        Clase = $clase
    }
}

function Set-Head(
    [double]$Aval,[double]$Etaval,[double]$Fval,
    [long]$TermMinOverride=0,
    [long]$TermMaxOverride=0,
    [long]$MeasureMaxOverride=0,
    [int]$TermFixedMode=0,
    [int]$MeasureForceMax=0
) {
    $base = $script:originalHead
    $base = $base -replace '#define\s+A\s+[-+0-9.eE]+',      "#define A $(CFloat $Aval)"
    $base = $base -replace '#define\s+eta\s+[-+0-9.eE]+',    "#define eta $(CFloat $Etaval)"
    $base = $base -replace '#define\s+FEXT\s+[-+0-9.eE]+',   "#define FEXT $(CFloat $Fval)"
    $base = $base -replace '#define\s+paso_h\s+[-+0-9.eE]+', "#define paso_h $(CFloat $h)"
    $base = $base -replace '#define\s+flag\s+\d+',            "#define flag 2"
    $base = $base -replace '#define\s+flag_Objetivo\s+\d+',   "#define flag_Objetivo 2"

    $lim = Get-Limits $Aval $Etaval $Fval

    [long]$termMin = $TermMinProduccion
    [long]$termMax = $lim.TermMax
    [long]$measureMax = $lim.MeasureMax
    [long]$measureMin = 300000000L

    if($TermMinOverride -gt 0) { $termMin = $TermMinOverride }
    if($TermMaxOverride -gt 0) { $termMax = $TermMaxOverride }
    if($MeasureMaxOverride -gt 0) { $measureMax = $MeasureMaxOverride }
    if($termMax -lt $termMin) { $termMax = $termMin }
    if($TermFixedMode -eq 1 -and $MeasureForceMax -eq 1) {
        # SOLO estudio metodologico de termalizacion; no es corrida de produccion.
        $measureMin=$measureMax
    }

    $base = $base -replace '#define\s+TERM_MIN_STEPS\s+\d+L', "#define TERM_MIN_STEPS ${termMin}L"
    $base = $base -replace '#define\s+termSteps\s+\d+L',       "#define termSteps ${termMax}L"
    $base = $base -replace '#define\s+numberSteps\s+\d+L',     "#define numberSteps ${measureMax}L"
    $base = $base -replace '#define\s+MEASURE_MIN_STEPS\s+\d+L', "#define MEASURE_MIN_STEPS ${measureMin}L"
    $base = $base -replace '#define\s+TERM_FIXED_STEPS_MODE\s+[01]', "#define TERM_FIXED_STEPS_MODE $TermFixedMode"
    $base = $base -replace '#define\s+MEASURE_FORCE_MAX\s+[01]', "#define MEASURE_FORCE_MAX $MeasureForceMax"

    Write-Host "Clase: $($lim.Clase) | TERM_MIN=$termMin | TERM_MAX=$termMax | MEASURE_MIN=$measureMin | MEASURE_MAX=$measureMax"
    Write-Host "TERM_FIXED=$TermFixedMode | MEASURE_FORCE_MAX=$MeasureForceMax"
    Set-Content $headPath $base -Encoding UTF8

    # Auditoria inmediata: no compilar si head.h no contiene exactamente
    # los parametros que acabamos de pedir. Esto detecta el antiguo bug eta=1.
    $written=Get-Content $headPath -Raw
    $etaExpected=[regex]::Escape((CFloat $Etaval))
    $aExpected=[regex]::Escape((CFloat $Aval))
    $fExpected=[regex]::Escape((CFloat $Fval))
    if($written -notmatch "(?m)^#define\s+eta\s+$etaExpected\s*$") { throw "head.h no escribio eta=$(CFloat $Etaval)" }
    if($written -notmatch "(?m)^#define\s+A\s+$aExpected\s*$") { throw "head.h no escribio A=$(CFloat $Aval)" }
    if($written -notmatch "(?m)^#define\s+FEXT\s+$fExpected\s*$") { throw "head.h no escribio FEXT=$(CFloat $Fval)" }
    if($written -notmatch "(?m)^#define\s+TERM_MIN_STEPS\s+${termMin}L\s*$") { throw "TERM_MIN_STEPS incorrecto" }
    if($written -notmatch "(?m)^#define\s+termSteps\s+${termMax}L\s*$") { throw "termSteps incorrecto" }
    if($written -notmatch "(?m)^#define\s+MEASURE_MIN_STEPS\s+${measureMin}L\s*$") { throw "MEASURE_MIN_STEPS incorrecto" }
    if($written -notmatch "(?m)^#define\s+numberSteps\s+${measureMax}L\s*$") { throw "numberSteps incorrecto" }
}

function Summary-Candidates([double]$Aval,[double]$Etaval,[double]$Fval) {
    $hh=FName $h; $a=FName $Aval; $e=FName $Etaval; $f=FName $Fval; $xc=FName $XC
    $dir="results\O2\$metodo"

    # Formato canonico UNICO: nunca usar resumen sin F ni 13 columnas.
    return @("$dir\resumen_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt")
}

function Resolve-Summary([double]$Aval,[double]$Etaval,[double]$Fval) {
    # Solo se aceptan nombres exactos del caso solicitado.
    # Se elimina deliberadamente el fallback por A/eta para impedir que un
    # resultado viejo de otro F pueda confundirse con la corrida nueva.
    foreach($p in (Summary-Candidates $Aval $Etaval $Fval)) {
        if(Test-Path $p) { return $p }
    }
    return $null
}

function Clear-CaseOutputs([double]$Aval,[double]$Etaval,[double]$Fval) {
    $hh=FName $h
    $a=FName $Aval
    $e=FName $Etaval
    $f=FName $Fval
    $xc=FName $XC
    $dir="results\O2\$metodo"

    # Nombres modernos y compatibilidad con salidas antiguas sin F.
    $patterns=@(
        "resumen_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
        "resumen_h${hh}_A${a}_eta${e}_XC${xc}.txt",
        "tiempos_derecha_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
        "tiempos_derecha_h${hh}_A${a}_eta${e}_XC${xc}.txt",
        "tiempos_izquierda_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
        "tiempos_izquierda_h${hh}_A${a}_eta${e}_XC${xc}.txt",
        "datosEnergia_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
        "datosEnergia_h${hh}_A${a}_eta${e}_${metodo}.txt",
        "datosTrayectoria_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
        "datosTrayectoria_h${hh}_A${a}_eta${e}_${metodo}.txt",
        "datosTrayectoriaZoom_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
        "Histogramas_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
        "Histogramas_h${hh}_A${a}_eta${e}_${metodo}.txt",
        "termalizacion_bloques_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
        "termalizacion_bloques_h${hh}_A${a}_eta${e}_XC${xc}.txt"
    )

    $deleted=0
    foreach($name in $patterns) {
        $p=Join-Path $dir $name
        if(Test-Path $p) {
            Remove-Item -Force $p
            $deleted++
        }
    }

    if($deleted -gt 0) {
        Write-Host "[DATOS NUEVOS] Eliminadas $deleted salidas antiguas del caso A=$(FName $Aval), eta=$(FName $Etaval), F=$(FName $Fval)."
    }
    else {
        Write-Host "[DATOS NUEVOS] No habia salidas previas para este caso."
    }
}

function Run-Case(
    [double]$Aval,[double]$Etaval,[double]$Fval,
    [long]$TermMinOverride=0,
    [long]$TermMaxOverride=0,
    [long]$MeasureMaxOverride=0,
    [int]$TermFixedMode=0,
    [int]$MeasureForceMax=0,
    [switch]$ForceRun   # conservado solo por compatibilidad; todos los casos se fuerzan
) {
    # PRODUCCION FRESCA OBLIGATORIA:
    # nunca se reutiliza un resumen anterior. Se borran solamente las salidas
    # correspondientes a ESTE caso antes de compilar y ejecutar de nuevo.
    Clear-CaseOutputs $Aval $Etaval $Fval

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "O2: A=$(G $Aval)   eta=$(G $Etaval)   F=$(G $Fval)"
    Write-Host "============================================================"

    Set-Head $Aval $Etaval $Fval $TermMinOverride $TermMaxOverride $MeasureMaxOverride $TermFixedMode $MeasureForceMax

    # Comprobacion visible de macros escritos en head.h
    $defs = Select-String -Path $headPath -Pattern '^#define\s+(A|eta|FEXT|paso_h|TERM_MIN_STEPS|termSteps|numberSteps|TERM_FIXED_STEPS_MODE|MEASURE_FORCE_MAX)\s+' |
            ForEach-Object { $_.Line.Trim() }
    Write-Host "Parametros C:"
    $defs | ForEach-Object { Write-Host "  $_" }

    gcc src\main.c src\funciones.c src\random.c -O2 -std=c11 -lm -o $exe 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Error compilando A=$Aval eta=$Etaval F=$Fval"
    }

    & ".\$exe" | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Error ejecutando A=$Aval eta=$Etaval F=$Fval"
    }

    $summary=Resolve-Summary $Aval $Etaval $Fval

    if (!$summary) {
        Write-Host ""
        Write-Host "Resúmenes encontrados en results\O2\$metodo :"
        Get-ChildItem "results\O2\$metodo" -Filter "resumen_*.txt" -ErrorAction SilentlyContinue |
          Select-Object -ExpandProperty Name |
          ForEach-Object { Write-Host "  $_" }

        throw "La simulacion termino, pero no se encontro resumen compatible para A=$Aval eta=$Etaval F=$Fval."
    }

    $c = Read-Summary $summary
    $parseCI=[System.Globalization.CultureInfo]::InvariantCulture
    foreach($k in @(@(1,$Aval,'A'),@(2,$Etaval,'eta'),@(13,$Fval,'F'))) {
        $actual=[double]::Parse($c[[int]$k[0]],$parseCI)
        if([Math]::Abs($actual-[double]$k[1]) -gt 1e-9) {
            throw "Resumen ${summary}: valor $($k[2])=$actual, solicitado $($k[1]). No se permite confundir corridas."
        }
    }
    [long]$minExpected=300000000L
    if($TermFixedMode -eq 1 -and $MeasureForceMax -eq 1) {
        # Excepcion EXPLICITA: exploracion de termalizacion a igual duracion
        # de medida de diagnostico; NO son puntos de produccion O2.
        $minExpected=$MeasureMaxOverride
    }
    if([long]$c[14] -lt 1 -or [long]$c[15] -lt $minExpected) {
        throw "La ejecucion devolvio menos de $minExpected pasos de medida; revisar nucleo/compilacion."
    }
    # Los productos del caso deben pertenecer a esta misma corrida. No aceptar nombres sin F.
    $hh=FName $h; $a=FName $Aval; $e=FName $Etaval; $ff=FName $Fval; $xx=FName $XC
    $outDir="results\O2\$metodo"
    $required=@(
      "$outDir\datosEnergia_h${hh}_A${a}_eta${e}_F${ff}_${metodo}.txt",
      "$outDir\datosTrayectoria_h${hh}_A${a}_eta${e}_F${ff}_${metodo}.txt",
      "$outDir\datosTrayectoriaZoom_h${hh}_A${a}_eta${e}_F${ff}_${metodo}.txt",
      "$outDir\Histogramas_h${hh}_A${a}_eta${e}_F${ff}_${metodo}.txt",
      "$outDir\tiempos_derecha_h${hh}_A${a}_eta${e}_F${ff}_XC${xx}.txt",
      "$outDir\tiempos_izquierda_h${hh}_A${a}_eta${e}_F${ff}_XC${xx}.txt",
      "$outDir\termalizacion_bloques_h${hh}_A${a}_eta${e}_F${ff}_XC${xx}.txt"
    )
    foreach($p in $required) {
        if(!(Test-Path $p)) { throw "Falta un producto obligatorio de la corrida nueva: $p. Verificar nombres de salida en src/funciones.c." }
    }
    foreach($p in @($required[0],$required[1],$required[2],$required[3],$required[6])) {
        if((Get-Item $p).Length -eq 0) { throw "Producto vacio de la corrida: $p" }
    }
    Write-Host "[OK] Resumen de 28 columnas, parametros y productos del caso verificados: $summary"
    if($c[16] -ne '1' -or $c[17] -ne '1' -or $c[27] -ne '1') {
        Write-Warning "Caso A=$Aval eta=$Etaval F=$Fval sin convergencia COMPLETA: TERM=$($c[16]), STATS=$($c[17]), TERM_GLOBAL=$($c[27]). Se conserva con indicadores, no se considera dato validado."
    }
    return [string]$summary
}

function Read-Summary([string]$file) {
    $line = Get-Content $file |
            Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
            Select-Object -Last 1

    if (!$line) { throw "Resumen vacio: $file" }

    $c = ($line.Trim() -split '\s+') | Where-Object { $_ -ne "" }

    if ($c.Count -ne 28) {
        throw "RESUMEN INCOMPATIBLE: $file tiene $($c.Count) columnas; el contrato O2 v13 exige EXACTAMENTE 28. No se admiten resúmenes antiguos."
    }
    # El contrato incluye columnas 17,18,28 (1-based) de control de calidad.
    foreach($i in @(16,17,27)) {
        if($c[$i] -notin @('0','1')) {
            throw "Indicador de convergencia invalido en columna $($i+1) de ${file}: $($c[$i])"
        }
    }
    return ,$c
}

function Add-AggregateRow([string]$out,[double]$param,[string[]]$c) {
    if($c.Count -ne 28) { throw "El agregado exige 28 columnas; recibido $($c.Count)." }
    # Del resumen C: h,A,eta,XC,Pizq,Pder,trans,Nizq,Nder,tauIzq,tauDer,
    # tauGlobal,kSim,FEXT,termN,medN,termOK,statsOK,dEk,dEp,dX2,Pth,
    # errTerm,transTerm,errMed,relErrIzq,relErrDer,globalOK.
    # Agregado: columna 1 = variable barrida; columnas 2..24 = resultados.
    $indices=@(4,5,6,7,8,9,10,11,12,14,15,16,17,18,19,20,21,22,23,24,25,26,27)
    $v=@((FName $param))
    foreach($j in $indices){ $v += $c[$j] }
    ($v -join ' ') | Add-Content $out -Encoding Ascii
}

function First-Existing([string[]]$paths) {
    foreach($p in $paths) {
        if(Test-Path $p) { return $p }
    }
    return $null
}

function Make-Reference-Aliases {
    $base="results\O2\$metodo"
    $a=FName $Aref; $e=FName $Etaref; $f=FName $Fref; $hh=FName $h; $xc=FName $XC

    $summary=Resolve-Summary $Aref $Etaref $Fref
    $right="$base\tiempos_derecha_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"
    $left="$base\tiempos_izquierda_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"
    $energy="$base\datosEnergia_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $traj="$base\datosTrayectoria_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $hist="$base\Histogramas_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $zoom="$base\datosTrayectoriaZoom_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"

    $pairs=@(
      @($summary,"results\O2\analisis\resumen_referencia.txt"),
      @($right,"results\O2\analisis\tiempos_derecha.dat"),
      @($left,"results\O2\analisis\tiempos_izquierda.dat"),
      @($energy,"results\O2\analisis\energia.dat"),
      @($traj,"results\O2\analisis\trayectoria.dat"),
      @($hist,"results\O2\analisis\histograma.dat"),
      @($zoom,"results\O2\analisis\trayectoria_zoom.dat")
    )

    foreach($p in $pairs) {
        if(!$p[0] -or !(Test-Path $p[0])) { throw "Falta un archivo de referencia reciente: $($p[0])" }
        Copy-Item -Force $p[0] $p[1]
    }

    "# A eta F h XC KBT`n$(G $Aref) $(G $Etaref) $(G $Fref) $(G $h) $(G $XC) 0.2" |
      Set-Content "results\O2\analisis\parametros.dat" -Encoding UTF8
}



function Histogram-Path([double]$Aval,[double]$Etaval,[double]$Fval) {
    $a=FName $Aval; $e=FName $Etaval; $f=FName $Fval; $hh=FName $h
    $path="results\O2\$metodo\Histogramas_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    if(Test-Path $path) { return $path }
    return $null
}

function Boltzmann-L1([string]$hist,[double]$Aval,[double]$Fval) {
    $rows=@()
    foreach($line in Get-Content $hist) {
        if($line.Trim() -eq "" -or $line -match '^\s*#') { continue }
        $c=$line.Trim() -split '\s+'
        if($c.Count -ge 2) {
            $x=[double]::Parse($c[0],[System.Globalization.CultureInfo]::InvariantCulture)
            $p=[double]::Parse($c[1],[System.Globalization.CultureInfo]::InvariantCulture)
            $rows += [PSCustomObject]@{x=$x;p=$p}
        }
    }
    if($rows.Count -lt 2) { return $null }

    $dx=$rows[1].x-$rows[0].x
    $dI=0.001
    $Z=0.0
    for($i=-3000;$i -le 3000;$i++) {
        $x=$i*$dI
        $V=$Aval*($x*$x-1.0)*($x*$x-1.0)-$Fval*$x
        $Z += [Math]::Exp(-$V/0.2)*$dI
    }

    $l1=0.0
    $area=0.0
    foreach($r in $rows) {
        $V=$Aval*($r.x*$r.x-1.0)*($r.x*$r.x-1.0)-$Fval*$r.x
        $pth=[Math]::Exp(-$V/0.2)/$Z
        $l1 += [Math]::Abs($r.p-$pth)*$dx
        $area += $r.p*$dx
    }
    return [PSCustomObject]@{L1=$l1;Area=$area}
}

function Run-TermalizacionScan {
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "ESTUDIO CONTROLADO DE TERMALIZACION: A=1 eta=1 F=0"
    Write-Host "============================================================"

    $scanOut="results\O2\termalizacion_scan\resumen_termalizacion.dat"
    "# term_min term_used L1_Px area_hist term_converged term_global_ok stats_converged" |
        Set-Content $scanOut -Encoding UTF8

    foreach($nterm in $TermScanSteps) {
        [long]$termMax=[Math]::Max(100000000,[long]$nterm+50000000)
        [long]$measureMax=100000000

        $file=Run-Case 1.0 1.0 0.0 $nterm $termMax $measureMax 1 1 -ForceRun
        $c=Read-Summary $file
        $hist=Histogram-Path 1.0 1.0 0.0
        if(!$hist) { throw "No se encontro histograma para el estudio de termalizacion." }

        $metric=Boltzmann-L1 $hist 1.0 0.0
        $tag="term$($nterm)"
        Copy-Item -Force $hist "results\O2\termalizacion_scan\Histogramas_${tag}.txt"
        Copy-Item -Force $file "results\O2\termalizacion_scan\resumen_${tag}.txt"

        $termUsed=if($c.Count -ge 16){$c[14]}else{"nan"}
        $termConv=if($c.Count -ge 18){$c[16]}else{"nan"}
        $statsConv=if($c.Count -ge 18){$c[17]}else{"nan"}
        $global=if($c.Count -ge 28){$c[27]}else{"nan"}

        $l1s=$metric.L1.ToString("G12",[System.Globalization.CultureInfo]::InvariantCulture)
        $areas=$metric.Area.ToString("G12",[System.Globalization.CultureInfo]::InvariantCulture)
        "$(FName $nterm) $termUsed $l1s $areas $termConv $global $statsConv" |
            Add-Content $scanOut -Encoding UTF8

        Plot-Case 1.0 1.0 0.0
        $p0="plots\O2\Detalles\hist_posicion\Px_A1_eta1_F0.png"
        if(Test-Path $p0) { Copy-Item -Force $p0 "plots\O2\TermalizacionScan\Px_${tag}.png" }
    }
    Write-Host "[OK] $scanOut"
}

function GPPath([string]$p) {
    # Windows PowerShell 5.1: GetFullPath(ruta_relativa) puede usar el
    # directorio de trabajo de .NET, diferente del pwd de PowerShell.
    # Anclar TODAS las rutas relativas a la raiz real del proyecto.
    if ([System.IO.Path]::IsPathRooted($p)) {
        $rutaAbs = $p
    } else {
        $rutaAbs = Join-Path $projectRoot $p
    }
    return ([System.IO.Path]::GetFullPath($rutaAbs)).Replace('\','/')
}

function Plot-Case([double]$Aval,[double]$Etaval,[double]$Fval) {
    if (!(Test-Path $gnuplotExe)) { return }
    $summary=Resolve-Summary $Aval $Etaval $Fval
    if(!$summary) { return }
    $qc=Read-Summary $summary
    $valid=if($qc[16] -eq '1' -and $qc[17] -eq '1' -and $qc[27] -eq '1') { 1 } else { 0 }

    $a=FName $Aval
    $e=FName $Etaval
    $f=FName $Fval
    $hh=FName $h
    $xc=FName $XC

    $baseData = Join-Path $projectRoot "results\O2\$metodo"
    $basePlot = Join-Path $projectRoot "plots\O2\Detalles"
    $scriptBase = Join-Path $projectRoot "scriptsGnuplot\O2"

    $dirHist = Join-Path $basePlot "hist_posicion"
    $dirTau  = Join-Path $basePlot "tiempos"
    $dirEn   = Join-Path $basePlot "energia"
    $dirTr   = Join-Path $basePlot "trayectorias"
    $dirTerm = Join-Path $basePlot "termalizacion"

    New-Item -ItemType Directory -Force -Path $dirHist | Out-Null
    New-Item -ItemType Directory -Force -Path $dirTau  | Out-Null
    New-Item -ItemType Directory -Force -Path $dirEn   | Out-Null
    New-Item -ItemType Directory -Force -Path $dirTr   | Out-Null
    New-Item -ItemType Directory -Force -Path $dirTerm | Out-Null

    $hist = Join-Path $baseData "Histogramas_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $tr   = Join-Path $baseData "datosTrayectoria_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $zoom = Join-Path $baseData "datosTrayectoriaZoom_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $en   = Join-Path $baseData "datosEnergia_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $td   = Join-Path $baseData "tiempos_derecha_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"
    $ti   = Join-Path $baseData "tiempos_izquierda_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"
    $tb   = Join-Path $baseData "termalizacion_bloques_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"

    # Deliberadamente NO usar archivos antiguos sin F (riesgo de mezclar corridas).

    $plotTag = "A${a}_eta${e}_F${f}"

    $sHist = Join-Path $scriptBase "O2_C01_hist_posicion_caso.plt"
    $sTau  = Join-Path $scriptBase "O2_C02_tiempos_estancia_caso.plt"
    $sEn   = Join-Path $scriptBase "O2_C03_energia_caso.plt"
    $sTr   = Join-Path $scriptBase "O2_C04_trayectoria_caso.plt"
    $sTerm = Join-Path $scriptBase "O2_C05_termalizacion_bloques_caso.plt"

    if ((Test-Path $sHist) -and (Test-Path $hist)) {
        $in  = GPPath $hist
        $out = GPPath (Join-Path $dirHist "Px_${plotTag}.png")
        $scr = GPPath $sHist
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; KBT=0.2; VALID=$valid" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo Px para $plotTag" }
    }

    if ((Test-Path $sTau) -and (Test-Path $td) -and (Test-Path $ti) -and
        (Get-Item $td).Length -gt 0 -and (Get-Item $ti).Length -gt 0) {
        $r   = GPPath $td
        $l   = GPPath $ti
        $out = GPPath (Join-Path $dirTau "Tiempos_${plotTag}.png")
        $scr = GPPath $sTau
        & $gnuplotExe -e "rightfile='$r'; leftfile='$l'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; VALID=$valid" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo tiempos para $plotTag" }
    }

    if ((Test-Path $sEn) -and (Test-Path $en)) {
        $in  = GPPath $en
        $out = GPPath (Join-Path $dirEn "Energia_${plotTag}.png")
        $scr = GPPath $sEn
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; KBT=0.2; VALID=$valid" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo energia para $plotTag" }
    }

    if ((Test-Path $sTr) -and (Test-Path $tr)) {
        $in  = GPPath $tr
        $zmin = if(Test-Path $zoom){ GPPath $zoom } else { "" }
        $prefix = GPPath (Join-Path $dirTr $plotTag)
        $scr = GPPath $sTr
        & $gnuplotExe -e "datafile='$in'; zoomfile='$zmin'; outprefix='$prefix'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; VALID=$valid" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo trayectorias para $plotTag" }
    }

    if ((Test-Path $sTerm) -and (Test-Path $tb)) {
        $in  = GPPath $tb
        $out = GPPath (Join-Path $dirTerm "Termalizacion_${plotTag}.png")
        $scr = GPPath $sTerm
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; KBT=0.2; VALID=$valid" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo termalizacion por bloques para $plotTag" }
    }
}


function Plot-Eta-Single([double]$Aval,[string]$dataPath) {
    if (!(Test-Path $gnuplotExe)) { return }
    $script=Join-Path $projectRoot "scriptsGnuplot\O2\O2_03_tau_vs_eta_un_A.plt"
    if (!(Test-Path $script) -or !(Test-Path $dataPath)) { return }

    $tag=FName $Aval
    $in=GPPath $dataPath
    $out=GPPath (Join-Path $projectRoot "plots\O2\Tau_vs_eta_A${tag}_lineal.png")
    $scr=GPPath $script
    $doFit=if($Aval -lt 1.5){1}else{0}
    & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; FITMIN=1.0; DOFIT=$doFit" $scr
    if($LASTEXITCODE -ne 0){ Write-Host "[AVISO] Fallo grafica eta A=$Aval" }
}

function Eta-Meta-Text {
    $files=@('src\main.c','src\funciones.c','src\random.c')
    $hashes=@()
    foreach($p in $files) {
        if(!(Test-Path $p)) { throw "No se puede crear manifiesto sin $p" }
        $hashes += (Get-FileHash -Path $p -Algorithm SHA256).Hash
    }
    return "O2v13|h=$(CFloat $h)|XC=$(CFloat $XC)|KBT=0.2|TERM_MIN=$TermMinProduccion|TERM_MAX=$EtaManualTermMax|MEASURE_MIN=300000000|MEASURE_MAX=$EtaManualMeasureMax|etas=$($Etavals -join ',')|sha=$($hashes -join ':')"
}

function Write-Eta-Meta([double]$Aval) {
    $meta="results\O2\resumen_eta_A$(FName $Aval).meta"
    Eta-Meta-Text | Set-Content $meta -Encoding Ascii
    Write-Host "[OK] Manifiesto cientifico: $meta"
}

function Check-Eta-Meta {
    $paths=@(0.5,1.0,2.0) | ForEach-Object { "results\O2\resumen_eta_A$(FName $_).meta" }
    foreach($p in $paths) { if(!(Test-Path (Join-Path $projectRoot $p))) { return $false } }
    $texts=@($paths | ForEach-Object { (Get-Content (Join-Path $projectRoot $_) -Raw).Trim() })
    if($texts.Count -ne 3) { return $false }
    return ($texts[0] -ceq $texts[1] -and $texts[1] -ceq $texts[2])
}

function Run-Gnuplots([switch]$EtaOnly) {
    if (!(Test-Path $gnuplotExe)) {
        Write-Warning "No se encuentra Gnuplot en $gnuplotExe; simulaciones y datos siguen disponibles."
        return
    }

    # Comprobar dependencias: nunca mezclar resúmenes viejos o inventar puntos.
    $ref="results\O2\analisis"
    $root="results\O2"
    $allEta=@(0.5,1.0,2.0) | ForEach-Object { "${root}\resumen_eta_A$(FName $_).dat" }
    # -SoloGraficas sin -AetaFixed usa A=0.5; nunca buscar A0.dat.
    $aPlot=if($AetaFixed -gt 0.0) {$AetaFixed} else {0.5}
    $singleEta="${root}\resumen_eta_A$(FName $aPlot).dat"
    $cases=@(
      @{name='O2_01_distribucion_tiempos.plt'; deps=@("$ref\tiempos_derecha.dat","$ref\tiempos_izquierda.dat")},
      @{name='O2_02_tau_vs_A.plt'; deps=@("$root\resumen_A.dat")},
      @{name='O2_03_tau_vs_eta_tres_A.plt'; deps=$allEta},
      @{name='O2_T01_convergencia_termalizacion.plt'; deps=@("$root\termalizacion_scan\resumen_termalizacion.dat")},
      @{name='O2_04_ocupaciones_A_eta.plt'; deps=@("$root\resumen_A.dat",$singleEta)},
      @{name='O2_05_ocupaciones_eta_tres_A.plt'; deps=$allEta},
      @{name='O2_F01_ocupacion_vs_fuerza.plt'; deps=@("$root\resumen_F.dat")},
      @{name='O2_F02_tiempos_vs_fuerza.plt'; deps=@("$root\resumen_F.dat")},
      @{name='O2_F03_potencial_inclinado.plt'; deps=@()},
      @{name='O2_F04_residuo_logistica.plt'; deps=@("$root\resumen_F.dat")},
      @{name='O2_F04_diferencia_ocupacion.plt'; deps=@("$root\resumen_F.dat")},
      @{name='O2_D01_energia.plt'; deps=@("$ref\energia.dat")},
      @{name='O2_D02_histograma.plt'; deps=@("$ref\histograma.dat","$ref\parametros.dat")},
      @{name='O2_D03_trayectoria_fase.plt'; deps=@("$ref\trayectoria.dat")},
      @{name='O2_D04_trayectoria_zoom.plt'; deps=@("$ref\trayectoria_zoom.dat")}
    )
    Write-Host "Generando graficas disponibles; A de eta=$aPlot; datos no convergidos se distinguen."
    $plotFailures=@()
    Push-Location $scriptDirO2
    try {
        foreach($item in $cases) {
            $name=$item.name
            if($EtaOnly -and $name -notin @('O2_03_tau_vs_eta_tres_A.plt','O2_05_ocupaciones_eta_tres_A.plt')) {
                continue
            }
            if(!(Test-Path $name)) {
                Write-Warning "Falta script Gnuplot $name. Se continua con el resto."
                $plotFailures += $name
                continue
            }
            $missing=@($item.deps | Where-Object { !(Test-Path (Join-Path $projectRoot $_)) })
            if($missing.Count -gt 0) {
                Write-Host "[OMITIDA sin datos] $name : $($missing -join ', ')"
                continue
            }
            if($name -in @('O2_03_tau_vs_eta_tres_A.plt','O2_05_ocupaciones_eta_tres_A.plt')) {
                if(!(Check-Eta-Meta)) {
                    Write-Host "[OMITIDA] $name : falta o difiere la procedencia de A=0.5,1,2 (manifiestos .meta)."
                    continue
                }
            }
            Write-Host "[GNUPLOT] $name"
            & $gnuplotExe -e "AETA=$(CFloat $aPlot); AFORCE=$(CFloat $A_force); ETAFORCE=$(CFloat $eta_force)" $name
            if($LASTEXITCODE -ne 0) {
                Write-Warning "Gnuplot fallo: $name (salida $LASTEXITCODE). Se continua con el resto."
                $plotFailures += $name
                continue
            }
        }
    } finally { Pop-Location }
    if($plotFailures.Count -gt 0) {
        Write-Warning "Graficas fallidas: $($plotFailures -join ', '). Los datos de simulacion NO se han modificado."
    }
}

function Read-DoubleOrDefault([string]$prompt,[double]$default) {
    while($true) {
        $raw=Read-Host "$prompt [Enter = $(FName $default)]"
        if([string]::IsNullOrWhiteSpace($raw)) { return $default }
        $value=0.0
        $ok=[double]::TryParse(
            $raw.Replace(',','.'),
            [System.Globalization.NumberStyles]::Float,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [ref]$value
        )
        if($ok) { return $value }
        Write-Host "Valor no valido."
    }
}

# La UNICA eleccion de parametros permitida es A para el barrido tau(eta).
# El resto permanece fijo como en la configuracion acordada:
#   barrido A: eta=1, F=0
#   barrido F: A=0.5, eta=1
#   referencia: A=0.5, eta=1, F=0
if((-not $SoloGraficas) -and (-not $SoloTermalizacion)) {
    if($AetaFixed -le 0.0) {
        $AetaFixed=Read-DoubleOrDefault "A fijo para el barrido de eta" 0.5
    }
    if($AetaFixed -le 0.0) { throw "A debe ser positivo." }

    $Apermitidos=@(0.5,1.0,2.0)
    $Aok=$false
    foreach($aPermitida in $Apermitidos) {
        if([Math]::Abs($AetaFixed-$aPermitida) -lt 1e-12) { $Aok=$true }
    }
    if(!$Aok) {
        throw "Para el barrido tau(eta), A debe ser 0.5, 1 o 2."
    }

    Write-Host ""
    Write-Host "PARAMETROS O2"
    Write-Host "  A elegido para tau(eta) : $AetaFixed"
    Write-Host "  barrido A               : eta=1, F=0 (fijo)"
    Write-Host "  barrido F               : A=0.5, eta=1 (fijo)"
    Write-Host "  referencia              : A=0.5, eta=1, F=0 (fijo)"
    Write-Host "  reutilizacion           : DESACTIVADA; todos los casos se recalculan"
}

Ensure-Dirs


if ($SoloGraficas) {
    Write-Host "Regenerando graficas detalladas a partir de los datos existentes..."
    Plot-Case $Aref $Etaref $Fref

    foreach($Aval in $Avals) {
        Plot-Case $Aval $eta_ASweep 0.0
    }
    $Aplot = $AetaFixed
    if($Aplot -le 0.0) { $Aplot = 0.5 }
    foreach($Aval in @(0.5,1.0,2.0)) {
        if(Test-Path "results\O2\resumen_eta_A$(FName $Aval).dat") {
            foreach($Etaval in $Etavals) { Plot-Case $Aval $Etaval 0.0 }
            Plot-Eta-Single $Aval "results\O2\resumen_eta_A$(FName $Aval).dat"
        }
    }
    foreach($Fval in $Fvals) {
        Plot-Case $A_force $eta_force $Fval
    }

    Run-Gnuplots
    exit 0
}

# Las graficas no necesitan los fuentes C. La produccion SÍ: fallar temprano
# si faltan fuentes que no se incluyen en el paquete de contexto.
foreach($src in @('src\head.h','src\main.c','src\funciones.c','src\random.c')) {
    if(!(Test-Path $src)) { throw "Falta $src. El ZIP de contexto original NO trae funciones.c/random.c; añade los originales del proyecto antes de simular." }
}

$headText=Get-Content "src\head.h" -Raw
if(($headText -notmatch "TERM_TOL_OCC") -or
   ($headText -notmatch "MEASURE_MAX_RELERR_TAU") -or
   ($headText -notmatch "O2_V8_EXTENDED_SWEEPS") -or
   ($headText -notmatch "O2_V9_TUTOR_REVIEW") -or
   ($headText -notmatch "O2_V10_MANUAL_ETA_AND_ZOOM") -or
   ($headText -notmatch "O2_V11_LONG_PRODUCTION")) {
    throw "Tu src\\head.h no es la version O2 v10. Copia head_O2_v10.h como src\\head.h."
}

$funcText=Get-Content "src\funciones.c" -Raw
$forceOK=($funcText -match 'FEXT') -and
         ($funcText -match '\+\s*FEXT') -and
         ($funcText -match '-\s*FEXT\s*\*\s*x')

if(!$forceOK) {
    throw @"
Tu src\funciones.c no parece incluir correctamente la fuerza externa.

Debe contener:
  F(x) = -4*A*x*(x*x-1) + FEXT
  V(x) =  A*(x*x-1)^2 - FEXT*x

Comprueba las funciones de fuerza y energia en tu src\funciones.c actual.
"@
}

$mainText=Get-Content "src\main.c" -Raw
if(($mainText -notmatch 'TERM_MIN_TRANSITIONS') -or
   ($mainText -notmatch 'MEASURE_MAX_RELERR_TAU') -or
   ($mainText -notmatch 'termalizacion_bloques') -or
   ($mainText -notmatch 'TERM_FIXED_STEPS_MODE') -or
   ($mainText -notmatch 'datosTrayectoriaZoom')) {
    throw @"
Tu src\main.c no es la version O2 compatible con produccion larga.
Copia src\main.c del paquete corregido.
"@
}

# Preparación: no empezar simulación larga con fuentes de nombre de salida antiguo.
$funcText=Get-Content 'src\funciones.c' -Raw
if(($funcText -notmatch 'datosEnergia_h[^"\r\n]*_A%g_eta%g_F%g') -or
   ($funcText -notmatch 'datosTrayectoria_h[^"\r\n]*_A%g_eta%g_F%g') -or
   ($funcText -notmatch 'Histogramas_h[^"\r\n]*_A%g_eta%g_F%g')) {
    throw "src\funciones.c NO cumple el contrato de nombres con A, eta y F. Comparte tu fichero para adaptarlo antes de ejecutar horas de simulacion."
}

$originalHead = Get-Content $headPath -Raw

$header = "# param P_izq P_der transiciones estancias_izq estancias_der tau_izq tau_der tau_global k_sim term_steps measure_steps term_converged stats_converged dEk_term dEp_term dX2_term Pizq_teoria occ_err_term term_mix_trans occ_err_measure relerr_tau_izq relerr_tau_der term_global_ok"

$outA   = "results\O2\resumen_A.dat"
$outEta = "results\O2\resumen_eta.dat"
$outF   = "results\O2\resumen_F.dat"

if($SoloEta) {
    $atag=FName $AetaFixed
    $outEtaManual="results\O2\resumen_eta_A${atag}.dat"
    $header | Set-Content $outEtaManual -Encoding Ascii
    $meta="results\O2\resumen_eta_A${atag}.meta"
    if(Test-Path $meta){ Remove-Item -Force $meta }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "BARRIDO MANUAL tau(eta): A=$AetaFixed"
    Write-Host "============================================================"
    Write-Host "eta = $($Etavals -join ', ')"
    Write-Host "TERM_MIN=$TermMinProduccion"
    Write-Host "TERM_MAX=$EtaManualTermMax"
    Write-Host "MEASURE_MIN=300000000"
    Write-Host "MEASURE_MAX=$EtaManualMeasureMax"
    if($AetaFixed -eq 2.0) {
        Write-Host "A=2 se ejecuta con EL MISMO presupuesto que A=0.5 y A=1."
        Write-Host "Si no converge, NO se fuerza: ese fallo es parte del estudio."
    }
    Write-Host ""

    try {
        foreach($Etaval in $Etavals) {
            $file=Run-Case $AetaFixed $Etaval 0.0 `
                  $TermMinProduccion $EtaManualTermMax $EtaManualMeasureMax 0 0
            $c=Read-Summary $file
            Add-AggregateRow $outEtaManual $Etaval $c
            Plot-Case $AetaFixed $Etaval 0.0
        }
    }
    finally {
        Set-Content $headPath $originalHead -Encoding UTF8
        if(Test-Path $exe){ Remove-Item $exe -Force }
    }

    Write-Eta-Meta $AetaFixed
    if(!$SinGraficas) {
        Plot-Eta-Single $AetaFixed $outEtaManual
        # SOLO comparaciones entre los tres A si sus manifiestos son compatibles.
        Run-Gnuplots -EtaOnly
    }

    Write-Host ""
    Write-Host "[OK] Barrido manual terminado: $outEtaManual"
    Write-Host "No se inicia ningun otro valor de A."
    exit 0
}

$header | Set-Content $outA -Encoding Ascii
$header | Set-Content $outF -Encoding Ascii

Write-Host ""
Write-Host "BARRIDO v8:"
Write-Host "  A   : $($Avals.Count) puntos, $($Avals[0]) -> $($Avals[-1])"
Write-Host "  eta : $($Etavals.Count) puntos lineales para A=0.5, A=1 y A=2"
Write-Host "  F   : $($Fvals.Count) puntos, $($Fvals[0]) -> $($Fvals[-1])"
$FcritForce = 8.0*$A_force/(3.0*[Math]::Sqrt(3.0))
Write-Host ("  Barrido F usa A={0}; Fcrit={1:N4}. +/-0.5 inclina/rompe simetria, pero mantiene dos minimos." -f $A_force,$FcritForce)
Write-Host ""

if(!$SaltarEstudioTermalizacion) {
    Run-TermalizacionScan
    if($SoloTermalizacion) {
        if(!$SinGraficas) { Run-Gnuplots }
        exit 0
    }
}
elseif($SoloTermalizacion) {
    Write-Host "No hay nada que ejecutar: se combinaron -SoloTermalizacion y -SaltarEstudioTermalizacion."
    exit 0
}

try {
    # 0) Caso de referencia para diagnosticos
    Run-Case $Aref $Etaref $Fref | Out-Null
    Make-Reference-Aliases
    Plot-Case $Aref $Etaref $Fref

    # 1) Dependencia con altura de barrera A, eta=1, F=0
    foreach($Aval in $Avals) {
        if($Aval -eq $Aref) {
            # El caso A=0.5, eta=1, F=0 ya se acaba de generar para referencia.
            # No repetirlo; reusar DENTRO DE LA MISMA EJECUCION, nunca del disco previo.
            $file=Resolve-Summary $Aref $Etaref $Fref
        } else {
            $file=Run-Case $Aval $eta_ASweep 0.0
        }
        $c=Read-Summary $file
        Add-AggregateRow $outA $Aval $c
        Plot-Case $Aval $eta_ASweep 0.0
    }

    # 2) tau(eta): UNICAMENTE el A elegido al inicio.
    $atag=FName $AetaFixed
    $outEtaActual="results\O2\resumen_eta_A${atag}.dat"
    $header | Set-Content $outEtaActual -Encoding Ascii
    $meta="results\O2\resumen_eta_A${atag}.meta"
    if(Test-Path $meta){ Remove-Item -Force $meta }

    foreach($Etaval in $Etavals) {
        $file=Run-Case $AetaFixed $Etaval 0.0 `
              $TermMinProduccion $EtaManualTermMax $EtaManualMeasureMax 0 0
        $c=Read-Summary $file
        Add-AggregateRow $outEtaActual $Etaval $c
        Plot-Case $AetaFixed $Etaval 0.0
    }
    Copy-Item -Force $outEtaActual "results\O2\resumen_eta.dat"
    Write-Eta-Meta $AetaFixed

    # 3) Fuerza externa, A=0.5, eta=1
    foreach($Fval in $Fvals) {
        $file=Run-Case $A_force $eta_force $Fval
        $c=Read-Summary $file
        Add-AggregateRow $outF $Fval $c
        Plot-Case $A_force $eta_force $Fval
    }
}
finally {
    Set-Content $headPath $originalHead -Encoding UTF8
    if(Test-Path $exe){ Remove-Item $exe -Force }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "OBJETIVO 2: BARRIDOS TERMINADOS"
Write-Host "============================================================"
Write-Host $outA
Write-Host "results\O2\resumen_eta_A$(FName $AetaFixed).dat"
Write-Host $outEta
Write-Host $outF
Write-Host "Caso de referencia: results\O2\analisis\"

if (!$SinGraficas) {
    Plot-Eta-Single $AetaFixed "results\O2\resumen_eta_A$(FName $AetaFixed).dat"
    Run-Gnuplots
}
