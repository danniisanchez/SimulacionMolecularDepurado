reset
archivo="../../results/O2/resumen_F.dat"
KBT=0.2

PR(F)=1.0/(1.0+exp(-2.0*F/KBT))
PL(F)=1.0/(1.0+exp(+2.0*F/KBT))
DeltaP(F)=PR(F)-PL(F)

set terminal pngcairo size 1400,800 enhanced font "Arial,14"
set output "../../plots/O2/Diferencia_ocupacion_vs_F.png"
set border linewidth 1.3
set tics out
set title "O2 - Diferencia de ocupaciones frente a fuerza"
set xlabel "F"
set ylabel "P_R-P_L"
set yrange [-1:1]
set grid back
set key left top

plot archivo u 1:($13==1 && $14==1 && $24==1 ? $3-$2 : 1/0) w p pt 7 ps 1.25 title "Simulacion validada", \
     archivo u 1:($13!=1 || $14!=1 || $24!=1 ? $3-$2 : 1/0) w p pt 2 ps 1.25 title "Simulacion no validada", \
     archivo u 1:($13==1 && $14==1 && $24==1 ? 1.0-2.0*$18 : 1/0) w p pt 4 ps 1.05 title "Boltzmann exacta (integral)", \
     DeltaP(x) w l lw 2 dt 2 title "Logistica aproximada: P_R-P_L"

unset output
