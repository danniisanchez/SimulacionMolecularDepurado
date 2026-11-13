# O3 - Energias acumuladas normalizadas con el MISMO denominador.
# Referencia: main.c (col 2 = <Ek>, col 3 = <Ebond>), head.h (KBT = 1).
# Ejecutar desde scriptsGnuplot/O3: gnuplot -e "N=32" O3_03_termalizacion_normalizada.plt
# XMAX=0 muestra el rango temporal completo. Por defecto, zoom [0:2000] para N=32,64.
reset
if (!exists("N")) N=4
if (!exists("KBT")) KBT=1.0
if (!exists("PLOT_SKIP")) PLOT_SKIP=5
if (PLOT_SKIP < 1) PLOT_SKIP=1
if (!exists("XMAX")) XMAX=(N == 32 || N == 64 ? 2000.0 : 0.0)
if (!exists("TERM_FILE")) TERM_FILE=sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
if (!exists("TERM_OUT")) TERM_OUT=sprintf("../../plots/O3/N%d/Termalizacion_N%d_normalizada.png",N,N)

# Se divide AMBAS energias por (N-1)*k_B*T.
# La primera particula esta fija: N-1 monomeros moviles y N-1 enlaces.
Escale=(N-1)*KBT
if (N <= 1 || KBT <= 0) print "ERROR: N>1 y KBT>0 requeridos"

set terminal pngcairo size 1880,970 enhanced font "Arial,17"
set output TERM_OUT
set title sprintf("O3 - Termalizacion: energias por monomero movil, N=%d",N) font ",21"
set xlabel "Tiempo de simulacion, t" font ",19"
set ylabel "Energia acumulada / [(N-1)k_{B}T]" font ",19"
set border 15 lw 1.6 lc rgb "#334155"
set tics out nomirror
set grid xtics ytics back lc rgb "#CDD6E1" lw 1 dt 3
set format x "%g"
set yrange [0:*]
if (XMAX > 0) set xrange [0:XMAX]
if (XMAX <= 0) set xrange [0:*]
set lmargin at screen 0.12
set rmargin at screen 0.73
set bmargin at screen 0.15
set tmargin at screen 0.88
set key outside right top vertical
set key box lw 1.2 lc rgb "#334155"
set key opaque
set key spacing 1.7 samplen 2.4 font ",15"
plot TERM_FILE every PLOT_SKIP using 1:($2/Escale) \
       with lines lw 2.5 lc rgb "#1675A9" title "<E_{k}>/[(N-1)k_{B}T]", \
     TERM_FILE every PLOT_SKIP using 1:($3/Escale) \
       with lines lw 2.5 lc rgb "#CE6A27" title "<E_{bond}>/[(N-1)k_{B}T]", \
     1.5 with lines dt 2 lw 1.8 lc rgb "#1675A9" title "Teoria E_{k}: 3/2", \
     0.5 with lines dt 2 lw 1.8 lc rgb "#CE6A27" title "Aprox. E_{bond}: 1/2"
unset output
print sprintf("Guardado: %s",TERM_OUT)
print "Son medias acumuladas. El equilibrio estructural requiere diagnosticos adicionales."
