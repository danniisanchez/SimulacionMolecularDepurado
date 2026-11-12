reset
if (!exists("VALID")) VALID=0
calidad=(VALID==1)?"VALIDADO":"NO VALIDADO"
if (!exists("rightfile")) rightfile="../../results/O2/analisis/tiempos_derecha.dat"
if (!exists("leftfile")) leftfile="../../results/O2/analisis/tiempos_izquierda.dat"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/tiempos/Tiempos_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0

stats rightfile using 1 name "D" nooutput
stats leftfile using 1 name "I" nooutput
tauD=D_mean; tauI=I_mean
nD=D_records; nI=I_records

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
set output outfile
set multiplot layout 1,2 title sprintf("O2 - Tiempos de residencia; A=%g, eta=%g, F=%g [%s]",AVAL,ETAVAL,FVAL,calidad)
set border linewidth 1.3
set tics out
set xrange [0:*]
set logscale y
set grid back
set style fill transparent solid 0.35 border
set xlabel "Tiempo"
set ylabel "Densidad"

set xrange [0:limD]
set boxwidth bwD*0.82
set title sprintf("Derecha: N=%d, bins=%d, <tau>=%.3g",nD,nbD,tauD)
plot rightfile using (binD($1)):(1.0/(nD*bwD)) smooth freq with boxes title "Datos", \
     PD(x) w l lw 2 title "Exponencial"

set xrange [0:limI]
set boxwidth bwI*0.82
set title sprintf("Izquierda: N=%d, bins=%d, <tau>=%.3g",nI,nbI,tauI)
plot leftfile using (binI($1)):(1.0/(nI*bwI)) smooth freq with boxes title "Datos", \
     PI(x) w l lw 2 title "Exponencial"

unset logscale y
unset multiplot
unset output
