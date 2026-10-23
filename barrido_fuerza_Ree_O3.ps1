# ============================================================
# O3 - Barrido amplio de fuerza externa para Ree_parallel(F)
#
# Colocar en la RAIZ del repositorio.
#
# Estructura esperada:
#   srcO3/
#     main.c
#     funciones.c
#     random.c
#     head.h
#
# Suposiciones:
# - bead 0 fija
# - fuerza F_ext aplicada en +x sobre bead N-1
# - el ejecutable recibe N como argumento
# - resumen_N.dat contiene Ree_parallel_mean en la columna 12
# ============================================================

$N = 64

# Barrido amplio:
# débil -> respuesta lineal -> orientación -> fuerte estiramiento de enlaces
$forces = @(
    0.0,
    0.001, 0.003,
    0.01, 0.03,
    0.1, 0.3,
    0.5, 1.0, 2.0, 3.0, 5.0,
    10.0, 20.0, 30.0, 50.0,
    100.0, 200.0,300.0, 500.0,750.0
    , 1000.0
)

$headPath = "srcO3\head.h"
$outDir = "results\O3"
$outFile = "$outDir\ree_vs_fuerza_N$N.dat"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path "plots\O3" | Out-Null

$originalHead = Get-Content $headPath -Raw

"# F_ext Ree_parallel_mean Ree_mean bond_mean muestras" | Set-Content $outFile -Encoding UTF8

try {
    foreach ($F in $forces) {

        Write-Host ""
        Write-Host "========================================"
        Write-Host "N = $N     F_ext = $F"
        Write-Host "========================================"

        $nuevoHead = $originalHead -replace '#define\s+F_ext\s+[-+0-9.eE]+', "#define F_ext $F"
        Set-Content -Path $headPath -Value $nuevoHead -Encoding UTF8

        gcc srcO3\main.c srcO3\funciones.c srcO3\random.c -O2 -std=c11 -lm -o o3_force.exe

        if ($LASTEXITCODE -ne 0) {
            throw "Error de compilacion para F_ext=$F"
        }

        .\o3_force.exe $N

        if ($LASTEXITCODE -ne 0) {
            throw "Error de ejecucion para F_ext=$F"
        }

        $summary = "results\O3\N$N\resumen_N$N.dat"

        if (!(Test-Path $summary)) {
            throw "No existe $summary"
        }

        $line = Get-Content $summary |
                Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
                Select-Object -Last 1

        $cols = ($line -split '\s+') | Where-Object { $_ -ne "" }

        if ($cols.Count -lt 12) {
            throw "El resumen tiene menos de 12 columnas. Debes añadir Ree_parallel_mean como columna 12."
        }

        $ReeMean      = $cols[5]
        $BondMean     = $cols[9]
        $Muestras     = $cols[10]
        $ReeParallel  = $cols[11]

        "$F $ReeParallel $ReeMean $BondMean $Muestras" |
            Add-Content $outFile -Encoding UTF8
    }
}
finally {
    Set-Content -Path $headPath -Value $originalHead -Encoding UTF8
}

Write-Host ""
Write-Host "========================================"
Write-Host "Barrido terminado."
Write-Host "Datos: $outFile"
Write-Host "========================================"
