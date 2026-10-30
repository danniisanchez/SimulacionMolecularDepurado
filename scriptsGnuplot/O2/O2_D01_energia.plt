reset
archivo="../../results/O2/analisis/energia.dat"
KBT=0.2
set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output "../../plots/O2/Energia_referencia.png"
set title "O2 - Termalizacion energetica (caso de referencia)"
set xlabel "Tiempo"; set ylabel "Energia"; set grid; set key top right
plot 0.5*KBT w l dt 2 lw 2 title "<E_k>=kBT/2", \
     archivo u 1:2 w l lw 2 title "<E_k>", archivo u 1:3 w l lw 2 title "<V>"
unset output
