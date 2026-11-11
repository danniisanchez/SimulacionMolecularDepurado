# O3 - Representacion 3D de la configuracion final
reset
N = 4
archivo = sprintf("../../results/O3/N%d/snapshot_final_N%d.dat",N,N)
salida = sprintf("../../plots/O3/N%d/Polimero3D_N%d.png",N,N)
set terminal pngcairo size 850,750 enhanced font "Arial,12"
set output salida
set title sprintf("Configuracion final del polimero, N=%d",N)
set xlabel "x"
set ylabel "y"
set zlabel "z"
set grid
set key off
set view 60,30
splot archivo using 2:3:4 with linespoints lw 2 pt 7 ps 0.8
unset output
