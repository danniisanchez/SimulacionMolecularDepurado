reset
archivo="../../results/O2/analisis/trayectoria.dat"
# En vez de fijar un intervalo antiguo, muestra los primeros datos disponibles.
set terminal pngcairo size 1000,500 enhanced font "Arial,12"
set output "../../plots/O2/Trayectoria_zoom_referencia.png"
set title "O2 - Detalle de la trayectoria"
set xlabel "t"; set ylabel "x(t)"; set grid; set yrange [-1.6:1.6]
plot archivo every ::0::5000 u 1:2 w l lw 1.5 title "x(t)"
unset output
