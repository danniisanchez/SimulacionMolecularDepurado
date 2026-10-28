param(
    [switch]$SoloReconstruir
)

# ============================================================
# O3 - Barrido de tamanos + reconstruccion resumen_tamanos.dat
#
# Ejecutar desde la RAIZ del repositorio.
#
# Uso normal:
#   .\barrido_tamanos_O3_adaptativo.ps1
#
# Si YA existen:
#   results/O3/N4/resumen_N4.dat
#   ...
#   results/O3/N64/resumen_N64.dat
#
# y solo quieres regenerar resumen_tamanos.dat SIN repetir simulaciones:
#   .\barrido_tamanos_O3_adaptativo.ps1 -SoloReconstruir
#
# El archivo generado es:
#   results/O3/resumen_tamanos.dat
#
# Conserva el orden de columnas de resumen_N*.dat.
# Los .plt antiguos usan solo las primeras columnas, por lo que
# las columnas adaptativas nuevas al final no rompen compatibilidad.
# ============================================================

$ErrorActionPreference = "Stop"

$Ns = @(4, 8, 16, 32, 64)
$exe = "o3_tamanos.exe"
$outFile = "results\O3\resumen_tamanos.dat"

function Reconstruir-ResumenTamanos {
    New-Item -ItemType Directory -Force -Path "results\O3" | Out-Null

    $headerWritten = $false
    $rows = @()

    foreach ($N in $Ns) {
        $file = "results\O3\N$N\resumen_N$N.dat"

        if (!(Test-Path $file)) {
            throw "Falta $file. Ejecuta primero N=$N o usa el modo normal del script."
        }

        $lines = Get-Content $file
        $header = $lines |
            Where-Object { $_ -match '^\s*#' } |
            Select-Object -First 1

        $data = $lines |
            Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
            Select-Object -Last 1

        if (!$data) {
            throw "No se encontro una fila de datos valida en $file"
        }

        $cols = ($data.Trim() -split '\s+') |
            Where-Object { $_ -ne "" }

        if ($cols.Count -lt 11) {
            throw "$file solo contiene $($cols.Count) columnas; se necesitan al menos 11."
        }

        if ([int]$cols[0] -ne $N) {
            throw "La primera columna de $file es N=$($cols[0]), pero se esperaba N=$N."
        }

        if (!$headerWritten) {
            if ($header) {
                Set-Content -Path $outFile -Value $header -Encoding UTF8
            }
            else {
                Set-Content -Path $outFile -Value "# N Ek_mean Ek_teo Ebond_mean Ebond_ref Ree_mean Ree2_mean Rg_mean Rg2_mean bond_mean muestras" -Encoding UTF8
            }
            $headerWritten = $true
        }

        $rows += $data.Trim()
    }

    foreach ($row in $rows) {
        Add-Content -Path $outFile -Value $row -Encoding UTF8
    }

    Write-Host ""
    Write-Host "=================================================="
    Write-Host "resumen_tamanos.dat reconstruido correctamente"
    Write-Host "=================================================="
    Write-Host $outFile
    Write-Host ""
    Write-Host "Filas incluidas: N = $($Ns -join ', ')"
    Write-Host "Los scripts O3_01, O3_02 y O3_05 pueden usarlo directamente."