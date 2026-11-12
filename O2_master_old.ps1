param(
    [switch]$SoloGraficas,
    [switch]$SinGraficas,
    [switch]$ReusarExistentes
)

# ============================================================
# OBJETIVO 2 - AUTOMATIZADOR MAESTRO v8
#
# Ejecutar desde la raiz del repositorio:
#   .\O2_master.ps1
#
# Modos:
#   .\O2_master.ps1 -SoloGraficas
#   .\O2_master.ps1 -SinGraficas
#   .\O2_master.ps1 -ReusarExistentes
#
# Nucleo esperado:
#   src/main.c
#   src/funciones.c
#   src/random.c
#   src/head.h
#
# Resultados canonicos generados:
#   results/O2/resumen_A.dat
#   results/O2/resumen_eta.dat
#   results/O2/resumen_F.dat
#   results/O2/analisis/*
#
# Los .plt auditados leen SOLO esos nombres estables.
# ============================================================

$ErrorActionPreference = "Stop"

# Ruta absoluta a Gnuplot
$gnuplotExe = "C:\Program Files\gnuplot\bin\gnuplot.exe"
$scriptDirO2 = "scriptsGnuplot\O2"
$projectRoot = $PSScriptRoot

$headPath = "src\head.h"
$exe = "O2_master.exe"
$metodo = "Verlet"

$h = 0.001
$XC = 0.2

# 1. Definir solo A = 0.5 en el array del barrido de A
$Avals = @(0.5)

# eta: cubre mas profundamente baja friccion, turnover y alta friccion.
$Etavals = @(0.005,0.01,0.02,0.03,0.05,0.1,0.2,0.3,0.5,0.7,1.0,1.5,2.0,3.0,5.0,7.0,10.0)

# Fuerza: paso 0.05 desde -0.5 hasta +0.5.
$Fvals = @(-0.50,-0.45,-0.40,-0.35,-0.30,-0.25,-0.20,-0.15,-0.10,-0.05,
           0.00,
           0.05,0.10,0.15,0.20,0.25,0.30,0.35,0.40,0.45,0.50)

# 2. Fijar A = 0.5 para los barridos de eta y de Fuerza
$A_etaSweep = 0.5
$eta_ASweep = 1.0
$A_force = 0.5
$eta_force = 1.0

# 3. Fijar el caso de referencia (para histogramas, trayectoria y energía) a A = 0.5
$Aref = 0.5
$Etaref = 1.0
$Fref = 0.0

function G([double]$x) {
    # Formato para nombres de archivo: compacto, sin cambiar 1.0 -> 1
    return $x.ToString("G17",[System.Globalization.CultureInfo]::InvariantCulture)
}

function CFloat([double]$x) {
    # Literal C SIEMPRE de punto flotante.
    # Evita que eta=1 se convierta en macro entero y rompa printf("%g", eta).
    $s=$x.ToString("G17",[System.Globalization.CultureInfo]::InvariantCulture)
    if(($s -notmatch '[\.eE]')) { $s += ".0" }
    return $s
}

function FName([double]$x) {
    # Convencion de nombres compatible con %g de C para los valores del barrido.
    return $x.ToString("G",[System.Globalization.CultureInfo]::InvariantCulture)
}

function Ensure-Dirs {
    @(
      "results\O2",
      "results\O2\Verlet",
      "results\O2\analisis",
      "plots\O2",
      "plots\O2\Verlet",
      "plots\O2\Trayectorias"
    ) | ForEach-Object {
        New-Item -ItemType Directory -Force -Path $_ | Out-Null
    }
}

function Get-Limits([double]$Aval,[double]$Etaval,[double]$Fval) {
    # Límite NORMAL: la mayoría de puntos.
    [long]$termMax = 300000000
    [long]$measMax = 1000000000
    $clase = "normal"

    # Casos de mezcla lenta / Kramers difícil.
    if(($Aval -ge 1.4) -or ($Etaval -le 0.03) -or ($Etaval -ge 5.0)) {
        $termMax = 600000000
        $measMax = 1000000000
        $clase = "dificil"
    }

    # Extremos: barrera alta o fricción muy extrema.
    if(($Aval -ge 1.8) -or ($Etaval -le 0.01) -or ($Etaval -ge 10.0)) {
        $termMax = 1500000000
        $measMax = 1000000000
        $clase = "extremo"
    }

    return [PSCustomObject]@{
        TermMax = $termMax
        MeasureMax = $measMax
        Clase = $clase
    }
}

