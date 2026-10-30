
reset
if (!exists("datafile")) datafile="../../results/O2/analisis/energia.dat"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/energia/Energia_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0
if (!exists("KBT")) KBT=0.2
set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output outfile
set title sprintf("O2 - Medias acumuladas de energia; A=%g, eta=%g, F=%g",AVAL,ETAVAL,FVAL)
set xlabel "Tiempo"; set ylabel "Energia"
set grid; set key top right
plot 0.5*KBT w l dt 2 lw 2 title "<Ek> teorico", \
     datafile u 1:2 w l lw 2 title "<Ek>", \
     datafile u 1:3 w l lw 2 title "<V>", \
     datafile u 1:4 w l lw 1 title "E total"
unset output
