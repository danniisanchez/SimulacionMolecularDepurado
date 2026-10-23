# O3 - Bending armónico: Ree y Rg frente a KBEND
# Ejecutar desde scriptsGnuplot/O3

reset

N=64
archivo=sprintf("../../results/O3/bending_armonico_N%d.dat",N)
salida=sprintf("../../plots/O3/Bending_Rg_Ree_N%d.png",N)

set terminal pngcairo size 1000,700 enhanced font "Arial,12"
set output salida

set title sprintf("Efecto del bending armonico, N=%d",N)
set xlabel "K_{bend} / k_BT  (k_BT=1)"
set ylabel "Longitud"
set grid
set key top left

plot archivo using 1:2 with linespoints lw 2 pt 7 title "<R_{ee}>", \
     archivo using 1:3 with linespoints lw 2 pt 5 title "<R_g>"

unset output
print sprintf("Figura guardada en: %s",salida)
