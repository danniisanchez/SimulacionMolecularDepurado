# O3 - Energias acumuladas en unidades originales de la simulacion.
# Referencia: main.c (col 2 = <Ek>, col 3 = <Ebond>), head.h (KBT = 1).
# Ejecutar desde scriptsGnuplot/O3: gnuplot -e "N=32" O3_03_termalizacion_sin_normalizar.plt
# XMAX=0 muestra el rango temporal completo. Por defecto, zoom [0:2000] para N=32,64.
reset
if (!exists("N")) N=4
if (!exists("KBT")) KBT=1.0
if (!exists("PLOT_SKIP")) PLOT_SKIP=5
if (PLOT_SKIP < 1) PLOT_SKIP=1
if (!exists("XMAX")) XMAX=(N == 32 || N == 64 ? 2000.0 : 0.0)
if (!exists("TERM_FILE")) TERM_FILE=sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
if (!exists("TERM_OUT")) TERM_OUT=sprintf("../../plots/O3/N%d/Termalizacion_N%d_sin_normalizar.png",N,N)

# Valores absolutos almacenados en el .dat (sin dividir por N ni por k_B*T).
# Las referencias utilizan el numero N-1 de monomeros moviles/enlaces.
EkRef=1.5*(N-1)*KBT
EbondRef=0.5*(N-1)*KBT

set terminal pngcairo size 1880,970 enhanced font "Arial,17"
set output TERM_OUT
set title sprintf("O3 - Termalizacion: energias sin normalizar, N=%d",N) font ",21"
set xlabel "Tiempo de simulacion, t" font ",19"
set ylabel "Energia media acumulada (unidades de simulacion)" font ",19"
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
plot TERM_FILE every PLOT_SKIP using 1:2 \
       with lines lw 2.5 lc rgb "#1675A9" title "<E_{k}> (sin normalizar)", \
     TERM_FILE every PLOT_SKIP using 1:3 \
       with lines lw 2.5 lc rgb "#CE6A27" title "<E_{bond}> (sin normalizar)", \
     EkRef with lines dt 2 lw 1.8 lc rgb "#1675A9" title sprintf("Teoria E_{k} = %.4g",EkRef), \
     EbondRef with lines dt 2 lw 1.8 lc rgb "#CE6A27" title sprintf("Aprox. E_{bond} = %.4g",EbondRef)
unset output
print sprintf("Guardado: %s",TERM_OUT)
print "Son medias acumuladas. El potencial de fuerza externa no esta incluido en E_bond."
