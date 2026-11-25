param(
    [switch]$SoloReconstruir,
    [switch]$SoloGraficas,
    [switch]$ReusarExistentes,
    [switch]$SoloNuevos
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$Ns = @(4,6,8,12,16,24,32,40,48,56,64)
$Nuevos = @(6,12,24,40,48,56)
$AProcesar = if ($SoloNuevos) { $Nuevos } else { $Ns }
$exe = Join-Path $root 'o3_tamanos_libre.exe'
$src = Join-Path $root 'srcO3_tamanos_libre'
$gnuplot = 'C:\Program Files\gnuplot\bin\gnuplot.exe'
if (-not (Test-Path -LiteralPath $gnuplot)) {
    $comando = Get-Command 'gnuplot.exe' -ErrorAction SilentlyContinue
    if (-not $comando) { $comando = Get-Command 'gnuplot' -ErrorAction SilentlyContinue }
    if ($comando) { $gnuplot = $comando.Source }
}

function Last-DataLine([string]$file) {
    return Get-Content -LiteralPath $file |
        Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } |
        Select-Object -Last 1
}
function Resumen-Convergido([string]$file) {
    if (-not (Test-Path -LiteralPath $file)) { return $false }
    $line = Last-DataLine $file
    if (-not $line) { return $false }
    $c = ($line.Trim() -split '\s+') | Where-Object { $_ -ne '' }
    if ($c.Count -lt 26) { return $false }
    return (($c[24] -eq '1') -and ($c[25] -eq '1'))
}
function Reconstruir {
    $out = Join-Path $root 'results\O3\resumen_tamanos.dat'
    $folder = Split-Path -Parent $out
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    $rows = @()
    $header = $null
    foreach ($n in $Ns) {
        $f = Join-Path $root ("results\O3\N{0}\resumen_N{0}.dat" -f $n)
        if (-not (Test-Path -LiteralPath $f)) {
            throw "Falta el resumen del tamano N=$n. Para usar los 11 puntos, ejecuta primero ese caso."
        }
        $data = Last-DataLine $f
        if (-not $data) { throw "No hay datos en $f" }
        $cols = @($data.Trim() -split '\s+')
        if ([int]$cols[0] -ne $n) { throw "N no coincide en $f" }
        $rows += $data.Trim()
        if (-not $header) {
            $header = Get-Content -LiteralPath $f | Where-Object { $_ -match '^\s*#' } | Select-Object -First 1
        }
    }
    if (-not $header) { throw 'Los resumenes individuales no tienen cabecera.' }
    # ASCII evita el BOM UTF8 que a veces interfiere con Gnuplot.
    [System.IO.File]::WriteAllLines($out, ([string[]](@($header) + $rows)), [System.Text.Encoding]::ASCII)
    Write-Host "[O3] Resumen reconstruido con $($Ns.Count) puntos: $out"
    Write-Warning 'Comprueba que los 5 tamanos historicos correspondan a F=0 y sin anclaje, antes de interpretar el ajuste.'
}
function Graficar {
    if (-not (Test-Path -LiteralPath $gnuplot)) { throw "Gnuplot no encontrado: $gnuplot" }
    foreach ($n in $Ns) {
        New-Item -ItemType Directory -Force -Path (Join-Path $root ("plots\O3\N{0}" -f $n)) | Out-Null
    }
    $cwd = Get-Location
    try {
        Set-Location -LiteralPath (Join-Path $root 'scriptsGnuplot\O3')
        foreach ($s in @('O3_01_equiparticion_v11.plt','O3_02_Ree_Rg_vs_N_v11.plt','O3_05_ley_escala_NmenosB_v11.plt')) {
            & $gnuplot $s
            if ($LASTEXITCODE -ne 0) { throw "Fallo de Gnuplot en $s" }
        }
        foreach ($n in $Ns) {
            $term = Join-Path $root ("results\O3\N{0}\termalizacion_N{0}.dat" -f $n)
            if (Test-Path -LiteralPath $term) {
                foreach ($s in @('O3_03_termalizacion_normalizada.plt','O3_03_termalizacion_sin_normalizar.plt')) {
                    & $gnuplot -e "N=$n" $s
                    if ($LASTEXITCODE -ne 0) { throw "Fallo de Gnuplot en $s, N=$n" }
                }
            } else {
                Write-Warning "N=${n}: sin archivo de termalizacion. Se omite este caso."
            }
            $snap = Join-Path $root ("results\O3\N{0}\snapshot_final_N{0}.dat" -f $n)
            if (Test-Path -LiteralPath $snap) {
                & $gnuplot -e "N=$n" 'O3_04_polimero3D_N_v11.plt'
                if ($LASTEXITCODE -ne 0) { throw "Fallo al generar snapshot N=$n" }
            }
        }
    } finally {
        Set-Location -LiteralPath $cwd.Path
    }
}
function Backup-Case([int]$n) {
    $case = Join-Path $root ("results\O3\N{0}" -f $n)
    if (-not (Test-Path -LiteralPath $case)) { return }
    $names = @("resumen_N${n}.dat", "termalizacion_N${n}.dat", "medidas_N${n}.dat", "snapshot_final_N${n}.dat",'procedencia_tamanos_libre.txt')
    $presentes = @($names | Where-Object { Test-Path -LiteralPath (Join-Path $case $_) })
    if ($presentes.Count -eq 0) { return }
    $stamp = Get-Date -Format 'yyyyMMdd_HHmmssfff'
    $dir = Join-Path $root ("results\O3\copias_previas\N{0}_{1}" -f $n,$stamp)
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    foreach ($name in $presentes) { Copy-Item -LiteralPath (Join-Path $case $name) -Destination $dir }
    Write-Host "[COPIA] Caso anterior N=$n guardado en $dir"
}

