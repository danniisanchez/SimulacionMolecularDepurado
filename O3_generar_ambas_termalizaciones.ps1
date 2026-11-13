# Se invoca desde graficar_O3_todo_v12.ps1. No simula ni compila nada.
# Solo genera las dos versiones de termalizacion con datos existentes.
param(
    [int[]]$Ns = @(4,8,16,32,64)
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$plotsDir = Join-Path $root 'scriptsGnuplot\O3'

if (-not (Test-Path -LiteralPath $plotsDir -PathType Container)) {
    throw "No existe la carpeta de scripts de Gnuplot: $plotsDir"
}

$gnuplot = 'C:\Program Files\gnuplot\bin\gnuplot.exe'
if (-not (Test-Path -LiteralPath $gnuplot -PathType Leaf)) {
    $comando = Get-Command 'gnuplot.exe' -ErrorAction SilentlyContinue
    if (-not $comando) { $comando = Get-Command 'gnuplot' -ErrorAction SilentlyContinue }
    if (-not $comando) { throw 'No se encuentra Gnuplot. Instala Gnuplot o anadelo a PATH.' }
    $gnuplot = $comando.Source
}

$scripts = @(
    'O3_03_termalizacion_normalizada.plt',
    'O3_03_termalizacion_sin_normalizar.plt'
)
foreach ($script in $scripts) {
    if (-not (Test-Path -LiteralPath (Join-Path $plotsDir $script) -PathType Leaf)) {
        throw "Falta $script en scriptsGnuplot\O3"
    }
}

$anterior = Get-Location
try {
    Set-Location -LiteralPath $plotsDir
    foreach ($n in $Ns) {
        $datos = Join-Path $root ("results\O3\N{0}\termalizacion_N{0}.dat" -f $n)
        if (-not (Test-Path -LiteralPath $datos -PathType Leaf)) {
            Write-Warning "N=${n}: no existe el archivo de termalizacion. Se omiten ambas graficas."
            continue
        }

        New-Item -ItemType Directory -Path (Join-Path $root ("plots\O3\N{0}" -f $n)) -Force | Out-Null
        foreach ($script in $scripts) {
            Write-Host "[GNUPLOT O3] N=$n : $script"
            & $gnuplot -e "N=$n" $script
            if ($LASTEXITCODE -ne 0) {
                throw "Fallo de Gnuplot al representar $script para N=$n (salida $LASTEXITCODE)"
            }
        }
    }
}
finally {
    Set-Location -LiteralPath $anterior.Path
}
