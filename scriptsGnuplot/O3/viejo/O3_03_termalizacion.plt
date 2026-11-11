# O3 - Termalizacion para un N concreto
reset
N = 4
archivo = sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
salida = sprintf("../../plots/O3/N%d/Termalizacion_N%d.png",N,N)
set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output salida
set title sprintf("Termalizacion del polimero, N=%d",N)
set xlabel "Tiempo"
set ylabel "Energia / referencia de equiparticion"
set yrange [0:1.5]
set grid
set key bottom right
plot archivo using 1:($2/$4) with lines lw 2 title "<Ek>(t)/(3NkBT/2)", \
     archivo using 1:($3/$5) with lines lw 2 title "<Ep>(t)/((N-1)kBT/2)", \
     1.0 with lines dt 2 lw 2 title "Equiparticion"
unset output
