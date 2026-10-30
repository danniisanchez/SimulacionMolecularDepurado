# O2 - Dependencia del tiempo medio de estancia con A
# Ejecutar desde scriptsGnuplot/O2

metodo = "Verlet"
h = 0.001
eta_fijo = 1.0
XC = 0.2

array Avals[9] = [0.5,0.7,0.9,1.0,1.1,1.2,1.4,1.6,2.0]

tmp = "tmp_tau_vs_A.dat"
set print tmp

do for [i=1:9] {
    Aval = Avals[i]
    archivo = sprintf("../../results/O2/%s/resumen_h%g_A%g_eta%g_XC%g.txt",metodo,h,Aval,eta_fijo,XC)
    stats archivo using 12 name "S" nooutput
    if (S_records > 0 && S_mean > 0) {
        print Aval, S_mean, log(S_mean)
    }
}
set print

m = 5.0
b = 1.0
f(x) = m*x + b
fit f(x) tmp using 1:3 via m,b

salida = sprintf("../../plots/O2/%s/Dependencia_tau_A_h%g_eta%g_XC%g.png",metodo,h,eta_fijo,XC)

set terminal pngcairo size 1000,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title sprintf("Dependencia con la barrera A: %s, h=%g, eta=%g",metodo,h,eta_fijo)

set grid
set key top left

set xlabel "A"
set ylabel "<tau> global"
set title "Tiempo medio de estancia frente a A"
plot tmp using 1:2 with linespoints lw 2 pt 7 title "<tau>(A)"

set xlabel "A"
set ylabel "ln <tau>"
set title sprintf("Escala semilogaritmica; ajuste: pendiente = %.3g",m)
plot tmp using 1:3 with points pt 7 ps 1.2 title "Datos", \
     f(x) with lines lw 2 title "Ajuste lineal"

unset multiplot
unset output

print sprintf("Pendiente de ln(tau) vs A = %g",m)
print sprintf("Figura guardada en: %s",salida)
