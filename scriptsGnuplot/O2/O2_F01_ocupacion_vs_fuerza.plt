# O2 - Ocupacion frente a fuerza externa
# Requiere los resumen_*_F*.txt generados con main_O2_fuerza.c
# Ejecutar desde scriptsGnuplot/O2

reset

metodo = "Verlet"
h = 0.001
A = 1.0
eta = 1.0
XC = 0.2
KBT = 0.2

# Barrido recomendado: zona central densa y extremos hasta saturacion
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

# Aproximacion de dos estados localizada cerca de x=+-1:
# P_R/P_L ~ exp(2F/kBT)
PR_teo(F) = 1.0/(1.0 + exp(-2.0*F/KBT))
PL_teo(F) = 1.0 - PR_teo(F)

salida = sprintf("../../plots/O2/%s/Ocupacion_vs_F_h%g_A%g_eta%g.png",metodo,h,A,eta)

set terminal pngcairo size 1050,700 enhanced font "Arial,12"
set output salida
set title sprintf("Ocupacion frente a fuerza externa: %s, h=%g, A=%g, eta=%g",metodo,h,A,eta)
set xlabel "Fuerza externa, F"
set ylabel "Ocupacion"
set xrange [-0.42:0.42]
set yrange [0:1]
set grid
set key left top

plot tmp using 1:2 with points pt 7 ps 1.1 title "P izquierda (sim)", \
     tmp using 1:3 with points pt 5 ps 1.1 title "P derecha (sim)", \
     PL_teo(x) with lines lw 2 dt 2 title "P izquierda (2 estados)", \
     PR_teo(x) with lines lw 2 dt 2 title "P derecha (2 estados)"

unset output
print sprintf("Figura guardada en: %s",salida)
