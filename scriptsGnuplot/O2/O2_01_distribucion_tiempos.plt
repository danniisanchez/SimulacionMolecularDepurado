reset
der="../../results/O2/analisis/tiempos_derecha.dat"
izq="../../results/O2/analisis/tiempos_izquierda.dat"
salida="../../plots/O2/Distribucion_tiempos_referencia.png"

stats der using 1 name "D" nooutput
stats izq using 1 name "I" nooutput

tauD=D_mean; tauI=I_mean
nD=D_records; nI=I_records

# Regla sqrt(N), independiente para cada pozo.
# Evita tanto histogramas demasiado gruesos como 100 cajas casi vacias.
nbD=int(sqrt(nD)); if(nbD<8) nbD=8; if(nbD>60) nbD=60
nbI=int(sqrt(nI)); if(nbI<8) nbI=8; if(nbI>60) nbI=60

limD=(D_max<6*tauD)?D_max:6*tauD
bwD=limD/nbD; if(bwD<=0) bwD=1.0
limI=(I_max<6*tauI)?I_max:6*tauI
bwI=limI/nbI; if(bwI<=0) bwI=1.0
binD(x)=bwD*floor(x/bwD)+bwD/2.0
binI(x)=bwI*floor(x/bwI)+bwI/2.0

PD(x)=(x>=0&&tauD>0)?exp(-x/tauD)/tauD:1/0
PI(x)=(x>=0&&tauI>0)?exp(-x/tauI)/tauI:1/0

set terminal pngcairo size 1500,700 enhanced font "Arial,14"
set output salida
set multiplot layout 1,2 title "O2 - Distribucion de tiempos de residencia (referencia)"
set grid back
set border linewidth 1.3
set tics out
set xrange [0:*]
set logscale y
set xlabel "Tiempo de residencia"
set ylabel "Densidad"
set style fill transparent solid 0.35 border

set xrange [0:limD]
set boxwidth bwD*0.82
set title sprintf("Derecha: N=%d, bins=%d, <tau>=%.3g",nD,nbD,tauD)
plot der using (binD($1)):(1.0/(nD*bwD)) smooth freq with boxes title "Datos", \
     PD(x) w l lw 2 title "p(t)=exp(-t/<tau>)/<tau>"

set xrange [0:limI]
set boxwidth bwI*0.82
set title sprintf("Izquierda: N=%d, bins=%d, <tau>=%.3g",nI,nbI,tauI)
plot izq using (binI($1)):(1.0/(nI*bwI)) smooth freq with boxes title "Datos", \
     PI(x) w l lw 2 title "p(t)=exp(-t/<tau>)/<tau>"

unset logscale y
unset multiplot
unset output
