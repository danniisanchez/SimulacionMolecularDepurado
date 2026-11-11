reset
if(!exists("N")) N=4
archivo=sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
salida=sprintf("../../plots/O3/N%d/Termalizacion_N%d.png",N,N)
KBT=1.0
EkRef=1.5*(N-1)*KBT
EbondRef=0.5*(N-1)*KBT

stats archivo u 1 name "T" nooutput
stride=int(T_records/40000.0)+1
if(stride<1) stride=1

set terminal pngcairo size 1500,1050 enhanced font "Arial,14"
set output salida
set multiplot layout 2,1 title sprintf("O3 - Termalizacion, N=%d",N)
set border linewidth 1.3
set tics out
set grid back
set xrange [T_min:T_max]

set xlabel "Tiempo"
set ylabel "Energia / referencia"
set title "Equilibrio energetico"
plot archivo every stride u 1:($2/EkRef) w l lw 1.6 title "<E_k>/(3(N-1)k_BT/2)", \
     archivo every stride u 1:($3/EbondRef) w l lw 1.6 title "<E_{bond}>/((N-1)k_BT/2)", \
     1.0 w l lw 2 dt 2 title "Referencia"

set xlabel "Tiempo"
set ylabel "Longitud"
set title "Estabilizacion estructural"
plot archivo every stride u 1:7 w l lw 1.5 title "<R_{ee}>", \
     archivo every stride u 1:8 w l lw 1.5 title "<R_g>", \
     archivo every stride u 1:9 w l lw 1.5 title "<l_{bond}>"
unset multiplot
unset output
