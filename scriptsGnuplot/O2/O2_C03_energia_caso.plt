reset
if (!exists("VALID")) VALID=0
calidad=(VALID==1)?"VALIDADO":"NO VALIDADO"
if (!exists("datafile")) datafile="../../results/O2/analisis/energia.dat"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/energia/Energia_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0
if (!exists("KBT")) KBT=0.2

set terminal pngcairo size 1400,800 enhanced font "Arial,14"
set output outfile
set title sprintf("O2 - Medias acumuladas de energia; A=%g, eta=%g, F=%g [%s]",AVAL,ETAVAL,FVAL,calidad)
set xlabel "Tiempo"
set ylabel "Energia"
set border linewidth 1.3
set tics out
set grid back
set key top right

plot 0.5*KBT w l dt 2 lw 2 title "<E_k> teorico = k_BT/2", \
     datafile u 1:2 w l lw 1.8 title "<E_k>", \
     datafile u 1:3 w l lw 1.8 title "<V>", \
     datafile u 1:4 w l lw 1.2 title "E total"

unset output
