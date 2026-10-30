# O2 - Tiempos de estancia frente a fuerza externa
# Muestra como la fuerza favorece un pozo y dificulta escapar de el.

reset

metodo = "Verlet"
h = 0.001
A = 1.0
eta = 1.0
XC = 0.2
KBT = 0.2

array Fvals[13] = [-0.4,-0.3,-0.2,-0.15,-0.1,-0.05,0.0,0.05,0.1,0.15,0.2,0.3,0.4]

tmp = "tmp_tau_vs_F.dat"
set print tmp

do for [i=1:13] {
    F = Fvals[i]
    archivo = sprintf("../../results/O2/%s/resumen_h%g_A%g_eta%g_F%g_XC%g.txt",metodo,h,A,eta,F,XC)
    stats archivo using 10 name "TL" nooutput
    stats archivo using 11 name "TR" nooutput
    if (TL_records > 0 && TR_records > 0 && TL_mean > 0 && TR_mean > 0) {
        print F, TL_mean, TR_mean, log(TR_mean/TL_mean)
    }
}
set print

# En la aproximacion de dos estados:
# tau_R/tau_L ~ exp(2F/kBT)  => ln(tau_R/tau_L) ~ 2F/kBT
g(F) = 2.0*F/KBT

salida = sprintf("../../plots/O2/%s/Tiempos_vs_F_h%g_A%g_eta%g.png",metodo,h,A,eta)

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title sprintf("Respuesta dinamica a la fuerza: %s, h=%g, A=%g, eta=%g",metodo,h,A,eta)

set grid
set key top left
set xlabel "Fuerza externa, F"
set ylabel "Tiempo medio de estancia"
set logscale y
set title "Tiempos medios de residencia"
plot tmp using 1:2 with linespoints lw 2 pt 7 title "<tau> izquierda", \
     tmp using 1:3 with linespoints lw 2 pt 5 title "<tau> derecha"

unset logscale y
set xlabel "Fuerza externa, F"
set ylabel "ln(<tau_R>/<tau_L>)"
set title "Asimetria de los tiempos de residencia"
plot tmp using 1:4 with points pt 7 ps 1.2 title "Simulacion", \
     g(x) with lines lw 2 dt 2 title "2F/kBT (aprox.)"

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
