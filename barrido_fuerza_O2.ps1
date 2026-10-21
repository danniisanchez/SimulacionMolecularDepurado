# Barrido automatico de fuerza externa para Objetivo 2
# Ejecutar desde la raiz del repositorio.
# Requiere gcc en PATH y los archivos src/main.c, src/funciones.c, src/random.c, src/head.h.

$forces = @(-0.4, -0.3, -0.2, -0.15, -0.1, -0.05, 0.0, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4)

$headPath = "src/head.h"
$original = Get-Content $headPath -Raw

try {
    foreach ($F in $forces) {
        Write-Host "========================================"
        Write-Host "Simulando FEXT = $F"
        Write-Host "========================================"

        $nuevo = $original -replace '#define\s+FEXT\s+[-+0-9.eE]+', "#define FEXT $F"
        Set-Content -Path $headPath -Value $nuevo -Encoding UTF8

        gcc src/main.c src/funciones.c src/random.c -O2 -lm -o main.exe
        if ($LASTEXITCODE -ne 0) {
            throw "Error compilando para FEXT=$F"
        }

        .\main.exe
        if ($LASTEXITCODE -ne 0) {
            throw "Error ejecutando para FEXT=$F"
        }
    }
}
finally {
    # Restaurar head.h aunque haya un error a mitad del barrido
    Set-Content -Path $headPath -Value $original -Encoding UTF8
}

Write-Host "Barrido de fuerza terminado."
