# O3 - Volumen excluido: Rg y Ree frente a N
# Ejecutar desde scriptsGnuplot/O3

reset

ideal="../../results/O3/excluded_ideal_sizes.dat"
wca="../../results/O3/excluded_WCA_sizes.dat"
salida="../../plots/O3/EV_Rg_Ree_vs_N.png"

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title "Efecto del volumen excluido WCA"

set title "Radio de giro"
set xlabel "N"
set ylabel "<R_g>"
set grid
set key top left
plot ideal using 1:3 with linespoints lw 2 pt 7 title "Ideal", \
     wca using 1:3 with linespoints lw 2 pt 5 title "WCA"

set title "Distancia extremo a extremo"
set xlabel "N"
set ylabel "<R_{ee}>"
set grid
set key top left
plot ideal using 1:2 with linespoints lw 2 pt 7 title "Ideal", \
     wca using 1:2 with linespoints lw 2 pt 5 title "WCA"

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
