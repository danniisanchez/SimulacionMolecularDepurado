# O3 - Observables conformacionales frente a N
# Ejecutar desde scriptsGnuplot/O3
#
# resumen_tamanos.dat:
# 1 N, 6 Ree_mean, 8 Rg_mean
reset

archivo = "../../results/O3/resumen_tamanos.dat"
salida = "../../plots/O3/Ree_Rg_vs_N.png"

set terminal pngcairo size 1000,700 enhanced font "Arial,12"
set output salida

set title "Objetivo 3: tamano conformacional del polimero"
set xlabel "Numero de beads, N"
set ylabel "Longitud media"
set grid
set key top left

plot archivo using 1:6 with linespoints lw 2 pt 7 title "<R_{ee}>", \
     archivo using 1:8 with linespoints lw 2 pt 5 title "<R_g>"

unset output
