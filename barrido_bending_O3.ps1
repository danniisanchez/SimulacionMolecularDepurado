# ============================================================
# O3 - Barrido automático de bending armónico
#
# Colocar en la RAÍZ del repositorio.
# Se asume que el integrador está dentro de funciones.c.
#
# Construye:
#   results/O3/bending_armonico_N64.dat
#
# Columnas:
# 1 KBEND
# 2 <Ree>
# 3 <Rg>
# 4 <Ebond>
# 5 <Ebend>
# 6 <theta> [rad]
# 7 <cos(theta)>
# 8 <longitud_enlace>
# 9 muestras
# ============================================================

$N = 64
$kbends = @(0.0,0.1,0.25,0.5,1.0,2.0,5.0,10.0,20.0,50.0)

$headPath = "srcO3\head.h"
$outDir = "results\O3"
$outFile = "$outDir\bending_armonico_N$N.dat"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path "plots\O3" | Out-Null

$originalHead = Get-Content $headPath -Raw

"# KBEND Ree_mean Rg_mean Ebond_mean Ebend_mean theta_mean cos_theta_mean bond_mean muestras" |
    Set-Content $outFile -Encoding UTF8

try {
    foreach ($K in $kbends) {
        Write-Host ""
        Write-Host "========================================"
        Write-Host "N = $N     KBEND = $K"
        Write-Host "========================================"

        # Aislamos el efecto del bending: fuerza externa nula.
        $nuevoHead = $originalHead
        $nuevoHead = $nuevoHead -replace '#define\s+KBEND\s+[-+0-9.eE]+', "#define KBEND $K"
        $nuevoHead = $nuevoHead -replace '#define\s+USE_BENDING\s+\d+', "#define USE_BENDING 1"
        $nuevoHead = $nuevoHead -replace '#define\s+F_ext\s+[-+0-9.eE]+', "#define F_ext 0.0"

        Set-Content -Path $headPath -Value $nuevoHead -Encoding UTF8

        gcc srcO3\main.c srcO3\funciones.c srcO3\random.c -O2 -std=c11 -lm -o o3_bending.exe
        if ($LASTEXITCODE -ne 0) { throw "Error de compilacion para KBEND=$K" }

        .\o3_bending.exe $N
        if ($LASTEXITCODE -ne 0) { throw "Error de ejecucion para KBEND=$K" }

        $summary = "results\O3\N$N\resumen_N$N.dat"
        if (!(Test-Path $summary)) { throw "No existe $summary" }

        $line = Get-Content $summary |
                Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
                Select-Object -Last 1

        $cols = ($line -split '\s+') | Where-Object { $_ -ne "" }

        if ($cols.Count -lt 15) {
            throw "El resumen debe contener 15 columnas incluyendo Ebend, theta y cos(theta)."
        }

        # resumen:
        # 1 N, 2 Ek, 3 Ek_teo, 4 Ep, 5 Ep_ref,
        # 6 Ree, 7 Ree2, 8 Rg, 9 Rg2, 10 bond,
        # 11 muestras, 12 Ree_parallel,
        # 13 Ebend, 14 theta, 15 cos(theta)
        $Ree      = $cols[5]
        $Rg       = $cols[7]
        $Ebond    = $cols[3]
        $Ebend    = $cols[12]
        $Theta    = $cols[13]
        $CosTheta = $cols[14]
        $Bond     = $cols[9]
        $Muestras = $cols[10]

        "$K $Ree $Rg $Ebond $Ebend $Theta $CosTheta $Bond $Muestras" |
            Add-Content $outFile -Encoding UTF8
    }
}
finally {
    Set-Content -Path $headPath -Value $originalHead -Encoding UTF8
}

Write-Host ""
Write-Host "Barrido terminado."
Write-Host "Datos: $outFile"