function Existing-IsReusable([string]$file) {
    if(!(Test-Path $file)) { return $false }
    try {
        $c = Read-Summary $file
        # Reusar únicamente si la versión contiene flags v7/v8 y
        # termalización + mezcla global + estadística están aprobadas.
        if($c.Count -ge 28) {
            return (($c[16] -eq "1") -and ($c[17] -eq "1") -and ($c[27] -eq "1"))
        }
    } catch {}
    return $false
}

function Set-Head([double]$Aval,[double]$Etaval,[double]$Fval) {
    $base = $script:originalHead
    $base = $base -replace '#define\s+A\s+[-+0-9.eE]+',      "#define A $(CFloat $Aval)"
    $base = $base -replace '#define\s+eta\s+[-+0-9.eE]+',    "#define eta $(CFloat $Etaval)"
    $base = $base -replace '#define\s+FEXT\s+[-+0-9.eE]+',   "#define FEXT $(CFloat $Fval)"
    $base = $base -replace '#define\s+paso_h\s+[-+0-9.eE]+', "#define paso_h $(CFloat $h)"
    $base = $base -replace '#define\s+flag\s+\d+',            "#define flag 2"
    $base = $base -replace '#define\s+flag_Objetivo\s+\d+',   "#define flag_Objetivo 2"

    $lim = Get-Limits $Aval $Etaval $Fval
    $base = $base -replace '#define\s+termSteps\s+\d+L',      "#define termSteps $($lim.TermMax)L"
    $base = $base -replace '#define\s+numberSteps\s+\d+L',    "#define numberSteps $($lim.MeasureMax)L"

    Write-Host "Clase de muestreo: $($lim.Clase) | TERM_MAX=$($lim.TermMax) | MEASURE_MAX=$($lim.MeasureMax)"
    Set-Content $headPath $base -Encoding UTF8
}

function Summary-Candidates([double]$Aval,[double]$Etaval,[double]$Fval) {
    $hh=FName $h; $a=FName $Aval; $e=FName $Etaval; $f=FName $Fval; $xc=FName $XC
    $dir="results\O2\$metodo"

    return @(
      "$dir\resumen_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
      "$dir\resumen_h${hh}_A${a}_eta${e}_XC${xc}.txt"
    )
}

function Resolve-Summary([double]$Aval,[double]$Etaval,[double]$Fval) {
    foreach($p in (Summary-Candidates $Aval $Etaval $Fval)) {
        if(Test-Path $p) { return $p }
    }

    $dir="results\O2\$metodo"
    $a=FName $Aval; $e=FName $Etaval
    $found=Get-ChildItem $dir -Filter "resumen_*.txt" -ErrorAction SilentlyContinue |
           Where-Object { $_.Name -like "*_A${a}_eta${e}_*" } |
           Sort-Object LastWriteTime -Descending

    if($found.Count -gt 0) {
        Write-Host "[AVISO] Nombre no canonico detectado: $($found[0].Name)"
        return $found[0].FullName
    }

    return $null
}

function Run-Case([double]$Aval,[double]$Etaval,[double]$Fval) {
    $existing=Resolve-Summary $Aval $Etaval $Fval

    if ($ReusarExistentes -and $existing -and (Existing-IsReusable $existing)) {
        Write-Host "[REUSO CONVERGIDO] A=$(G $Aval) eta=$(G $Etaval) F=$(G $Fval) -> $existing"
        return $existing
    }
    elseif($ReusarExistentes -and $existing) {
        Write-Host "[REPETIR] Existe resultado, pero no supera term/global/stats: $existing"
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "O2: A=$(G $Aval)   eta=$(G $Etaval)   F=$(G $Fval)"
    Write-Host "============================================================"

    Set-Head $Aval $Etaval $Fval

    # Comprobacion visible de macros escritos en head.h
    $defs = Select-String -Path $headPath -Pattern '^#define\s+(A|eta|FEXT|paso_h|termSteps|numberSteps)\s+' |
            ForEach-Object { $_.Line.Trim() }
    Write-Host "Parametros C:"
    $defs | ForEach-Object { Write-Host "  $_" }

    gcc src\main.c src\funciones.c src\random.c -O2 -std=c11 -lm -o $exe 2>&1 | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Error compilando A=$Aval eta=$Etaval F=$Fval"
    }

    & ".\$exe" | Out-Host
    if ($LASTEXITCODE -ne 0) {
        throw "Error ejecutando A=$Aval eta=$Etaval F=$Fval"
    }

    $summary=Resolve-Summary $Aval $Etaval $Fval

    if (!$summary) {
        Write-Host ""
        Write-Host "Resúmenes encontrados en results\O2\$metodo :"
        Get-ChildItem "results\O2\$metodo" -Filter "resumen_*.txt" -ErrorAction SilentlyContinue |
          Select-Object -ExpandProperty Name |
          ForEach-Object { Write-Host "  $_" }

        throw "La simulacion termino, pero no se encontro resumen compatible para A=$Aval eta=$Etaval F=$Fval."
    }

    Write-Host "[OK] Resumen detectado: $summary"
    return [string]$summary
}

