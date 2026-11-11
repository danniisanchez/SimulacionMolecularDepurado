reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Equiparticion_vs_N.png"
set terminal pngcairo size 1500,900 enhanced font "Arial,14"
set output salida
set border linewidth 1.3
set tics out
set grid back
set title "O3 - Equiparticion para todos los tamanos"
set xlabel "Numero de beads, N"
set ylabel "Energia medida / referencia"
set yrange [0.8:1.2]
set key top right
plot 1.0 w l lw 2 dt 2 title "Referencia", \
     archivo u 1:($2/$3) w p pt 7 ps 1.4 title "<E_k> / [3(N-1)k_BT/2]", \
     archivo u 1:($4/$5) w p pt 5 ps 1.4 title "<E_{bond}> / [(N-1)k_BT/2]"
unset output
