reset
archivo="../../results/O2/analisis/energia.dat"
KBT=0.2
set terminal pngcairo size 1400,800 enhanced font "Arial,14"
set output "../../plots/O2/Energia_referencia.png"
set title "O2 - Termalizacion energetica (caso de referencia)"
set xlabel "Tiempo"
set ylabel "Energia"
set border linewidth 1.3
set tics out
set grid back
set key top right
plot 0.5*KBT w l dt 2 lw 2 title "<E_k>=k_BT/2", \
     archivo u 1:2 w l lw 1.8 title "<E_k>", \
     archivo u 1:3 w l lw 1.8 title "<V>"
unset output
