# ============================================================
# O2 - Barridos previos a la fuerza: barrera A y friccion eta
#
# Ejecutar desde la RAIZ del repositorio.
# Requiere:
#   src/main.c
#   src/funciones.c
#   src/random.c
#   src/head.h
#
# Pensado para main/head O2 adaptativos.
#
# Reproduce exactamente los valores usados por:
#   O2_02_tau_vs_A.plt
#   O2_03_tau_k_vs_eta.plt
#   O2_04_ocupaciones_A_eta.plt
#
# Ademas copia los archivos con F=0 a los nombres "legacy" sin _F0
# para que esos .plt anteriores sigan funcionando sin modificarlos.
# ============================================================

using namespace System.Globalization

$headPath = "src\head.h"
$exe = "main_O2_auto.exe"

$Avals   = @(0.5,0.7,0.9,1.0,1.1,1.2,1.4,1.6,2.0)
$Etavals = @(0.01,0.03,0.1,0.3,0.5,1.0,2.0,3.0,5.0)

$etaFijo = 1.0
$AFijo   = 1.0
$hFijo   = 0.001
$XC      = 0.2
$F       = 0.0

$originalHead = Get-Content $headPath -Raw

function G([double]$x) {
    return $x.ToString("G", [CultureInfo]::InvariantCulture)
}

function Prepare-Head([double]$A, [double]$Eta) {
    $nuevo = $originalHead
    $nuevo = $nuevo -replace '#define\s+A\s+[-+0-9.eE]+',     "#define A $(G $A)"
    $nuevo = $nuevo -replace '#define\s+eta\s+[-+0-9.eE]+',   "#define eta $(G $Eta)"
    $nuevo = $nuevo -replace '#define\s+FEXT\s+[-+0-9.eE]+',  "#define FEXT 0.0"
    $nuevo = $nuevo -replace '#define\s+paso_h\s+[-+0-9.eE]+',"#define paso_h $(G $hFijo)"
    $nuevo = $nuevo -replace '#define\s+flag\s+\d+',           "#define flag 2"
    $nuevo = $nuevo -replace '#define\s+flag_Objetivo\s+\d+',  "#define flag_Objetivo 2"
    Set-Content -Path $headPath -Value $nuevo -Encoding UTF8
}

function Compile-And-Run([double]$A, [double]$Eta) {
    Prepare-Head $A $Eta

    gcc src\main.c src\funciones.c src\random.c -O2 -std=c11 -lm -o $exe
    if ($LASTEXITCODE -ne 0) {
        throw "Error compilando A=$(G $A), eta=$(G $Eta)"
    }

    & ".\$exe"
    if ($LASTEXITCODE -ne 0) {
        throw "Error ejecutando A=$(G $A), eta=$(G $Eta)"
    }
}

function Get-Summary-Line([double]$A,[double]$Eta) {
    $h = G $hFijo
    $a = G $A
    $e = G $Eta
    $f = G $F
    $xc = G $XC

    $file = "results\O2\Verlet\resumen_h${h}_A${a}_eta${e}_F${f}_XC${xc}.txt"

    if (!(Test-Path $file)) {
        throw "No se encuentra el resumen: $file"
    }

    return Get-Content $file |
           Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
           Select-Object -Last 1
}

function Copy-Legacy-Filenames([double]$A,[double]$Eta) {
    $h = G $hFijo
    $a = G $A
    $e = G $Eta
    $f = G $F
    $xc = G $XC
    $dir = "results\O2\Verlet"

    $pairs = @(
        @("$dir\resumen_h${h}_A${a}_eta${e}_F${f}_XC${xc}.txt",
          "$dir\resumen_h${h}_A${a}_eta${e}_XC${xc}.txt"),
        @("$dir\tiempos_derecha_h${h}_A${a}_eta${e}_F${f}_XC${xc}.txt",
          "$dir\tiempos_derecha_h${h}_A${a}_eta${e}_XC${xc}.txt"),
        @("$dir\tiempos_izquierda_h${h}_A${a}_eta${e}_F${f}_XC${xc}.txt",
          "$dir\tiempos_izquierda_h${h}_A${a}_eta${e}_XC${xc}.txt")
    )

    foreach ($pair in $pairs) {
        if (Test-Path $pair[0]) {
            Copy-Item -Force $pair[0] $pair[1]
        }
    }
}

