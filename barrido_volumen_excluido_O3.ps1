# ============================================================
# O3 - Comparacion cadena ideal vs volumen excluido WCA
#
# Ejecutar desde la RAIZ del repositorio.
# Compara N = 4, 8, 16, 32, 64 con:
#   USE_EXCLUDED_VOLUME = 0
#   USE_EXCLUDED_VOLUME = 1
#
# Para aislar el efecto del volumen excluido:
#   BENDING_MODEL = 0
#   F_ext = 0
# ============================================================

$Ns = @(4,8,16,32,64)

$headPath = "srcO3\head.h"
$outDir = "results\O3"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path "plots\O3" | Out-Null

$originalHead = Get-Content $headPath -Raw

$cases = @(
    @{ EV = 0; Name = "ideal"; File = "$outDir\excluded_ideal_sizes.dat" },
    @{ EV = 1; Name = "WCA";   File = "$outDir\excluded_WCA_sizes.dat" }
)

foreach ($case in $cases) {
    "# N Ree_mean Rg_mean Rg2_mean Ebond_mean Eev_mean dmin_mean bond_mean muestras" |
        Set-Content $case.File -Encoding UTF8
}

try {
    foreach ($case in $cases) {
        foreach ($N in $Ns) {
            Write-Host ""
            Write-Host "========================================"
            Write-Host "Caso = $($case.Name)   N = $N"
            Write-Host "========================================"

            $nuevoHead = $originalHead
            $nuevoHead = $nuevoHead -replace '#define\s+USE_EXCLUDED_VOLUME\s+\d+', "#define USE_EXCLUDED_VOLUME $($case.EV)"
            $nuevoHead = $nuevoHead -replace '#define\s+BENDING_MODEL\s+\d+', "#define BENDING_MODEL 0"
            $nuevoHead = $nuevoHead -replace '#define\s+F_ext\s+[-+0-9.eE]+', "#define F_ext 0.0"

            Set-Content -Path $headPath -Value $nuevoHead -Encoding UTF8

            gcc srcO3\main.c srcO3\funciones.c srcO3\random.c -O2 -std=c11 -lm -o o3_ev.exe
            if ($LASTEXITCODE -ne 0) { throw "Error compilando caso $($case.Name), N=$N" }

            .\o3_ev.exe $N
            if ($LASTEXITCODE -ne 0) { throw "Error ejecutando caso $($case.Name), N=$N" }

            $summary = "results\O3\N$N\resumen_N$N.dat"
            if (!(Test-Path $summary)) { throw "No existe $summary" }

            $line = Get-Content $summary |
                    Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
                    Select-Object -Last 1

            $cols = ($line -split '\s+') | Where-Object { $_ -ne "" }

            if ($cols.Count -lt 22) {
                throw "El resumen debe contener las 22 columnas de la version EV."
            }

            # 1 N, 2 Ek, 3 Ek_teo, 4 Ebond, 5 Ebond_ref,
            # 6 Ree, 7 Ree2, 8 Rg, 9 Rg2, 10 bond,
            # 11 muestras, 12 Ree_parallel, 13 Ebend, 14 theta,
            # 15 cos(theta), 16 bending_model, 17 KBEND,
            # 18 Eev, 19 dmin, 20 use_EV, 21 epsilon, 22 sigma
            $Ree      = $cols[5]
            $Rg       = $cols[7]
            $Rg2      = $cols[8]
            $Ebond    = $cols[3]
            $Eev      = $cols[17]
            $Dmin     = $cols[18]
            $Bond     = $cols[9]
            $Muestras = $cols[10]

            "$N $Ree $Rg $Rg2 $Ebond $Eev $Dmin $Bond $Muestras" |
                Add-Content $case.File -Encoding UTF8
        }
    }
}
finally {
    Set-Content -Path $headPath -Value $originalHead -Encoding UTF8
}

Write-Host ""
Write-Host "Barrido terminado."
Write-Host "Ideal: results\O3\excluded_ideal_sizes.dat"
Write-Host "WCA:   results\O3\excluded_WCA_sizes.dat"
