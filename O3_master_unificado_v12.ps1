param(
    [ValidateSet("menu","tamanos","fuerza","fuerzas-todos","graficas")]
    [string]$Modo = "menu",

    [ValidateSet(0,4,8,16,32,64)]
    [int]$N = 0,

    [switch]$ReusarExistentes
)

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$sizes  = Join-Path $root "barrido_tamanos_O3_v12.ps1"
$force  = Join-Path $root "barrido_fuerza_O3_v12.ps1"
$plots  = Join-Path $root "graficar_O3_todo_v12.ps1"


foreach($required in @($sizes,$force,$plots)){
    if(!(Test-Path $required)){
        throw "Falta el archivo auxiliar: $required. Copia TODO el contenido del ZIP a la raiz del proyecto."
    }
}

function Run-Tamanos {
    Write-Host ""
    Write-Host "=== O3 v12: barrido de tamanos N=4,8,16,32,64 ==="
    if($ReusarExistentes){
        & $sizes -ReusarExistentes
    } else {
        & $sizes
    }
}

function Run-Fuerza([int]$NN) {
    if(@(4,8,16,32,64) -notcontains $NN){
        throw "Para fuerza debes indicar -N 4, 8, 16, 32 o 64."
    }
    Write-Host ""
    Write-Host "=== O3 v12: fuerza para N=$NN ==="
    Write-Host "Se ejecutan KE=100 y KE=1000 con EXACTAMENTE las mismas fuerzas."
    if($ReusarExistentes){
        & $force -N $NN -ReusarExistentes
    } else {
        & $force -N $NN
    }
}

function Run-FuerzasTodos {
    Write-Host ""
    Write-Host "=== O3 v12: fuerza para todos los N ==="
    Write-Host "Cada N ejecuta KE=100 y KE=1000 con el mismo barrido de F."
    if($ReusarExistentes){
        & $force -Todos -ReusarExistentes
    } else {
        & $force -Todos
    }
}

function Run-Graficas {
    Write-Host ""
    Write-Host "=== O3 v12: regenerando todas las graficas disponibles ==="
    & $plots
}

if($Modo -eq "menu"){
    Write-Host ""
    Write-Host "============================================================"
    Write-Host "              O3 MASTER UNIFICADO v12"
    Write-Host "============================================================"
    Write-Host "1  - Barrido de tamanos N=4,8,16,32,64"
    Write-Host "2  - Barrido de fuerza para UN N (KE=100 y KE=1000)"
    Write-Host "3  - Barridos de fuerza para TODOS los N"
    Write-Host "4  - Regenerar graficas sin simular"
    Write-Host "0  - Salir"
    Write-Host ""
    $choice = Read-Host "Elige una opcion"

    switch($choice){
        "1" { Run-Tamanos }
        "2" {
            $raw = Read-Host "N (4, 8, 16, 32 o 64)"
            [int]$nn = 0
            if(-not [int]::TryParse($raw,[ref]$nn)){
                throw "N no valido."
            }
            Run-Fuerza $nn
        }
        "3" { Run-FuerzasTodos }
        "4" { Run-Graficas }
        "0" { exit 0 }
        default { throw "Opcion no valida." }
    }
}
elseif($Modo -eq "tamanos"){
    Run-Tamanos
}
elseif($Modo -eq "fuerza"){
    Run-Fuerza $N
}
elseif($Modo -eq "fuerzas-todos"){
    Run-FuerzasTodos
}
elseif($Modo -eq "graficas"){
    Run-Graficas
}
