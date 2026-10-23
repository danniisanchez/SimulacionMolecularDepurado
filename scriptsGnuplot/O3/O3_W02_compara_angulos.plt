# O3 - Comparacion armonico vs WLC: angulos

reset

N=64
harm=sprintf("../../results/O3/bending_armonico_N%d.dat",N)
wlc=sprintf("../../results/O3/bending_WLC_N%d.dat",N)
salida=sprintf("../../plots/O3/Comparacion_Harmonico_WLC_angulos_N%d.png",N)

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title sprintf("Estadistica angular: armonico vs WLC, N=%d",N)

set title "Angulo medio"
set xlabel "Rigidez K / k_BT  (k_BT=1)"
set ylabel "<theta> [rad]"
set grid
set key top right
plot harm using 1:6 with linespoints lw 2 pt 7 title "Armonico", \
     wlc using 1:6 with linespoints lw 2 pt 5 title "WLC"

set title "Correlacion de enlaces consecutivos"
set xlabel "Rigidez K / k_BT  (k_BT=1)"
set ylabel "<cos(theta)>"
set yrange [-1:1.05]
set grid
set key bottom right
plot harm using 1:7 with linespoints lw 2 pt 7 title "Armonico", \
     wlc using 1:7 with linespoints lw 2 pt 5 title "WLC", \
     1.0 with lines dt 2 lw 2 title "Cadena localmente recta"

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
