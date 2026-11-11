# O3 - Equiparticion para N=4,8,16,32,64
# Ejecutar desde scriptsGnuplot/O3
reset
archivo = "../../results/O3/resumen_tamanos.dat"
salida = "../../plots/O3/Equiparticion_vs_N.png"
set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output salida
set title "Objetivo 3: comprobacion de equiparticion"
set xlabel "Numero de beads, N"
set ylabel "Energia medida / referencia"
set xrange [2:70]
set yrange [0.7:1.3]
set grid
set key top right
plot 1.0 with lines dt 2 lw 2 title "Equiparticion", \
     archivo using 1:($2/$3) with linespoints lw 2 pt 7 title "<Ek> / (3NkBT/2)", \
     archivo using 1:($4/$5) with linespoints lw 2 pt 5 title "<Ep> / ((N-1)kBT/2)"
unset output
