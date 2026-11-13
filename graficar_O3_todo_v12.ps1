
# O3_AUTO_TERMALIZACIONES_AMBAS_v1
& (Join-Path $PSScriptRoot "O3_generar_ambas_termalizaciones.ps1")
# FIN_O3_AUTO_TERMALIZACIONES_AMBAS_v1
$gp="C:\Program Files\gnuplot\bin\gnuplot.exe"
$Ns=@(4,8,16,32,64)
if(!(Test-Path $gp)){throw "No se encuentra Gnuplot."}
foreach($N in $Ns){New-Item -ItemType Directory -Force -Path "plots\O3\N$N"|Out-Null}
$cwd=Get-Location
try{
  Set-Location "scriptsGnuplot\O3"

  foreach($s in @(
    "O3_01_equiparticion_v11.plt",
    "O3_02_Ree_Rg_vs_N_v11.plt",
    "O3_05_ley_escala_NmenosB_v11.plt"
  )){
    & $gp $s
  }

  foreach($N in $Ns){
    & $gp -e "N=$N" "O3_03_termalizacion_N_v11.plt"
    & $gp -e "N=$N" "O3_04_polimero3D_N_v11.plt"

    $f100="../../results/O3/ree_vs_fuerza_N${N}_KE100.dat"
    $f1000="../../results/O3/ree_vs_fuerza_N${N}_KE1000.dat"
    if((Test-Path $f100) -and (Test-Path $f1000)){
      & $gp -e "N=$N" "O3_06_EFJC_KE100_KE1000_N_v12.plt"
      & $gp -e "N=$N" "O3_07_EFJC_KE100_KE1000_log_N_v12.plt"
    }
  }
}
finally{Set-Location $cwd}
