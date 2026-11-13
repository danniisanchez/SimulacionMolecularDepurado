param(
    [switch]$SoloReconstruir,
    [switch]$SoloGraficas,
    [switch]$ReusarExistentes
)

$ErrorActionPreference = "Stop"
$Ns = @(4,8,16,32,64)
$exe = "o3_v11.exe"
$gnuplot = "C:\Program Files\gnuplot\bin\gnuplot.exe"

function Last-DataLine([string]$file) {
    return Get-Content $file |
        Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
        Select-Object -Last 1
}

function Resumen-Convergido([string]$file) {
    if(!(Test-Path $file)){ return $false }
    $line=Last-DataLine $file
    if(!$line){ return $false }
    $c=($line.Trim() -split '\s+') | Where-Object {$_ -ne ""}
    # v11/adaptativo: col 25=term_converged, 26=stats_converged
    if($c.Count -lt 26){ return $false }
    return (($c[24] -eq "1") -and ($c[25] -eq "1"))
}

function Reconstruir {
    New-Item -ItemType Directory -Force -Path "results\O3" | Out-Null
    $out="results\O3\resumen_tamanos.dat"
    $headerWritten=$false
    foreach($N in $Ns){
        $f="results\O3\N$N\resumen_N$N.dat"
        if(!(Test-Path $f)){ throw "Falta $f" }
        $lines=Get-Content $f
        $header=$lines | Where-Object {$_ -match '^\s*#'} | Select-Object -First 1
        $data=Last-DataLine $f
        if(!$data){ throw "Sin datos en $f" }
        if(!$headerWritten){
            if($header){ Set-Content $out $header -Encoding UTF8 }
            else { Set-Content $out "# N Ek_mean Ek_teo Ebond_mean Ebond_ref Ree_mean Ree2_mean Rg_mean Rg2_mean bond_mean muestras" -Encoding UTF8 }
            $headerWritten=$true
        }
        Add-Content $out $data.Trim() -Encoding UTF8
    }
    Write-Host "[OK] $out reconstruido para N=$($Ns -join ',')"
}

function Graficar {
    if(!(Test-Path $gnuplot)){ throw "No se encuentra Gnuplot en $gnuplot" }
    New-Item -ItemType Directory -Force -Path "plots\O3" | Out-Null
    foreach($N in $Ns){ New-Item -ItemType Directory -Force -Path "plots\O3\N$N" | Out-Null }

    $cwd=Get-Location
    try{
        Set-Location "scriptsGnuplot\O3"
        $scripts=@(
            "O3_01_equiparticion_v11.plt",
            "O3_02_Ree_Rg_vs_N_v11.plt",
            "O3_05_ley_escala_NmenosB_v11.plt"
        )
        foreach($s in $scripts){
            & $gnuplot $s
            if($LASTEXITCODE -ne 0){ throw "Fallo Gnuplot: $s" }
        }
        foreach($N in $Ns){
            & $gnuplot -e "N=$N" "O3_03_termalizacion_normalizada.plt"
            if($LASTEXITCODE -ne 0){ throw "Fallo termalizacion normalizada N=$N" }
            & $gnuplot -e "N=$N" "O3_03_termalizacion_sin_normalizar.plt"
            if($LASTEXITCODE -ne 0){ throw "Fallo termalizacion sin normalizar N=$N" }
            & $gnuplot -e "N=$N" "O3_04_polimero3D_N_v11.plt"
            if($LASTEXITCODE -ne 0){ throw "Fallo snapshot N=$N" }
        }
    } finally {
        Set-Location $cwd
    }
}

if($SoloReconstruir){
    Reconstruir
    if(!$SoloGraficas){ Graficar }
    exit 0
}
if($SoloGraficas){
    Graficar
    exit 0
}

try{
    gcc srcO3\main.c srcO3\funciones.c srcO3\random.c -O2 -std=c11 -Wall -Wextra -pedantic -lm -o $exe
    if($LASTEXITCODE -ne 0){ throw "Error compilando O3." }

    foreach($N in $Ns){
        $res="results\O3\N$N\resumen_N$N.dat"
        if($ReusarExistentes -and (Resumen-Convergido $res)){
            Write-Host "[REUSO] N=$N ya converge."
            continue
        }
        Write-Host ""
        Write-Host "================================================"
        Write-Host "O3 v11: N=$N"
        Write-Host "================================================"
        & ".\$exe" $N | Out-Host
        if($LASTEXITCODE -ne 0){ throw "Fallo O3 N=$N" }
    }

    Reconstruir
    Graficar
}
finally{
    if(Test-Path $exe){ Remove-Item $exe -Force }
}