function Read-Summary([string]$file) {
    $line = Get-Content $file |
            Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne "" } |
            Select-Object -Last 1

    if (!$line) { throw "Resumen vacio: $file" }

    $c = ($line.Trim() -split '\s+') | Where-Object { $_ -ne "" }

    if ($c.Count -lt 13) {
        throw "El resumen $file tiene solo $($c.Count) columnas; se requieren al menos 13."
    }

    return ,$c
}

function Add-AggregateRow([string]$out,[double]$param,[string[]]$c) {
    # Primeras 21 columnas: compatibles con la version adaptativa anterior.
    $termSteps="nan"; $measSteps="nan"; $termConv="nan"; $statsConv="nan"
    $dEk="nan"; $dEp="nan"; $dX2="nan"
    $pth="nan"; $errTerm="nan"; $mixTrans="nan"; $errMed="nan"
    $relTauI="nan"; $relTauD="nan"; $globalTerm="nan"

    if($c.Count -ge 18) {
        $termSteps=$c[14]; $measSteps=$c[15]
        $termConv=$c[16]; $statsConv=$c[17]
    }
    if($c.Count -ge 21) {
        $dEk=$c[18]; $dEp=$c[19]; $dX2=$c[20]
    }
    if($c.Count -ge 28) {
        $pth=$c[21]; $errTerm=$c[22]; $mixTrans=$c[23]
        $errMed=$c[24]; $relTauI=$c[25]; $relTauD=$c[26]
        $globalTerm=$c[27]
    }

    "$(FName $param) $($c[4]) $($c[5]) $($c[6]) $($c[7]) $($c[8]) $($c[9]) $($c[10]) $($c[11]) $($c[12]) $termSteps $measSteps $termConv $statsConv $dEk $dEp $dX2 $pth $errTerm $mixTrans $errMed $relTauI $relTauD $globalTerm" |
        Add-Content $out -Encoding UTF8
}

function First-Existing([string[]]$paths) {
    foreach($p in $paths) {
        if(Test-Path $p) { return $p }
    }
    return $null
}

function Make-Reference-Aliases {
    $base="results\O2\$metodo"
    $a=FName $Aref; $e=FName $Etaref; $f=FName $Fref; $hh=FName $h; $xc=FName $XC

    $summary=Resolve-Summary $Aref $Etaref $Fref
    $right=First-Existing @(
      "$base\tiempos_derecha_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
      "$base\tiempos_derecha_h${hh}_A${a}_eta${e}_XC${xc}.txt"
    )
    $left=First-Existing @(
      "$base\tiempos_izquierda_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt",
      "$base\tiempos_izquierda_h${hh}_A${a}_eta${e}_XC${xc}.txt"
    )
    $energy=First-Existing @(
      "$base\datosEnergia_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
      "$base\datosEnergia_h${hh}_A${a}_eta${e}_${metodo}.txt"
    )
    $traj=First-Existing @(
      "$base\datosTrayectoria_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
      "$base\datosTrayectoria_h${hh}_A${a}_eta${e}_${metodo}.txt"
    )
    $hist=First-Existing @(
      "$base\Histogramas_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt",
      "$base\Histogramas_h${hh}_A${a}_eta${e}_${metodo}.txt"
    )

    $pairs=@(
      @($summary,"results\O2\analisis\resumen_referencia.txt"),
      @($right,"results\O2\analisis\tiempos_derecha.dat"),
      @($left,"results\O2\analisis\tiempos_izquierda.dat"),
      @($energy,"results\O2\analisis\energia.dat"),
      @($traj,"results\O2\analisis\trayectoria.dat"),
      @($hist,"results\O2\analisis\histograma.dat")
    )

    foreach($p in $pairs) {
        if(!$p[0]) { throw "Falta un archivo del caso de referencia A=$Aref eta=$Etaref F=$Fref." }
        Copy-Item -Force $p[0] $p[1]
    }

    "# A eta F h XC KBT`n$(G $Aref) $(G $Etaref) $(G $Fref) $(G $h) $(G $XC) 0.2" |
      Set-Content "results\O2\analisis\parametros.dat" -Encoding UTF8
}


