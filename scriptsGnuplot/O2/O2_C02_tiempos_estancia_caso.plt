
reset
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
xmin=(D_min<I_min)?D_min:I_min
xmax=(D_max>I_max)?D_max:I_max
nbins=int(sqrt(nD+nI)); if(nbins<8) nbins=8
bw=(xmax-xmin)/nbins; if(bw<=0) bw=1.0
bin(x,w)=w*floor(x/w)+w/2.0
PD(x)=(x>=0&&tauD>0)?exp(-x/tauD)/tauD:1/0
PI(x)=(x>=0&&tauI>0)?exp(-x/tauI)/tauI:1/0
set terminal pngcairo size 1250,600 enhanced font "Arial,12"
set output outfile
set multiplot layout 1,2 title sprintf("O2 - Tiempos de residencia; A=%g, eta=%g, F=%g",AVAL,ETAVAL,FVAL)
set xrange [0:*]; set logscale y; set grid
set style fill transparent solid 0.35 border
set boxwidth bw*0.82
set xlabel "Tiempo"; set ylabel "Densidad"
set title sprintf("Derecha: N=%d, <tau>=%.3g",nD,tauD)
plot rightfile using (bin($1,bw)):(1.0/(nD*bw)) smooth freq with boxes title "Datos", PD(x) w l lw 2 title "Exponencial"
set title sprintf("Izquierda: N=%d, <tau>=%.3g",nI,tauI)
plot leftfile using (bin($1,bw)):(1.0/(nI*bw)) smooth freq with boxes title "Datos", PI(x) w l lw 2 title "Exponencial"
unset multiplot; unset output
