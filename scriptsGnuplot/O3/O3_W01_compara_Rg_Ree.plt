# O3 - Comparacion armonico vs WLC: Ree y Rg
# Ejecutar desde scriptsGnuplot/O3

reset

N=64
harm=sprintf("../../results/O3/bending_armonico_N%d.dat",N)
wlc=sprintf("../../results/O3/bending_WLC_N%d.dat",N)
salida=sprintf("../../plots/O3/Comparacion_Harmonico_WLC_Rg_Ree_N%d.png",N)

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title sprintf("Bending armonico vs WLC, N=%d",N)

set title "Distancia extremo a extremo"
set xlabel "Rigidez K / k_BT  (k_BT=1)"
set ylabel "<R_{ee}>"
set grid
set key top left
plot harm using 1:2 with linespoints lw 2 pt 7 title "Armonico", \
     wlc using 1:2 with linespoints lw 2 pt 5 title "WLC"

set title "Radio de giro"
set xlabel "Rigidez K / k_BT  (k_BT=1)"
set ylabel "<R_g>"
set grid
set key top left
plot harm using 1:3 with linespoints lw 2 pt 7 title "Armonico", \
     wlc using 1:3 with linespoints lw 2 pt 5 title "WLC"

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
