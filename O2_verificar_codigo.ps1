# Preflight O2 v14: NO ejecuta simulaciones largas ni modifica resultados.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Push-Location $root
try {
    $requeridos = @('src\head.h','src\main.c','src\funciones.c','src\random.c','O2_master.ps1')
    foreach($p in $requeridos) {
        if(!(Test-Path $p)) {
            throw "Falta $p. El paquete integrado O2 v14 debe contener los cuatro fuentes C."
        }
    }
    $f = Get-Content 'src\funciones.c' -Raw
    if(!($f -match 'FEXT' -and $f -match '\+\s*FEXT' -and $f -match '-\s*FEXT\s*\*\s*x')) {
        throw 'Comprobar fuerza Fdet=-4Ax(x^2-1)+FEXT y energia V=A(x^2-1)^2-FEXT*x.'
    }
    foreach($tag in @('datosEnergia_h','datosTrayectoria_h','Histogramas_h')) {
        if($f -notmatch ($tag+'[^"\r\n]*_A%g_eta%g_F%g')) {
            throw "La rutina src\funciones.c NO parece generar $tag con A, eta y F en el nombre."
        }
    }
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    if(!$gcc) { throw 'No se encuentra gcc. Instala/activa el compilador MinGW usado en tu proyecto.' }
    Write-Host 'Comprobacion de compilacion sin ejecutar:'
    gcc -std=c11 -Wall -Wextra -O2 src\main.c src\funciones.c src\random.c -lm -o O2_preflight.exe
    if($LASTEXITCODE -ne 0) { throw 'GCC devolvio un error de compilacion o enlazado.' }
    Remove-Item 'O2_preflight.exe' -Force
    $gp = 'C:\Program Files\gnuplot\bin\gnuplot.exe'
    if(Test-Path $gp){ & $gp --version } else { Write-Warning "No se encontro Gnuplot en $gp" }
    Write-Host '[OK] Fuentes integrados, nombres de salida y compilacion completa GCC.'
    Write-Host 'Para verificar tiempo de ejecucion, usa O2_autoprueba_corta.ps1.'
} finally {
    if(Test-Path 'O2_preflight.exe'){ Remove-Item 'O2_preflight.exe' -Force }
    Pop-Location
}
