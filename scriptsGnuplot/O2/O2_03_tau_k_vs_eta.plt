# O2 - Dependencia del tiempo medio y tasa de escape con eta
# Usa los ficheros resumen generados por main.c
# Ejecutar desde scriptsGnuplot/O2

metodo = "Verlet"
h = 0.001
A_fijo = 1.0
XC = 0.2

array etavals[9] = [0.01,0.03,0.1,0.3,0.5,1.0,2.0,3.0,5.0]

tmp = "tmp_tau_vs_eta.dat"
set print tmp

do for [i=1:9] {
    etaval = etavals[i]
    archivo = sprintf("../../results/O2/%s/resumen_h%g_A%g_eta%g_XC%g.txt",metodo,h,A_fijo,etaval,XC)
    stats archivo using 12 name "T" nooutput
    stats archivo using 13 name "K" nooutput
    if (T_records > 0 && T_mean > 0) print etaval, T_mean, K_mean
}
set print

salida = sprintf("../../plots/O2/%s/Dependencia_tau_eta_h%g_A%g_XC%g.png",metodo,h,A_fijo,XC)

set terminal pngcairo size 1000,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title sprintf("Dependencia con el damping: %s, h=%g, A=%g",metodo,h,A_fijo)
set grid
set logscale x
set key top right

set xlabel "eta"
set ylabel "<tau> global"
set title "Tiempo medio de estancia frente al damping"
plot tmp using 1:2 with linespoints lw 2 pt 7 title "<tau>(eta)"

set xlabel "eta"
set ylabel "k_sim = 1/<tau>"
set title "Tasa de escape frente al damping"
plot tmp using 1:3 with linespoints lw 2 pt 7 title "k(eta)"

unset logscale x
unset multiplot
unset output

print sprintf("Figura guardada en: %s",salida)