function GPPath([string]$p) {
    # Gnuplot en Windows acepta mejor rutas absolutas con "/".
    return ([System.IO.Path]::GetFullPath($p)).Replace('\','/')
}

function Plot-Case([double]$Aval,[double]$Etaval,[double]$Fval) {
    if (!(Test-Path $gnuplotExe)) { return }

    $a=FName $Aval
    $e=FName $Etaval
    $f=FName $Fval
    $hh=FName $h
    $xc=FName $XC

    $baseData = Join-Path $projectRoot "results\O2\$metodo"
    $basePlot = Join-Path $projectRoot "plots\O2\Detalles"
    $scriptBase = Join-Path $projectRoot "scriptsGnuplot\O2"

    $dirHist = Join-Path $basePlot "hist_posicion"
    $dirTau  = Join-Path $basePlot "tiempos"
    $dirEn   = Join-Path $basePlot "energia"
    $dirTr   = Join-Path $basePlot "trayectorias"
    $dirTerm = Join-Path $basePlot "termalizacion"

    New-Item -ItemType Directory -Force -Path $dirHist | Out-Null
    New-Item -ItemType Directory -Force -Path $dirTau  | Out-Null
    New-Item -ItemType Directory -Force -Path $dirEn   | Out-Null
    New-Item -ItemType Directory -Force -Path $dirTr   | Out-Null
    New-Item -ItemType Directory -Force -Path $dirTerm | Out-Null

    $hist = Join-Path $baseData "Histogramas_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $tr   = Join-Path $baseData "datosTrayectoria_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $en   = Join-Path $baseData "datosEnergia_h${hh}_A${a}_eta${e}_F${f}_${metodo}.txt"
    $td   = Join-Path $baseData "tiempos_derecha_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"
    $ti   = Join-Path $baseData "tiempos_izquierda_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"
    $tb   = Join-Path $baseData "termalizacion_bloques_h${hh}_A${a}_eta${e}_F${f}_XC${xc}.txt"

    # Compatibilidad con salidas antiguas sin F en el nombre.
    if (!(Test-Path $hist)) {
        $hist = Join-Path $baseData "Histogramas_h${hh}_A${a}_eta${e}_${metodo}.txt"
    }
    if (!(Test-Path $tr)) {
        $tr = Join-Path $baseData "datosTrayectoria_h${hh}_A${a}_eta${e}_${metodo}.txt"
    }
    if (!(Test-Path $en)) {
        $en = Join-Path $baseData "datosEnergia_h${hh}_A${a}_eta${e}_${metodo}.txt"
    }
    if (!(Test-Path $td)) {
        $td = Join-Path $baseData "tiempos_derecha_h${hh}_A${a}_eta${e}_XC${xc}.txt"
    }
    if (!(Test-Path $ti)) {
        $ti = Join-Path $baseData "tiempos_izquierda_h${hh}_A${a}_eta${e}_XC${xc}.txt"
    }

    $plotTag = "A${a}_eta${e}_F${f}"

    $sHist = Join-Path $scriptBase "O2_C01_hist_posicion_caso.plt"
    $sTau  = Join-Path $scriptBase "O2_C02_tiempos_estancia_caso.plt"
    $sEn   = Join-Path $scriptBase "O2_C03_energia_caso.plt"
    $sTr   = Join-Path $scriptBase "O2_C04_trayectoria_caso.plt"
    $sTerm = Join-Path $scriptBase "O2_C05_termalizacion_bloques_caso.plt"

    if ((Test-Path $sHist) -and (Test-Path $hist)) {
        $in  = GPPath $hist
        $out = GPPath (Join-Path $dirHist "Px_${plotTag}.png")
        $scr = GPPath $sHist
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; KBT=0.2" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo Px para $plotTag" }
    }

    if ((Test-Path $sTau) -and (Test-Path $td) -and (Test-Path $ti)) {
        $r   = GPPath $td
        $l   = GPPath $ti
        $out = GPPath (Join-Path $dirTau "Tiempos_${plotTag}.png")
        $scr = GPPath $sTau
        & $gnuplotExe -e "rightfile='$r'; leftfile='$l'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo tiempos para $plotTag" }
    }

    if ((Test-Path $sEn) -and (Test-Path $en)) {
        $in  = GPPath $en
        $out = GPPath (Join-Path $dirEn "Energia_${plotTag}.png")
        $scr = GPPath $sEn
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; KBT=0.2" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo energia para $plotTag" }
    }

    if ((Test-Path $sTr) -and (Test-Path $tr)) {
        $in  = GPPath $tr
        $out = GPPath (Join-Path $dirTr "Trayectoria_${plotTag}.png")
        $scr = GPPath $sTr
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo trayectoria para $plotTag" }
    }

    if ((Test-Path $sTerm) -and (Test-Path $tb)) {
        $in  = GPPath $tb
        $out = GPPath (Join-Path $dirTerm "Termalizacion_${plotTag}.png")
        $scr = GPPath $sTerm
        & $gnuplotExe -e "datafile='$in'; outfile='$out'; AVAL=$Aval; ETAVAL=$Etaval; FVAL=$Fval; KBT=0.2" $scr
        if($LASTEXITCODE -ne 0) { Write-Host "[AVISO] Fallo termalizacion por bloques para $plotTag" }
    }
}

