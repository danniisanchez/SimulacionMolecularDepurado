# O3 - Cadena LIBRE sin fuerza: E_k usa N monomeros, E_bond usa N-1 enlaces.
# Columnas de termalizacion_N*.dat: 1=t, 2=<Ek> acumulada, 3=<Ebond> acumulada.
# Ejemplo: gnuplot -e "N=32;XMAX=2000" O3_03_termalizacion_normalizada.plt
reset
if (!exists("N")) N=4
if (!exists("KBT")) KBT=1.0
if (!exists("PLOT_SKIP")) PLOT_SKIP=5
if (!exists("MARK_SKIP")) MARK_SKIP=200
if (PLOT_SKIP<1) PLOT_SKIP=1
if (MARK_SKIP<1) MARK_SKIP=1
if (!exists("XMAX")) XMAX=(N>=24 ? 2000.0 : 0.0)
if (!exists("TERM_FILE")) TERM_FILE=sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
if (N<2 || KBT<=0) { print "ERROR: N>=2 y KBT>0 requeridos"; exit }
EkRef=1.5*N*KBT
EbondRef=0.5*(N-1)*KBT

# Comparacion directa en unidades de energia (sin normalizar).
if (!exists("TERM_OUT")) TERM_OUT=sprintf("../../plots/O3/N%d/Termalizacion_N%d_sin_normalizar.png",N,N)
set terminal pngcairo size 2250,1160 enhanced font "Arial,20"
set border 15 linewidth 1.8 linecolor rgb "#303B47"
set tics out nomirror font ",19" scale 1.2
set grid xtics ytics back linecolor rgb "#D4DDE5" linewidth 1 dashtype 3
set lmargin at screen 0.115
set rmargin at screen 0.710
set bmargin at screen 0.145
set tmargin at screen 0.895
set key outside right top vertical
set key box linewidth 1.3 linecolor rgb "#303B47"
set key opaque
set key spacing 1.7 samplen 2.5 font ",17"

set output TERM_OUT
set title sprintf("O3 - Termalizacion sin normalizar (cadena libre), N=%d",N) font ",27"
set xlabel "Tiempo de simulacion, t" font ",27"
set ylabel "Energia media acumulada" font ",25"
set format x "%g"
set yrange [0:*]
if (XMAX>0) set xrange [0:XMAX]
if (XMAX<=0) set xrange [0:*]
plot TERM_FILE every PLOT_SKIP using 1:2 \
       with lines lw 3.2 lc rgb "#0072B2" title "<E_{k}> medida", \
     TERM_FILE every PLOT_SKIP using 1:3 \
       with lines lw 3.2 lc rgb "#D55E00" title "<E_{bond}> medida", \
     EkRef with lines lw 2 dt 2 lc rgb "#0072B2" title "Teoria E_{k} = 3Nk_{B}T/2", \
     EbondRef with lines lw 2 dt 3 lc rgb "#D55E00" title "Aprox. E_{bond} = (N-1)k_{B}T/2", \
     TERM_FILE every MARK_SKIP using 1:2 \
       with points pt 7 ps 1.35 lc rgb "#0072B2" notitle, \
     TERM_FILE every MARK_SKIP using 1:3 \
       with points pt 5 ps 1.6 lc rgb "#D55E00" notitle
unset output
print sprintf("[O3] Sin normalizar: %s",TERM_OUT)
