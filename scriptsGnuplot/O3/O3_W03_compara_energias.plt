# O3 - Comparacion armonico vs WLC: energia de bending

reset

N=64
harm=sprintf("../../results/O3/bending_armonico_N%d.dat",N)
wlc=sprintf("../../results/O3/bending_WLC_N%d.dat",N)
salida=sprintf("../../plots/O3/Comparacion_Harmonico_WLC_energias_N%d.png",N)

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title sprintf("Energetica: armonico vs WLC, N=%d",N)

set title "Energia angular media"
set xlabel "Rigidez K / k_BT  (k_BT=1)"
set ylabel "<E_bend>"
set grid
set key top left
plot harm using 1:5 with linespoints lw 2 pt 7 title "Armonico", \
     wlc using 1:5 with linespoints lw 2 pt 5 title "WLC"

set title "Energia de estiramiento de enlaces"
set xlabel "Rigidez K / k_BT  (k_BT=1)"
set ylabel "<E_bond>"
set grid
set key top left
plot harm using 1:4 with linespoints lw 2 pt 7 title "Armonico", \
     wlc using 1:4 with linespoints lw 2 pt 5 title "WLC"

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
