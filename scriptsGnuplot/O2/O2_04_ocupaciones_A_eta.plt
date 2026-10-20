# O2 - Ocupacion de los dos pozos
# Panel izquierdo: P_L y P_R frente a A con eta=1
# Panel derecho:   P_L y P_R frente a eta con A=1
# Ejecutar desde scriptsGnuplot/O2

metodo = "Verlet"
h = 0.001
XC = 0.2
eta_fijo = 1.0
A_fijo = 1.0

array Avals[9] = [0.5,0.7,0.9,1.0,1.1,1.2,1.4,1.6,2.0]
array etavals[9] = [0.01,0.03,0.1,0.3,0.5,1.0,2.0,3.0,5.0]

tmpA = "tmp_ocupacion_A.dat"
set print tmpA
do for [i=1:9] {
    Aval = Avals[i]
    archivo = sprintf("../../results/O2/%s/resumen_h%g_A%g_eta%g_XC%g.txt",metodo,h,Aval,eta_fijo,XC)
    stats archivo using 5 name "L" nooutput
    stats archivo using 6 name "R" nooutput
    if (L_records > 0) print Aval, L_mean, R_mean
}
set print

tmpEta = "tmp_ocupacion_eta.dat"
set print tmpEta
do for [i=1:9] {
    etaval = etavals[i]
    archivo = sprintf("../../results/O2/%s/resumen_h%g_A%g_eta%g_XC%g.txt",metodo,h,A_fijo,etaval,XC)
    stats archivo using 5 name "L" nooutput
    stats archivo using 6 name "R" nooutput
    if (L_records > 0) print etaval, L_mean, R_mean
}
set print

salida = sprintf("../../plots/O2/%s/Ocupaciones_h%g_XC%g.png",metodo,h,XC)

set terminal pngcairo size 1250,600 enhanced font "Arial,12"
set output salida
set multiplot layout 1,2 title sprintf("Ocupacion de los estados: %s, h=%g",metodo,h)
set grid
set yrange [0:1]
set ylabel "Ocupacion"
set key bottom right

set xlabel "A"
set title sprintf("Variacion con A (eta=%g)",eta_fijo)
plot 0.5 with lines dt 2 lw 1 title "P=0.5", \
     tmpA using 1:2 with linespoints lw 2 pt 7 title "P izquierda", \
     tmpA using 1:3 with linespoints lw 2 pt 5 title "P derecha"

set logscale x
set xlabel "eta"
set title sprintf("Variacion con eta (A=%g)",A_fijo)
plot 0.5 with lines dt 2 lw 1 title "P=0.5", \
     tmpEta using 1:2 with linespoints lw 2 pt 7 title "P izquierda", \
     tmpEta using 1:3 with linespoints lw 2 pt 5 title "P derecha"

unset logscale x
unset multiplot
unset output

print sprintf("Figura guardada en: %s",salida)