New-Item -ItemType Directory -Force -Path "results\O2" | Out-Null

$outA   = "results\O2\barrido_A_adaptativo.dat"
$outEta = "results\O2\barrido_eta_adaptativo.dat"

"# A tau_global k_sim P_izq P_der estancias_total term_steps measure_steps term_converged stats_converged" |
    Set-Content $outA -Encoding UTF8

"# eta tau_global k_sim P_izq P_der estancias_total term_steps measure_steps term_converged stats_converged" |
    Set-Content $outEta -Encoding UTF8

try {
    # ------------------------------------------------------------
    # 1) Barrido de la altura de barrera A, eta=1
    # ------------------------------------------------------------
    foreach ($A in $Avals) {
        Write-Host ""
        Write-Host "=================================================="
        Write-Host "BARRIDO A: A=$(G $A), eta=$(G $etaFijo), F=0"
        Write-Host "=================================================="

        Compile-And-Run $A $etaFijo
        Copy-Legacy-Filenames $A $etaFijo

        $line = Get-Summary-Line $A $etaFijo
        $c = ($line -split '\s+') | Where-Object { $_ -ne "" }

        if ($c.Count -lt 18) {
            throw "El resumen O2 adaptativo debe tener al menos 18 columnas."
        }

        # 0 h,1 A,2 eta,3 XC,4 Pizq,5 Pder,6 trans,
        # 7 est_izq,8 est_der,9 tau_izq,10 tau_der,11 tau_global,
        # 12 k_sim,13 F,14 term_steps,15 measure_steps,
        # 16 term_converged,17 stats_converged
        $estTot = [long]$c[7] + [long]$c[8]

        "$(G $A) $($c[11]) $($c[12]) $($c[4]) $($c[5]) $estTot $($c[14]) $($c[15]) $($c[16]) $($c[17])" |
            Add-Content $outA -Encoding UTF8
    }

    # ------------------------------------------------------------
    # 2) Barrido de friccion eta, A=1
    # ------------------------------------------------------------
    foreach ($Eta in $Etavals) {
        Write-Host ""
        Write-Host "=================================================="
        Write-Host "BARRIDO ETA: A=$(G $AFijo), eta=$(G $Eta), F=0"
        Write-Host "=================================================="

        Compile-And-Run $AFijo $Eta
        Copy-Legacy-Filenames $AFijo $Eta

        $line = Get-Summary-Line $AFijo $Eta
        $c = ($line -split '\s+') | Where-Object { $_ -ne "" }

        if ($c.Count -lt 18) {
            throw "El resumen O2 adaptativo debe tener al menos 18 columnas."
        }

        $estTot = [long]$c[7] + [long]$c[8]

        "$(G $Eta) $($c[11]) $($c[12]) $($c[4]) $($c[5]) $estTot $($c[14]) $($c[15]) $($c[16]) $($c[17])" |
            Add-Content $outEta -Encoding UTF8
    }

    # Caso adicional que ya aparece en uno de tus scripts de distribucion:
    # A=1.2, eta=5. Evita repetirlo si ya existiera.
    Write-Host ""
    Write-Host "Caso adicional para distribucion: A=1.2, eta=5"
    Compile-And-Run 1.2 5.0
    Copy-Legacy-Filenames 1.2 5.0
}
finally {
    Set-Content -Path $headPath -Value $originalHead -Encoding UTF8

    if (Test-Path $exe) {
        Remove-Item $exe -Force
    }
}

Write-Host ""
Write-Host "=================================================="
Write-Host "BARRIDOS O2 TERMINADOS"
Write-Host "=================================================="
Write-Host "Resumen A   : $outA"
Write-Host "Resumen eta : $outEta"
Write-Host ""
Write-Host "Los nombres legacy sin _F0 tambien han sido creados"
Write-Host "para mantener compatibilidad con tus .plt anteriores."
