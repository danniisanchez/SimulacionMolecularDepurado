param(
    [string]$Aeta = ""
)

$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$master = Join-Path $root "O2_master.ps1"
$gnuplot = "C:\Program Files\gnuplot\bin\gnuplot.exe"

function Convert-UserDouble([string]$text) {
    if([string]::IsNullOrWhiteSpace($text)) { return $null }

    $s = $text.Trim().Replace(",", ".")
    [double]$value = 0.0

    $ok = [double]::TryParse(
        $s,
        [System.Globalization.NumberStyles]::Float,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [ref]$value
    )

    if(!$ok) { return $null }
    return $value
}

if(!(Test-Path $master)) {
    throw "No se encuentra O2_master.ps1 en:`n$master"
}

if(!(Test-Path $gnuplot)) {
    throw "No se encuentra Gnuplot en:`n$gnuplot"
}

# El master revisado necesita saber qué A corresponde al barrido de eta
# para localizar, por ejemplo, resumen_eta_A0.5.dat.
if([string]::IsNullOrWhiteSpace($Aeta)) {
    do {
        Write-Host ""
        Write-Host "============================================================"
        Write-Host "O2 - REGENERAR SOLO GRAFICAS"
        Write-Host "============================================================"
        Write-Host "No se compila ni se ejecuta ninguna simulacion."
        Write-Host ""

        $raw = Read-Host "Que A corresponde al barrido de eta que quieres representar"
        $parsed = Convert-UserDouble $raw

        if(($null -eq $parsed) -or ($parsed -le 0.0)) {
            Write-Host "[AVISO] Introduce un numero positivo. Se admite punto o coma decimal."
        }

    } while(($null -eq $parsed) -or ($parsed -le 0.0))

    [double]$Aval = $parsed
}
else {
    $parsed = Convert-UserDouble $Aeta

    if(($null -eq $parsed) -or ($parsed -le 0.0)) {
        throw "-Aeta debe ser un numero positivo."
    }

    [double]$Aval = $parsed
}

Write-Host ""
Write-Host "============================================================"
Write-Host "O2 - REGENERACION DE GRAFICAS"
Write-Host "============================================================"
Write-Host "A del barrido eta : $Aval"
Write-Host "Master             : $master"
Write-Host ""
Write-Host "Se reutilizaran exclusivamente los datos ya existentes."
Write-Host "NO se ejecutara el solver C."
Write-Host ""

Push-Location $root
try {
    & $master -SoloGraficas -AetaFixed $Aval
    if(!$?) { throw "O2_master.ps1 fallo durante la regeneracion de graficas." }
} finally { Pop-Location }

Write-Host ""
Write-Host "[OK] Regeneracion de graficas finalizada."
Write-Host "Los datos de results\O2 no han sido recalculados."
