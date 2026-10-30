# O2 - Diferencia de ocupaciones frente a fuerza
# m = P_R - P_L, comparable con tanh(F/kBT) en aproximacion de dos estados.

reset

metodo = "Verlet"
h = 0.001
A = 1.0
eta = 1.0
XC = 0.2
KBT = 0.2

array Fvals[13] = [-0.4,-0.3,-0.2,-0.15,-0.1,-0.05,0.0,0.05,0.1,0.15,0.2,0.3,0.4]

tmp = "tmp_ocupacion_vs_F.dat"
set print tmp

do for [i=1:13] {
    F = Fvals[i]
    archivo = sprintf("../../results/O2/%s/resumen_h%g_A%g_eta%g_F%g_XC%g.txt",metodo,h,A,eta,F,XC)
    stats archivo using 5 name "L" nooutput
    stats archivo using 6 name "R" nooutput
    if (L_records > 0 && R_records > 0) {
        print F, L_mean, R_mean, R_mean-L_mean
    }
}
set print

mteo(F) = tanh(F/KBT)

set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output sprintf("../../plots/O2/%s/Diferencia_ocupacion_vs_F_h%g_A%g_eta%g.png",metodo,h,A,eta)

set title "Respuesta de dos estados a una fuerza constante"
set xlabel "Fuerza externa, F"
set ylabel "P_R - P_L"
set xrange [-0.42:0.42]
set yrange [-1:1]
set grid
set key left top

plot tmp using 1:4 with points pt 7 ps 1.2 title "Simulacion", \
     mteo(x) with lines lw 2 dt 2 title "tanh(F/kBT), aprox."

unset output
