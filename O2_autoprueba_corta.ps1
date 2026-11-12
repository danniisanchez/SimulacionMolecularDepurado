# Smoke test de integracion de ~100 000 pasos. Usa COPIAS temporales de los fuentes.
# NO es una corrida de produccion: no sirve para estimar ocupaciones ni tau finales.
$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$files=@('head.h','main.c','funciones.c','random.c')
foreach($n in $files) {
    if(!(Test-Path (Join-Path $root "src\$n"))) {
        throw "Falta src\$n. Aporta los fuentes originales para ejecutar esta autoprueba."
    }
}
$folder=Join-Path ([System.IO.Path]::GetTempPath()) ("O2_smoke_"+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path (Join-Path $folder 'src') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $folder 'results\O2\Verlet') | Out-Null
foreach($n in $files){ Copy-Item (Join-Path $root "src\$n") (Join-Path $folder "src\$n") }
$head=Join-Path $folder 'src\head.h'
$text=Get-Content $head -Raw
$macros=@{
    A='0.5'; FEXT='0.1'; eta='1.0'; paso_h='0.001'; flag='2'; flag_Objetivo='2'
    termSteps='50000L'; numberSteps='100000L'
    TERM_MIN_STEPS='10000L'; TERM_BLOCK_STEPS='5000L'; TERM_STABLE_BLOCKS='1'
    TERM_MIX_START_STEPS='1000L'; TERM_MIN_TRANSITIONS='0L'
    MEASURE_MIN_STEPS='50000L'; MEASURE_CHECK_EVERY='10000L'
    MIN_ESTANCIAS_TOTAL='1L'; MIN_ESTANCIAS_POR_POZO='1L'
    guardar_cada='100L'; ZOOM_SAVE_EVERY='10L'; ZOOM_CAPTURE_STEPS='20000L'
    TERM_FIXED_STEPS_MODE='1'; MEASURE_FORCE_MAX='1'
}
foreach($key in $macros.Keys){
    $pattern='(?m)^(#define\s+'+[regex]::Escape($key)+'\s+)\S+'
    if($text -notmatch $pattern) { throw "No se encontro macro de prueba: $key" }
    $text=[regex]::Replace($text,$pattern,('${1}'+$macros[$key]))
}
[System.IO.File]::WriteAllText($head,$text,[System.Text.UTF8Encoding]::new($false))
Push-Location $folder
try {
    Write-Host "[SMOKE] Trabajando en copia temporal: $folder"
    gcc -std=c11 -O2 src\main.c src\funciones.c src\random.c -lm -o O2_smoke.exe
    if($LASTEXITCODE -ne 0) { throw 'No se pudieron compilar los fuentes reales en el directorio temporal.' }
    & '.\O2_smoke.exe' 2>&1 | Tee-Object -FilePath 'O2_smoke.log'
    if($LASTEXITCODE -ne 0){throw 'Fallo ejecutando el smoke test.'}
    $resumen='results\O2\Verlet\resumen_h0.001_A0.5_eta1_F0.1_XC0.2.txt'
    if(!(Test-Path $resumen)) { throw "El archivo esperado no existe: $resumen" }
    $line=Get-Content $resumen | Where-Object { $_.Trim() -ne '' -and $_ -notmatch '^\s*#' } | Select-Object -Last 1
    $c=$line.Trim() -split '\s+'
    if($c.Count -ne 28){throw "Se esperan 28 columnas; se obtuvieron $($c.Count)."}
    if($c[1] -ne '0.5' -or $c[2] -ne '1' -or $c[13] -ne '0.1') {
        throw 'A, eta o F no coinciden con los valores solicitados; posible error de macros/printf.'
    }
    $expected=@(
        'datosEnergia_h0.001_A0.5_eta1_F0.1_Verlet.txt',
        'datosTrayectoria_h0.001_A0.5_eta1_F0.1_Verlet.txt',
        'datosTrayectoriaZoom_h0.001_A0.5_eta1_F0.1_Verlet.txt',
        'Histogramas_h0.001_A0.5_eta1_F0.1_Verlet.txt'
    )
    foreach($p in $expected) {
        if(!(Test-Path "results\O2\Verlet\$p")) { throw "Salida moderna ausente: $p" }
    }
    '[OK] 28 columnas, A, eta, F, histogramas, energia, trayectoria y zoom.' |
        Tee-Object -FilePath 'O2_smoke_reporte.txt'
    Write-Host "[OK] Envia O2_smoke.log y O2_smoke_reporte.txt si quieres que audite la ejecución: $folder"
} finally { Pop-Location }
