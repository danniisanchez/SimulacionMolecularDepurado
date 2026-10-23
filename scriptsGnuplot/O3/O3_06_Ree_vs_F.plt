# ============================================================
# O3 - Ree_parallel frente a fuerza externa
# Comparacion con la funcion de Langevin
#
# Ejecutar desde:
#   scriptsGnuplot/O3
#
# Datos esperados:
#   ../../results/O3/ree_vs_fuerza_N64.dat
#
# Columnas:
# 1 F_ext
# 2 <Ree_parallel>
# 3 <|Ree|>
# 4 <longitud_enlace>
# 5 muestras
# ============================================================

reset

N = 64
b0 = 1.0
KBT = 1.0

archivo = sprintf("../../results/O3/ree_vs_fuerza_N%d.dat",N)
salida  = sprintf("../../plots/O3/Ree_vs_F_N%d.png",N)

Lcont = (N-1)*b0

langevin(z) = (abs(z) < 1.0e-8) ? z/3.0 : 1.0/tanh(z) - 1.0/z
Ree_FJC(F) = Lcont * langevin(F*b0/KBT)

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida

set multiplot layout 2,1 title sprintf("Extension del polimero frente a fuerza externa, N=%d",N)

set title "Rango completo de fuerza"
set xlabel "Fuerza externa F"
set ylabel "<R_{ee,parallel}>"
set grid
set key bottom right

plot archivo using 1:2 with linespoints lw 2 pt 7 ps 1.0 title "Simulacion", \
     Ree_FJC(x) with lines lw 2 dt 2 title "FJC ideal: (N-1)b L(Fb/kBT)", \
     Lcont with lines dt 3 lw 2 title "(N-1)b"

set title "Regimen debil e intermedio"
set xrange [0:100]
set xlabel "Fuerza externa F"
set ylabel "<R_{ee,parallel}> / [(N-1)b]"
set yrange [0:1.2]
set grid
set key bottom right

plot archivo using 1:($2/Lcont) with linespoints lw 2 pt 7 ps 1.0 title "Simulacion", \
     langevin(x*b0/KBT) with lines lw 2 dt 2 title "Funcion de Langevin"

unset multiplot
unset output

print sprintf("Figura guardada en: %s",salida)
