# O3 - Volumen excluido: Rg y Ree frente a N
# excluded_*_sizes.dat:
# 1 N, 2 Ree, 3 Rg, 4 Rg2, 5 Ebond, 6 Eev, 7 dmin, 8 bond, 9 muestras
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