function Run-Gnuplots {
    $scripts = @(
      "O2_01_distribucion_tiempos.plt",
      "O2_02_tau_vs_A.plt",
      "O2_03_tau_k_vs_eta.plt",
      "O2_04_ocupaciones_A_eta.plt",
      "O2_F01_ocupacion_vs_fuerza.plt",
      "O2_F02_tiempos_vs_fuerza.plt",
      "O2_F03_potencial_inclinado.plt",
      "O2_F04_diferencia_ocupacion.plt",
      "O2_D01_energia.plt",
      "O2_D02_histograma.plt",
      "O2_D03_trayectoria_fase.plt",
      "O2_D04_trayectoria_zoom.plt"
    )

    if (!(Test-Path $gnuplotExe)) {
        Write-Host "[AVISO] No se encuentra Gnuplot en:"
        Write-Host "        $gnuplotExe"
        return
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "GENERANDO FIGURAS CON GNUPLOT"
    Write-Host "============================================================"
    Write-Host "Gnuplot: $gnuplotExe"

    Push-Location "scriptsGnuplot\O2"
    try {
        foreach($s in $scripts) {
            if(Test-Path $s) {
                Write-Host ""
                Write-Host "Ejecutando: $s"

                & $gnuplotExe $s

                if($LASTEXITCODE -ne 0) {
                    Write-Host "[AVISO] Gnuplot fallo en $s"
                }
                else {
                    Write-Host "[OK] $s"
                }
            }
            else {
                Write-Host "[AVISO] No existe scriptsGnuplot\O2\$s"
            }
        }
    }
    finally {
        Pop-Location
    }

    Write-Host ""
    Write-Host "Figuras generadas en plots\O2\"
}

Ensure-Dirs

$headText=Get-Content "src\head.h" -Raw
if(($headText -notmatch "TERM_TOL_OCC") -or
   ($headText -notmatch "MEASURE_MAX_RELERR_TAU") -or
   ($headText -notmatch "O2_V8_EXTENDED_SWEEPS")) {
    throw "Tu src\\head.h no es la version O2 v7. Copia head_O2_v7.h como src\\head.h."
}

$funcText=Get-Content "src\funciones.c" -Raw
$forceOK=($funcText -match 'FEXT') -and
         ($funcText -match '\+\s*FEXT') -and
         ($funcText -match '-\s*FEXT\s*\*\s*x')

if(!$forceOK) {
    throw @"
Tu src\funciones.c no parece incluir correctamente la fuerza externa.

Debe contener:
  F(x) = -4*A*x*(x*x-1) + FEXT
  V(x) =  A*(x*x-1)^2 - FEXT*x

Copia funciones_O2_v7.c como src\funciones.c.
"@
}

$mainText=Get-Content "src\main.c" -Raw
if(($mainText -notmatch 'TERM_MIN_TRANSITIONS') -or
   ($mainText -notmatch 'MEASURE_MAX_RELERR_TAU') -or
   ($mainText -notmatch 'termalizacion_bloques')) {
    throw @"
Tu src\main.c no es la version O2 v8 con control de mezcla global.
Copia main_O2_v8.c como src\main.c antes de ejecutar el automatizador.
"@
}

if ($SoloGraficas) {
    Write-Host "Regenerando graficas detalladas a partir de los datos existentes..."
    Plot-Case $Aref $Etaref $Fref

    foreach($Aval in $Avals) {
        Plot-Case $Aval $eta_ASweep 0.0
    }
    foreach($Etaval in $Etavals) {
        Plot-Case $A_etaSweep $Etaval 0.0
    }
    foreach($Fval in $Fvals) {
        Plot-Case $A_force $eta_force $Fval
    }

    Run-Gnuplots
    exit 0
}

$originalHead = Get-Content $headPath -Raw

$header = "# param P_izq P_der transiciones estancias_izq estancias_der tau_izq tau_der tau_global k_sim term_steps measure_steps term_converged stats_converged dEk_term dEp_term dX2_term Pizq_teoria occ_err_term term_mix_trans occ_err_measure relerr_tau_izq relerr_tau_der term_global_ok"

$outA   = "results\O2\resumen_A.dat"
$outEta = "results\O2\resumen_eta.dat"
$outF   = "results\O2\resumen_F.dat"

$header | Set-Content $outA -Encoding UTF8
$header | Set-Content $outEta -Encoding UTF8
$header | Set-Content $outF -Encoding UTF8

Write-Host ""
Write-Host "BARRIDO v8:"
Write-Host "  A   : $($Avals.Count) puntos, $($Avals[0]) -> $($Avals[-1])"
Write-Host "  eta : $($Etavals.Count) puntos, $($Etavals[0]) -> $($Etavals[-1])"
Write-Host "  F   : $($Fvals.Count) puntos, $($Fvals[0]) -> $($Fvals[-1])"
$FcritForce = 8.0*$A_force/(3.0*[Math]::Sqrt(3.0))
Write-Host ("  Barrido F usa A={0}; Fcrit={1:N4}. +/-0.5 inclina/rompe simetria, pero mantiene dos minimos." -f $A_force,$FcritForce)
Write-Host ""

try {
    # 0) Caso de referencia para diagnosticos
    Run-Case $Aref $Etaref $Fref | Out-Null
    Make-Reference-Aliases
    Plot-Case $Aref $Etaref $Fref

    # 1) Dependencia con altura de barrera A, eta=1, F=0
    foreach($Aval in $Avals) {
        $file=Run-Case $Aval $eta_ASweep 0.0
        $c=Read-Summary $file
        Add-AggregateRow $outA $Aval $c
        Plot-Case $Aval $eta_ASweep 0.0
    }

    # 2) Dependencia con friccion eta / turnover de Kramers, A=1, F=0
    foreach($Etaval in $Etavals) {
        $file=Run-Case $A_etaSweep $Etaval 0.0
        $c=Read-Summary $file
        Add-AggregateRow $outEta $Etaval $c
        Plot-Case $A_etaSweep $Etaval 0.0
    }

    # 3) Fuerza externa, A=1, eta=1
    foreach($Fval in $Fvals) {
        $file=Run-Case $A_force $eta_force $Fval
        $c=Read-Summary $file
        Add-AggregateRow $outF $Fval $c
        Plot-Case $A_force $eta_force $Fval
    }
}
finally {
    Set-Content $headPath $originalHead -Encoding UTF8
    if(Test-Path $exe){ Remove-Item $exe -Force }
}

Write-Host ""
Write-Host "============================================================"
Write-Host "OBJETIVO 2: BARRIDOS TERMINADOS"
Write-Host "============================================================"
Write-Host $outA
Write-Host $outEta
Write-Host $outF
Write-Host "Caso de referencia: results\O2\analisis\"

if (!$SinGraficas) {
    Run-Gnuplots
}
