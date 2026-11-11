# ============================================================
# O3 - Ree_parallel(F) con eje logaritmico en fuerza
# Excluye F=0 automaticamente porque log(0) no existe.
# Muy util para el barrido amplio.
# ============================================================

reset

N = 64
b0 = 1.0
KBT = 1.0

archivo = sprintf("../../results/O3/ree_vs_fuerza_N%d.dat",N)
salida  = sprintf("../../plots/O3/Ree_vs_F_log_N%d.png",N)

Lcont = (N-1)*b0
langevin(z) = (abs(z) < 1.0e-8) ? z/3.0 : 1.0/tanh(z) - 1.0/z

set terminal pngcairo size 1000,700 enhanced font "Arial,12"
set output salida

set title sprintf("Extension frente a fuerza - barrido logaritmico, N=%d",N)
set xlabel "Fuerza externa F"
set ylabel "<R_{ee,parallel}>"
set logscale x
set xrange [0.001:1250]
set grid
set key top left

plot archivo using 1:2 with linespoints lw 2 pt 7 ps 1.0 title "Simulacion", \
     Lcont*langevin(x*b0/KBT) with lines lw 2 dt 2 title "FJC ideal"

unset output

print sprintf("Figura guardada en: %s",salida)
