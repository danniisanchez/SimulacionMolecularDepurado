reset
if (!exists("datafile")) datafile="../../results/O2/Verlet/termalizacion_bloques.txt"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/termalizacion/Termalizacion_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0
if (!exists("KBT")) KBT=0.2

set terminal pngcairo size 1200,850 enhanced font "Arial,11"
set output outfile
set multiplot layout 2,1 title sprintf("O2 - Diagnostico de termalizacion; A=%g, eta=%g, F=%g",AVAL,ETAVAL,FVAL)

set grid
set xlabel "Tiempo"
set ylabel "Energia por bloque"
set title "Equilibrio local: medias por bloque"
plot datafile using 3:4 with linespoints pt 7 ps 0.45 title "<Ek> bloque", \
     datafile using 3:5 with linespoints pt 7 ps 0.45 title "<V> bloque", \
     0.5*KBT with lines dt 2 lw 2 title "kBT/2"

set xlabel "Tiempo"
set ylabel "P(izquierda)"
set yrange [0:1]
set title "Mezcla global: ocupacion acumulada desde TERM_MIX_START"
plot datafile using 3:11 with linespoints pt 7 ps 0.45 title "Pizq simulada", \
     datafile using 3:12 with lines lw 2 dt 2 title "Pizq Boltzmann"

unset multiplot
unset output
