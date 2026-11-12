reset
archivo="../../results/O2/analisis/trayectoria.dat"

stats archivo using 1 name "T" nooutput
stride=int(T_records/50000.0)+1
if(stride<1) stride=1

set border linewidth 1.3
set tics out
set grid back

set terminal pngcairo size 1500,700 enhanced font "Arial,14"
set output "../../plots/O2/Trayectorias/Referencia_x_completa.png"
set title "O2 - Posicion completa (caso de referencia)"
set xlabel "t"; set ylabel "x(t)"
set xrange [T_min:T_max]
plot archivo every stride u 1:2 w l lw 1 title "x(t)"
unset output

set output "../../plots/O2/Trayectorias/Referencia_v_completa.png"
set title "O2 - Velocidad completa (caso de referencia)"
set xlabel "t"; set ylabel "v(t)"
set xrange [T_min:T_max]
plot archivo every stride u 1:3 w l lw 1 title "v(t)"
unset output

set terminal pngcairo size 900,850 enhanced font "Arial,14"
set output "../../plots/O2/Trayectorias/Referencia_fase.png"
set title "O2 - Espacio de fases (caso de referencia)"
set xlabel "x"; set ylabel "v"
set size square
plot archivo every stride u 2:3 w p pt 7 ps 0.22 notitle
unset output
