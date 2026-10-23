# O3 - Bending armónico: observables angulares frente a KBEND

reset

N=64
archivo=sprintf("../../results/O3/bending_armonico_N%d.dat",N)
salida=sprintf("../../plots/O3/Bending_angulos_N%d.png",N)

set terminal pngcairo size 1000,820 enhanced font "Arial,12"
set output salida

set multiplot layout 2,1 title sprintf("Rigidez angular del polimero, N=%d",N)

set title "Angulo medio"
set xlabel "K_{bend} / k_BT  (k_BT=1)"
set ylabel "<theta> [rad]"
set grid
set key off
plot archivo using 1:6 with linespoints lw 2 pt 7

set title "Correlacion entre enlaces consecutivos"
set xlabel "K_{bend} / k_BT  (k_BT=1)"
set ylabel "<cos(theta)>"
set yrange [-1:1.05]
set grid
set key off
plot archivo using 1:7 with linespoints lw 2 pt 7, \
     1.0 with lines dt 2 lw 2

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
