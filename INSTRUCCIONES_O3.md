# O3: tres mejoras - noviembre 2026

## Entrega

- `srcO3_tamanos_libre/`: **copia independiente** del nucleo de tamanos; el principal `srcO3/` y el barrido de fuerzas no se tocan.
  - `main.c`: admite N=4,6,8,12,16,24,32,40,48,56,64 y usa `Ek_teo=1.5*N*KBT`.
  - `funciones.c`: integra tambien el monomero 0 (parte de la version `funciones(2).c` facilitada por el usuario).
  - `head.h`: fija `F_ext=0` solo para la copia de tamanos.
- `barrido_tamanos_O3_v12.ps1`: genera/reconstruye los 11 tamanos. Crea copia de seguridad antes de sobrescribir casos que realmente ejecuta.
- `scriptsGnuplot/O3/`: cinco scripts retocados: equiparticion, Ree/Rg, ley de escala y las dos termalizaciones.
- `O3_generar_ambas_termalizaciones.ps1`: auxiliar con los 11 tamaños.

## IMPORTANTE: integridad cientifica

El nucleo original recibido tenia `F_ext=0.1`, anclaba el monomero 0, y usaba `Ek_teo=1.5*(N-1)*KBT`. La copia para tamaños libres corrige los tres puntos, **sin cambiar el nucleo de fuerza**.

Los resultados previos de N=4,8,16,32,64 **solo pueden reutilizarse en el ajuste si se generaron con F=0 y sin anclaje** y son compatibles con el mismo KE, KBT, B0, etc. Si no puedes acreditarlo, repite tambien esos cinco tamaños. Los `.dat` se guardan en las rutas historicas porque asi lo requiere `main.c`, y el script genera respaldos antes de cada nueva ejecución.

La normalizacion energética para cadena libre se realiza respecto a referencias distintas:
`Ek/(1.5*N*KBT)` y `Ebond/(0.5*(N-1)*KBT)`. Ambas deberian tender aproximadamente a 1 (la segunda es aproximada). La grafica sin normalizar conserva las diferencias energeticas. La grafica de equiparticion usa las columnas 3 y 5 del resumen, generadas por el nucleo correspondiente; si los datos antiguos tienen referencia N-1, aparecera una comparacion inconsistente.

La ley de escala se ajusta con **exponente fijo 1/2** (dos parametros C y B para cada observable). Salidas: `Ley_escala_NmenosB.png` y `Ley_escala_NmenosB_loglog.png`; resultado numérico `results/O3/ajuste_nu_NmenosB.txt`. La ley teorica FJC supone enlaces de longitud b=1; no debe tomarse como exacta para muelles extensibles y/o interacciones adicionales.

## Instalacion

Copia las carpetas y archivos en la raiz de `SimulacionMolecularDepurado`, haciendo previamente copia de seguridad del `barrido_tamanos_O3_v12.ps1` y de los scripts Gnuplot sustituidos. **No copies estos `main.c`, `funciones.c` ni `head.h` a `srcO3/`**, sino a `srcO3_tamanos_libre/`.

El script requiere el fichero que ya tienes `srcO3/random.c`, GCC y Gnuplot. Los scripts Gnuplot existentes de fuerza permanecen intactos.

## Comandos

En PowerShell, situado en la raíz del proyecto:

```powershell
# Solo calcular los seis N nuevos (y reconstruir/representar los 11).
.\barrido_tamanos_O3_v12.ps1 -SoloNuevos

# Para repetir todos los N en las condiciones fisicas corregidas:
.\barrido_tamanos_O3_v12.ps1

# Si los anteriores son fiables y quieres reutilizarlos:
.\barrido_tamanos_O3_v12.ps1 -ReusarExistentes

# Regenerar el resumen de tamanos desde sus once resumenes individuales:
.\barrido_tamanos_O3_v12.ps1 -SoloReconstruir

# Graficas a partir de datos existentes, sin simular:
.\barrido_tamanos_O3_v12.ps1 -SoloGraficas

# Solo las dos termalizaciones (omite N sin .dat):
.\O3_generar_ambas_termalizaciones.ps1
```

Tu `O3_master_unificado_v12.ps1 -Modo tamanos` invoca este auxiliar y puede seguir utilizandose. Si `graficar_O3_todo_v12.ps1` llama al auxiliar de ambas termalizaciones, generara todos los tamaños con esta version. No hemos podido inspeccionar ese maestro de graficas, por lo que no aseguramos ni cambiamos su otra logica.

## Diagnostico de la cinetica algo elevada

En el regimen libre y termostatado: `<Ek> = 3 N KBT / 2` en equilibrio canónico clásico. Una ligera diferencia persistente puede deberse a incertidumbre estadística de medias correlacionadas, la inclusión del transitorio en la media acumulada, el estimador de velocidad discreta del esquema GJF, o una configuración distinta de F/anclaje/N. Para el oscilador armonico, el sesgo cinetico conocido de la velocidad on-site GJF es a menudo negativo, por lo que no explica automaticamente un exceso positivo. **No hemos realizado pruebas numéricas** y no hay evidencia suficiente para atribuir una desviacion positiva a una sola causa. Para separarlas: contrastar medias por bloques despues del transitorio, varias semillas y dependencia con H, registrando incertidumbres.

## Estilo y accesibilidad

Energías/observables con paleta Okabe-Ito: azul `#0072B2`, bermellón `#D55E00`, verde `#009E73`, violeta `#CC79A7`; tamaños de puntos mayores y símbolos diferentes (circulo y rombo), referencias con trazos discontinuos, tipografia de ejes aumentada y `pngcairo enhanced`.

## Alcance de validacion

Se ha comparado el contenido con los archivos adjuntados, pero no se han ejecutado simulaciones, pruebas C ni Gnuplot. Verifica las salidas en tu Windows antes de incorporarlas al informe.
