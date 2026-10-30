reset
archivo="../../results/O2/resumen_F.dat"
KBT=0.2; mteo(F)=tanh(F/KBT)
set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output "../../plots/O2/Diferencia_ocupacion_vs_F.png"
set title "O2 - Diferencia de ocupaciones frente a fuerza"
set xlabel "F"; set ylabel "P_R-P_L"; set yrange [-1:1]; set grid; set key left top
plot archivo u 1:($3-$2) w p pt 7 ps 1.2 title "Simulacion", mteo(x) w l lw 2 dt 2 title "tanh(F/kBT)"
unset output
