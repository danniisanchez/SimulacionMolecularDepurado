reset
archivo="../../results/O2/resumen_F.dat"
KBT=0.2
PR(F)=1.0/(1.0+exp(-2.0*F/KBT)); PL(F)=1.0-PR(F)
set terminal pngcairo size 1050,700 enhanced font "Arial,12"
set output "../../plots/O2/Ocupacion_vs_F.png"
set title "O2 - Ocupacion frente a fuerza externa"
set xlabel "F"; set ylabel "Ocupacion"; set yrange [0:1]; set grid; set key left top
plot archivo u 1:2 w p pt 7 ps 1.1 title "P izquierda", archivo u 1:3 w p pt 5 ps 1.1 title "P derecha", \
     PL(x) w l lw 2 dt 2 title "2 estados: P_L", PR(x) w l lw 2 dt 2 title "2 estados: P_R"
unset output
