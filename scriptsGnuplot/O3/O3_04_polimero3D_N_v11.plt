reset
if(!exists("N")) N=4
archivo=sprintf("../../results/O3/N%d/snapshot_final_N%d.dat",N,N)
salida=sprintf("../../plots/O3/N%d/Polimero3D_N%d.png",N,N)
set terminal pngcairo size 1100,1000 enhanced font "Arial,14"
set output salida
set border linewidth 1.2
set title sprintf("O3 - Configuracion final del polimero, N=%d",N)
set xlabel "x"; set ylabel "y"; set zlabel "z"
set grid
set view 60,35
set key off
splot archivo u 2:3:4 w lp lw 2 pt 7 ps 0.8
unset output
