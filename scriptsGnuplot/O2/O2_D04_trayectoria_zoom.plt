reset
archivo="../../results/O2/analisis/trayectoria_zoom.dat"

stats archivo using 1 name "T" nooutput
dt=(T_records>1)?(T_max-T_min)/(T_records-1):0
zoom_end=(T_min+50.0<T_max)?T_min+50.0:T_max

set terminal pngcairo size 1500,700 enhanced font "Arial,14"
set output "../../plots/O2/Trayectoria_zoom_referencia.png"
set border linewidth 1.3
set tics out
set grid back
set xrange [T_min:zoom_end]
set title sprintf("O2 - Detalle local de x(t); Delta t de salida ~= %.4g",dt)
set xlabel "t"
set ylabel "x(t)"
plot archivo u 1:2 w l lw 1.2 title "x(t)"
unset output
