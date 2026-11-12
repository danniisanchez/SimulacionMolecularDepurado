reset
archivo="../../results/O2/analisis/histograma.dat"
param="../../results/O2/analisis/parametros.dat"

stats param u 1 name "AA" nooutput
stats param u 3 name "FF" nooutput
A=AA_mean; F=FF_mean
KBT=0.2
M=1.0
pi=3.141592653589793

V(x)=A*(x*x-1.0)**2-F*x
dxI=0.001
Z=sum [i=-3000:3000] exp(-V(i*dxI)/KBT)*dxI
C=1.0/Z
Px(x)=C*exp(-V(x)/KBT)
Pv(v)=sqrt(M/(2*pi*KBT))*exp(-0.5*M*v*v/KBT)

stats archivo u 1 name "X" nooutput
nbx=X_records
bwx=(X_max-X_min)/(nbx-1)
stats archivo u 3 name "Vv" nooutput
nbv=Vv_records
bwv=(Vv_max-Vv_min)/(nbv-1)

set terminal pngcairo size 1500,700 enhanced font "Arial,14"
set output "../../plots/O2/Histogramas_referencia.png"
set multiplot layout 1,2 title sprintf("O2 - Distribuciones de equilibrio; A=%.3g, F=%.3g",A,F)
set border linewidth 1.3
set tics out
set style fill solid 0.40 border -1
set grid back

set title sprintf("Posicion: bins=%d, Delta x=%.4g",nbx,bwx)
set xlabel "x"; set ylabel "P(x)"
plot archivo u 1:2:(bwx) w boxes title "Simulacion", \
     Px(x) w l lw 2 title "Boltzmann"

set title sprintf("Velocidad: bins=%d, Delta v=%.4g",nbv,bwv)
set xlabel "v"; set ylabel "P(v)"
plot archivo u 3:4:(bwv) w boxes title "Simulacion", \
     Pv(x) w l lw 2 title "Maxwell-Boltzmann"

unset multiplot
unset output
