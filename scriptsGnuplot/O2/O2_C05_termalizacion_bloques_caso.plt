reset
if (!exists("VALID")) VALID=0
calidad=(VALID==1)?"VALIDADO":"NO VALIDADO"
if (!exists("datafile")) datafile="../../results/O2/Verlet/termalizacion_bloques.txt"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/termalizacion/Termalizacion_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0
if (!exists("KBT")) KBT=0.2

set terminal pngcairo size 1450,950 enhanced font "Arial,14"
set output outfile
set multiplot layout 2,1 title sprintf("O2 - Diagnostico de termalizacion; A=%g, eta=%g, F=%g [%s]",AVAL,ETAVAL,FVAL,calidad)
set border linewidth 1.3
set tics out
set grid back

set xlabel "Tiempo"
set ylabel "Energia por bloque"
set title "Equilibrio local: medias por bloque"
plot datafile using 3:4 with linespoints pt 7 ps 0.45 title "<E_k> bloque", \
     datafile using 3:5 with linespoints pt 7 ps 0.45 title "<V> bloque", \
     0.5*KBT with lines dt 2 lw 2 title "k_BT/2"

set xlabel "Tiempo"
set ylabel "P(izquierda)"
set yrange [0:1]
set title "Mezcla global: ocupacion acumulada"
plot datafile using 3:11 with linespoints pt 7 ps 0.45 title "P_izq simulada", \
     datafile using 3:12 with lines lw 2 dt 2 title "P_izq Boltzmann"

unset multiplot
unset output
