# O2 - Distribucion de tiempos de estancia (una simulacion)
# Ejecutar desde scriptsGnuplot/O2

metodo = "Verlet"
h = 0.001
A = 1.0
eta = 3.0
XC = 0.2

f_der = sprintf("../../results/O2/%s/tiempos_derecha_h%g_A%g_eta%g_XC%g.txt",metodo,h,A,eta,XC)
f_izq = sprintf("../../results/O2/%s/tiempos_izquierda_h%g_A%g_eta%g_XC%g.txt",metodo,h,A,eta,XC)
salida = sprintf("../../plots/O2/%s/DistribucionClara_h%g_A%g_eta%g_XC%g.png",metodo,h,A,eta,XC)

stats f_der using 1 name "DER" nooutput
stats f_izq using 1 name "IZQ" nooutput

tau_der = DER_mean
tau_izq = IZQ_mean
n_der = DER_records
n_izq = IZQ_records

xmin = (DER_min < IZQ_min) ? DER_min : IZQ_min
xmax = (DER_max > IZQ_max) ? DER_max : IZQ_max
nbins = int(sqrt(n_der + n_izq))
if (nbins < 8) nbins = 8
binwidth = (xmax - xmin)/nbins
if (binwidth <= 0) binwidth = 1.0

bin(x,w) = w*floor(x/w) + w/2.0
Pder(x) = (x >= 0 && tau_der > 0) ? exp(-x/tau_der)/tau_der : 1/0
Pizq(x) = (x >= 0 && tau_izq > 0) ? exp(-x/tau_izq)/tau_izq : 1/0

set terminal pngcairo size 1250,600 enhanced font "Arial,12"
set output salida
set multiplot layout 1,2 title sprintf("Tiempos de estancia: %s, h=%g, A=%g, eta=%g, XC=%g",metodo,h,A,eta,XC)
set grid
set xrange [0:*]
set xlabel "Tiempo de estancia, tau"
set ylabel "Densidad de probabilidad"
set boxwidth binwidth*0.82
set style fill transparent solid 0.35 border
set key top right
set logscale y

set title sprintf("Pozo derecho: N=%d, <tau>=%.3g",n_der,tau_der)
plot f_der using (bin($1,binwidth)):(1.0/(n_der*binwidth)) smooth freq with boxes title "Datos", \
     Pder(x) with lines lw 2 title "Exponencial"

set title sprintf("Pozo izquierdo: N=%d, <tau>=%.3g",n_izq,tau_izq)
plot f_izq using (bin($1,binwidth)):(1.0/(n_izq*binwidth)) smooth freq with boxes title "Datos", \
     Pizq(x) with lines lw 2 title "Exponencial"

unset logscale y
unset multiplot
unset output

print sprintf("Figura guardada en: %s",salida)
