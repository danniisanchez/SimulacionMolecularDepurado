reset
a="../../results/O2/resumen_A.dat"
e="../../results/O2/resumen_eta.dat"
salida="../../plots/O2/Ocupaciones_A_eta.png"
set terminal pngcairo size 1250,600 enhanced font "Arial,12"
set output salida
set multiplot layout 1,2 title "O2 - Ocupacion de los dos pozos"
set grid; set yrange [0:1]; set ylabel "Ocupacion"; set key bottom right
set xlabel "A"; set title "Variacion con A (eta=1, F=0)"
plot 0.5 w l dt 2 title "P=0.5", a u 1:2 w lp lw 2 pt 7 title "P izquierda", a u 1:3 w lp lw 2 pt 5 title "P derecha"
set logscale x; set xlabel "eta"; set title "Variacion con eta (A=1, F=0)"
plot 0.5 w l dt 2 title "P=0.5", e u 1:2 w lp lw 2 pt 7 title "P izquierda", e u 1:3 w lp lw 2 pt 5 title "P derecha"
unset logscale x; unset multiplot; unset output
