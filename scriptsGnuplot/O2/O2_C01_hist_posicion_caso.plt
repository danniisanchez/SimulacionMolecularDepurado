reset
if (!exists("VALID")) VALID=0
calidad=(VALID==1)?"VALIDADO":"NO VALIDADO"
if (!exists("datafile")) datafile="../../results/O2/analisis/histograma.dat"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/hist_posicion/Px_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0
if (!exists("KBT")) KBT=0.2

V(x)=AVAL*(x*x-1.0)**2-FVAL*x
dxI=0.001
Z=sum [i=-3000:3000] exp(-V(i*dxI)/KBT)*dxI
C=1.0/Z
Px(x)=C*exp(-V(x)/KBT)

stats datafile using 1 name "X" nooutput
nbins=X_records
bw=(X_max-X_min)/(nbins-1)

set terminal pngcairo size 1400,850 enhanced font "Arial,14"
set output outfile
set title sprintf("O2 - P(x); A=%g, eta=%g, F=%g | bins=%d, Delta x=%.4g [%s]",AVAL,ETAVAL,FVAL,nbins,bw,calidad)
set xlabel "x"
set ylabel "P(x)"
set xrange [-1.8:1.8]
set yrange [0:*]
set grid back
set border linewidth 1.3
set tics out
set key top left
set style fill solid 0.40 border -1

# Para F=0 los minimos estan exactamente en x=+-1.
# Para F!=0 la propia curva Boltzmann incorpora el desplazamiento debido a -F x.
if (abs(FVAL)<1e-12) {
    set arrow 1 from first -1.0, graph 0 to first -1.0, graph 1 nohead dt 2 lw 1
    set arrow 2 from first  1.0, graph 0 to first  1.0, graph 1 nohead dt 2 lw 1
    set label 1 "x=-1" at first -1.0, graph 0.94 center
    set label 2 "x=+1" at first  1.0, graph 0.94 center
}

plot datafile using 1:2:(bw) with boxes title "Histograma simulacion", \
     Px(x) with lines lw 2 title "Boltzmann normalizada"

unset output
