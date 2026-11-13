# Aplica una sola llamada al auxiliar original graficar_O3_todo_v12.ps1
# No elimina ni sustituye ninguna de sus llamadas existentes.
# Crea copia de seguridad ANTES de modificarlo y comprueba sintaxis.
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$target = Join-Path $root 'graficar_O3_todo_v12.ps1'
$helper = Join-Path $root 'O3_generar_ambas_termalizaciones.ps1'
$marker = '# O3_AUTO_TERMALIZACIONES_AMBAS_v1'

if (-not (Test-Path -LiteralPath $target -PathType Leaf)) {
    throw "No esta graficar_O3_todo_v12.ps1 en $root. Coloca este paquete junto al original."
}
if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) {
    throw "Falta el auxiliar: $helper"
}

# Comprobacion de idempotencia: se puede repetir el parche sin duplicar llamadas.
# Conserva la codificacion original al escribir: UTF-8, UTF-16 o ANSI.
$bytes = [System.IO.File]::ReadAllBytes($target)
$bom = [byte[]]@()
if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    $encoding = New-Object System.Text.UTF8Encoding($true)
    $bom = [byte[]](239,187,191)
}
elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) {
    $encoding = New-Object System.Text.UnicodeEncoding($false,$true)
    $bom = [byte[]](255,254)
}
elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255) {
    $encoding = New-Object System.Text.UnicodeEncoding($true,$true)
    $bom = [byte[]](254,255)
}
else {
    $encoding = New-Object System.Text.UTF8Encoding($false,$true)
    try { $null = $encoding.GetString($bytes) }
    catch { $encoding = [System.Text.Encoding]::Default }
}
$payload = New-Object byte[] ($bytes.Length - $bom.Length)
[Array]::Copy($bytes, $bom.Length, $payload, 0, $payload.Length)
$original = $encoding.GetString($payload)
if ($original.Contains($marker)) {
    Write-Host '[OK] El parche ya estaba aplicado. No se ha cambiado nada.'
    exit 0
}

$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    $target, [ref]$tokens, [ref]$errors
)
if ($errors.Count -gt 0) {
    throw 'El graficar original tiene errores de sintaxis; no se modifica.'
}

# Insertamos tras el bloque param (si existe); asi se ejecuta tambien si
# el original termina con exit o retorna antes del final del archivo.
# No tocamos ninguna de las llamadas a las graficas existentes.
$offset = 0
if ($null -ne $ast.ParamBlock) { $offset = $ast.ParamBlock.Extent.EndOffset }

$eol = "`r`n"
if ($original.Contains("`n") -and -not $original.Contains("`r`n")) { $eol = "`n" }
$addition = $eol + $marker + $eol +
    '& (Join-Path $PSScriptRoot "O3_generar_ambas_termalizaciones.ps1")' + $eol +
    '# FIN_O3_AUTO_TERMALIZACIONES_AMBAS_v1' + $eol
$nuevo = $original.Insert($offset, $addition)

$t2 = $null
$e2 = $null
[System.Management.Automation.Language.Parser]::ParseInput(
    $nuevo, [ref]$t2, [ref]$e2
) | Out-Null
if ($e2.Count -gt 0) {
    throw 'La modificacion no ha superado la comprobacion de sintaxis. No se cambia el original.'
}

$backup = "$target.bak_antes_termalizaciones"
if (Test-Path -LiteralPath $backup) {
    throw "Ya existe una copia de seguridad $backup; guardala o renombrala antes de repetir el parche."
}
Copy-Item -LiteralPath $target -Destination $backup
try {
    # Respeta la codificacion previa y su BOM, si lo hubiera.
    $content = $encoding.GetBytes($nuevo)
    $result = New-Object byte[] ($bom.Length + $content.Length)
    [Array]::Copy($bom, 0, $result, 0, $bom.Length)
    [Array]::Copy($content, 0, $result, $bom.Length, $content.Length)
    [System.IO.File]::WriteAllBytes($target, $result)
    Write-Host '[OK] graficar_O3_todo_v12.ps1 actualizado.'
    Write-Host "[BACKUP] $backup"
    Write-Host 'Se generan ambas termalizaciones para N=4,8,16,32,64.'
    Write-Host 'El resto de graficas del auxiliar queda sin cambiar.'
}
catch {
    Copy-Item -LiteralPath $backup -Destination $target -Force
    throw
}
