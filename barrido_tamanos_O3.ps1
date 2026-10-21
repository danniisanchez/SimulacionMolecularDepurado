# Objetivo 3 - barrido automatico N=4,8,16,32,64
# Colocar este archivo en la RAIZ del repositorio.

$Ns = @(4, 8, 16, 32, 64)

New-Item -ItemType Directory -Force -Path "results\O3" | Out-Null
New-Item -ItemType Directory -Force -Path "plots\O3" | Out-Null

if (Test-Path "results\O3\resumen_tamanos.dat") {
    Remove-Item "results\O3\resumen_tamanos.dat"
}

Write-Host "Compilando Objetivo 3..."
gcc srcO3\main.c srcO3\funciones.c srcO3\random.c -O2 -std=c11 -lm -o o3.exe
if ($LASTEXITCODE -ne 0) { throw "Error al compilar el Objetivo 3." }

foreach ($N in $Ns) {
    Write-Host ""
    Write-Host "========================================"
    Write-Host "Simulando polimero con N = $N"
    Write-Host "========================================"

    .\o3.exe $N
    if ($LASTEXITCODE -ne 0) { throw "La simulacion fallo para N=$N." }
}

Write-Host ""
Write-Host "Barrido terminado."
Write-Host "Resumen: results\O3\resumen_tamanos.dat"