if ($SoloReconstruir) { Reconstruir; if (-not $SoloGraficas) { Graficar }; exit 0 }
if ($SoloGraficas) { Graficar; exit 0 }

foreach ($name in @('main.c','funciones.c','head.h')) {
    if (-not (Test-Path -LiteralPath (Join-Path $src $name))) { throw "Falta el codigo del modo libre: $name" }
}
if (-not (Test-Path -LiteralPath (Join-Path $root 'srcO3\random.c'))) {
    throw 'Falta srcO3\random.c, necesario para compilar.'
}
try {
    Push-Location $root
    & gcc (Join-Path $src 'main.c') (Join-Path $src 'funciones.c') (Join-Path $root 'srcO3\random.c') -I $src -O2 -std=c11 -Wall -Wextra -pedantic -lm -o $exe
    if ($LASTEXITCODE -ne 0) { throw 'Error compilando O3 libre.' }
    foreach ($n in $AProcesar) {
        $res = Join-Path $root ("results\O3\N{0}\resumen_N{0}.dat" -f $n)
        $meta = Join-Path $root ("results\O3\N{0}\procedencia_tamanos_libre.txt" -f $n)
        if ($ReusarExistentes -and (Resumen-Convergido $res)) {
            if (-not (Test-Path -LiteralPath $meta)) {
                Write-Warning "N=${n}: resultado anterior sin procedencia de F=0/sin anclaje; NO lo consideres validado como cadena libre sin comprobarlo."
            }
            Write-Host "[REUSO] N=$n (convergencia TERM y STATS declarada)"
            continue
        }
        Backup-Case $n
        Write-Host "[O3 LIBRE] N=$n; F=0; sin anclaje; referencia Ek=1.5*N*KBT"
        & $exe $n | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "Fallo O3 sin fuerza N=$n" }
        $dir = Split-Path -Parent $meta
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
        @('modo=tamanos_libre','F_ext=0','anclaje=ninguno','referencia_Ek=1.5*N*KBT','origen=srcO3_tamanos_libre') |
            Set-Content -LiteralPath $meta -Encoding ASCII
    }
    Reconstruir
    Graficar
} finally {
    if (Test-Path -LiteralPath $exe) { Remove-Item -LiteralPath $exe -Force }
    Pop-Location
}
