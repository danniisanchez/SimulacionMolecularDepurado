# O3 - Solo termalizacion energetica normalizada (medias ACUMULADAS).
# Conserva rutas y archivo PNG del O3. No requiere cambios en main.c.
# Ejecutar desde scriptsGnuplot/O3; el maestro pasa N si corresponde.
# Ejemplo manual: gnuplot -e "N=16" O3_03_termalizacion_N_v11.plt
# Si la termalizacion viene de un barrido con fuerza, pasar TERM_FILE y TERM_OUT
# para mantener separado el PNG del caso sin fuerza.
reset
if (!exists("N")) N=4
if (!exists("TERM_FILE")) TERM_FILE=sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
if (!exists("TERM_OUT")) TERM_OUT=sprintf("../../plots/O3/N%d/Termalizacion_N%d.png",N,N)
if (!exists("TERM_TAG")) TERM_TAG=""
if (!exists("PLOT_SKIP")) PLOT_SKIP=5
if (PLOT_SKIP < 1) PLOT_SKIP=1

# N monomeros, primero inmovil: N-1 monomeros moviles y N-1 enlaces.
KBT=1.0
EbondRef=0.5*(N-1)*KBT

# Formato del archivo del core:
# 1=t, 2=<Ek>_acumulada, 3=<Ebond>_acumulada, 6=Ek_teorica.
# Usar la columna 6 evita diferencias con el valor teórico almacenado.
# No se ejecuta `stats`: un fichero vacio o una cabecera distinta ya no
# provocan variables TT_* indefinidas. Si la ruta es incorrecta, Gnuplot
# aun avisara; verificar que se ejecuta desde scriptsGnuplot/O3.
set terminal pngcairo size 1880,970 enhanced font "Arial,17"
set output TERM_OUT
set title sprintf("O3 - Termalizacion energetica normalizada, N=%d",N) font ",21"
set xlabel "Tiempo de simulacion, t" font ",19"
set ylabel "Media acumulada / referencia teorica" font ",19"
set border 15 lw 1.6 lc rgb "#334155"
set tics out nomirror
set grid xtics ytics back lc rgb "#CDD6E1" lw 1 dt 3
set format x "%.3g"
set lmargin at screen 0.11
set rmargin at screen 0.72
set bmargin at screen 0.15
set tmargin at screen 0.88
set key outside right top vertical
set key box lw 1.2 lc rgb "#334155"
set key opaque
set key spacing 1.8 samplen 2.5 font ",15"
plot TERM_FILE every PLOT_SKIP using 1:($6>0 ? $2/$6 : 1/0) \
       with lines lw 2.5 lc rgb "#1675A9" title "<E_k> / [3(N-1)k_BT/2]", \
     TERM_FILE every PLOT_SKIP using 1:($3/EbondRef) \
       with lines lw 2.5 lc rgb "#CE6A27" title "<E_{bond}> / [(N-1)k_BT/2]", \
     1.0 with lines lw 2 dt 2 lc rgb "#334155" title "Referencia = 1"
unset output
print sprintf("O3 termalizacion energetica: %s", TERM_OUT)
print "Aviso: medias acumuladas; la estabilidad visual no prueba convergencia por bloques."
