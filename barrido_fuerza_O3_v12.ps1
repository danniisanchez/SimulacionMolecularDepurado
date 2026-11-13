param(
    [int]$N = 0,
    [switch]$Todos,
    [switch]$ReusarExistentes,
    [switch]$SoloGraficas
)

$ErrorActionPreference="Stop"

$NsPermitidos=@(4,8,16,32,64)
$KEvals=@(100.0,1000.0)

# IMPORTANTE: exactamente el mismo barrido para KE=100 y KE=1000.
$forces=@(0.0,0.03,0.1,0.3,0.5,1.0,2.0,3.0,5.0,10.0,20.0,50.0)

$headPath="srcO3\head.h"
$exe="o3_force_v12.exe"
$gnuplot="C:\Program Files\gnuplot\bin\gnuplot.exe"

if($Todos){ $Ns=$NsPermitidos }
elseif($NsPermitidos -contains $N){ $Ns=@($N) }
else { throw "Usa -N 4,8,16,32,64 o -Todos." }

function FName([double]$x){
    return $x.ToString("G12",[System.Globalization.CultureInfo]::InvariantCulture)
}
function CFloat([double]$x){
    $s=$x.ToString("G17",[System.Globalization.CultureInfo]::InvariantCulture)
    if($s -notmatch '[\.eE]'){ $s += ".0" }
    return $s
}
function Last-DataLine([string]$file){
    return Get-Content $file |
      Where-Object {$_ -notmatch '^\s*#' -and $_.Trim() -ne ""} |
      Select-Object -Last 1
}

function Plot-OneN([int]$NN){
    if(!(Test-Path $gnuplot)){ return }
    New-Item -ItemType Directory -Force -Path "plots\O3\N$NN" | Out-Null
    $cwd=Get-Location
    try{
        Set-Location "scriptsGnuplot\O3"

        $f100="../../results/O3/ree_vs_fuerza_N${NN}_KE100.dat"
        $f1000="../../results/O3/ree_vs_fuerza_N${NN}_KE1000.dat"

        if((Test-Path $f100) -and (Test-Path $f1000)){
            & $gnuplot -e "N=$NN" "O3_06_EFJC_KE100_KE1000_N_v12.plt"
            if($LASTEXITCODE -ne 0){ throw "Fallo grafica comparativa N=$NN" }

            & $gnuplot -e "N=$NN" "O3_07_EFJC_KE100_KE1000_log_N_v12.plt"
            if($LASTEXITCODE -ne 0){ throw "Fallo grafica log comparativa N=$NN" }
        }
    } finally {
        Set-Location $cwd
    }
}

if($SoloGraficas){
    foreach($NN in $Ns){ Plot-OneN $NN }
    exit 0
}

$original=Get-Content $headPath -Raw

try{
    foreach($NN in $Ns){
        New-Item -ItemType Directory -Force -Path "results\O3" | Out-Null

        foreach($KEval in $KEvals){
            $ketag=[int]$KEval
            $outFile="results\O3\ree_vs_fuerza_N${NN}_KE${ketag}.dat"

            if(!(Test-Path $outFile) -or -not $ReusarExistentes){
                "# F_ext Ree_parallel_mean Ree_mean bond_mean muestras term_converged stats_converged KE" |
                    Set-Content $outFile -Encoding UTF8
            }

            $existing=@{}
            if($ReusarExistentes -and (Test-Path $outFile)){
                foreach($line in Get-Content $outFile){
                    if($line -match '^\s*#' -or $line.Trim() -eq ""){continue}
                    $c=$line.Trim() -split '\s+'
                    if($c.Count -ge 8 -and $c[6] -eq "1"){
                        $existing[$c[0]]=$true
                    }
                }
            }

            foreach($F in $forces){
                $fkey=FName $F

                if($existing.ContainsKey($fkey)){
                    Write-Host "[REUSO] N=$NN KE=$KEval F=$F"
                    continue
                }

                Write-Host ""
                Write-Host "================================================"
                Write-Host "O3 fuerza: N=$NN | KE=$KEval | F=$F"
                Write-Host "================================================"

                # Partimos siempre del head original: cambiamos F y KE a la vez.
                $new=$original
                $new=$new -replace '#define\s+F_ext\s+[-+0-9.eE]+',
                                   ("#define F_ext "+(CFloat $F))
                $new=$new -replace '#define\s+KE\s+[-+0-9.eE]+',
                                   ("#define KE "+(CFloat $KEval))

                Set-Content $headPath $new -Encoding UTF8

                gcc srcO3\main.c srcO3\funciones.c srcO3\random.c `
                    -O2 -std=c11 -Wall -Wextra -pedantic -lm -o $exe
                if($LASTEXITCODE -ne 0){
                    throw "Error compilando N=$NN KE=$KEval F=$F"
                }

                & ".\$exe" $NN | Out-Host
                if($LASTEXITCODE -ne 0){
                    throw "Fallo N=$NN KE=$KEval F=$F"
                }

                $sum="results\O3\N$NN\resumen_N$NN.dat"
                $line=Last-DataLine $sum
                $c=($line.Trim() -split '\s+') | Where-Object {$_ -ne ""}

                if($c.Count -lt 26){
                    throw "Resumen incompatible en $sum"
                }

                $Ree=$c[5]
                $bond=$c[9]
                $samples=$c[10]
                $ReePar=$c[11]
                $termOK=$c[24]
                $statsOK=$c[25]

                "$fkey $ReePar $Ree $bond $samples $termOK $statsOK $ketag" |
                    Add-Content $outFile -Encoding UTF8
            }
        }

        Plot-OneN $NN
    }
}
finally{
    Set-Content $headPath $original -Encoding UTF8
    if(Test-Path $exe){ Remove-Item $exe -Force }
}
