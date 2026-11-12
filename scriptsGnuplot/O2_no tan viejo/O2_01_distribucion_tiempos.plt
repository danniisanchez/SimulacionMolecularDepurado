reset
der="../../results/O2/analisis/tiempos_derecha.dat"
izq="../../results/O2/analisis/tiempos_izquierda.dat"
salida="../../plots/O2/Distribucion_tiempos_referencia.png"

stats der using 1 name "D" nooutput
stats izq using 1 name "I" nooutput
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
set output salida
set multiplot layout 1,2 title "O2 - Distribucion de tiempos de residencia (caso de referencia)"
set grid; set xrange [0:*]; set logscale y
set xlabel "Tiempo de residencia"; set ylabel "Densidad"
set boxwidth bw*0.82; set style fill transparent solid 0.35 border
set title sprintf("Derecha: N=%d, <tau>=%.3g",nD,tauD)
plot der using (bin($1,bw)):(1.0/(nD*bw)) smooth freq with boxes title "Datos", PD(x) w l lw 2 title "Exponencial"
set title sprintf("Izquierda: N=%d, <tau>=%.3g",nI,tauI)
plot izq using (bin($1,bw)):(1.0/(nI*bw)) smooth freq with boxes title "Datos", PI(x) w l lw 2 title "Exponencial"
unset logscale y; unset multiplot; unset output
