# ============================================================
# O3 - Comparacion bending armonico vs WLC
#
# Colocar en la RAIZ del repositorio.
# El integrador se asume incluido en funciones.c.
#
# Genera:
#   results/O3/bending_armonico_N64.dat
#   results/O3/bending_WLC_N64.dat
# ============================================================

$N = 64
$Ks = @(0.0,0.1,0.25,0.5,1.0,2.0,5.0,10.0,20.0,50.0)

$headPath = "srcO3\head.h"
$outDir = "results\O3"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path "plots\O3" | Out-Null

$originalHead = Get-Content $headPath -Raw

$models = @(
    @{ Id = 1; Name = "armonico"; File = "$outDir\bending_armonico_N$N.dat" },
    @{ Id = 2; Name = "WLC";      File = "$outDir\bending_WLC_N$N.dat" }
)

foreach ($model in $models) {
    "# K Ree_mean Rg_mean Ebond_mean Ebend_mean theta_mean cos_theta_mean bond_mean muestras" |
        Set-Content $model.File -Encoding UTF8
}

try {
    foreach ($model in $models) {
        foreach ($K in $Ks) {
            Write-Host ""
            Write-Host "========================================"
            Write-Host "Modelo = $($model.Name)   N = $N   K = $K"
            Write-Host "========================================"

            $nuevoHead = $originalHead
            $nuevoHead = $nuevoHead -replace '#define\s+BENDING_MODEL\s+\d+', "#define BENDING_MODEL $($model.Id)"
            $nuevoHead = $nuevoHead -replace '#define\s+KBEND\s+[-+0-9.eE]+', "#define KBEND $K"
            $nuevoHead = $nuevoHead -replace '#define\s+F_ext\s+[-+0-9.eE]+', "#define F_ext 0.0"

            Set-Content -Path $headPath -Value $nuevoHead -Encoding UTF8

            gcc srcO3\main.c srcO3\funciones.c srcO3\random.c -O2 -std=c11 -lm -o o3_bending_compare.exe
            if ($LASTEXITCODE -ne 0) {
                throw "Error compilando modelo $($model.Name), K=$K"
            }

            .\o3_bending_compare.exe $N
            if ($LASTEXITCODE -ne 0) {
                throw "Error ejecutando modelo $($model.Name), K=$K"
            }

            $summary = "results\O3\N$N\resumen_N$N.dat"
            if (!(Test-Path $summary)) { throw "No existe $summary" }

            $line = Get-Content $summary |
                    Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
                    Select-Object -Last 1

            $cols = ($line -split '\s+') | Where-Object { $_ -ne "" }

            if ($cols.Count -lt 17) {
                throw "El resumen debe contener las 17 columnas de la version WLC."
            }

            # 1 N, 2 Ek, 3 Ek_teo, 4 Ep, 5 Ep_ref,
            # 6 Ree, 7 Ree2, 8 Rg, 9 Rg2, 10 bond,
            # 11 muestras, 12 Ree_parallel, 13 Ebend,
            # 14 theta, 15 cos(theta), 16 model, 17 K
            $Ree      = $cols[5]
            $Rg       = $cols[7]
            $Ebond    = $cols[3]
            $Ebend    = $cols[12]
            $Theta    = $cols[13]
            $CosTheta = $cols[14]
            $Bond     = $cols[9]
            $Muestras = $cols[10]

            "$K $Ree $Rg $Ebond $Ebend $Theta $CosTheta $Bond $Muestras" |
                Add-Content $model.File -Encoding UTF8
        }
    }
}
finally {
    Set-Content -Path $headPath -Value $originalHead -Encoding UTF8
}

Write-Host ""
Write-Host "Comparacion terminada."
Write-Host "Armonico: results\O3\bending_armonico_N$N.dat"
Write-Host "WLC:      results\O3\bending_WLC_N$N.dat"
