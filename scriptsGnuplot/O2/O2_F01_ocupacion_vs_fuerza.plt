reset
archivo="../../results/O2/resumen_F.dat"
if (!exists("AFORCE")) AFORCE=0.5
if (!exists("ETAFORCE")) ETAFORCE=1.0
KBT=0.2

# Forma solicitada en tutoria: logisticas de dos estados.
PR(F)=1.0/(1.0+exp(-2.0*F/KBT))
PL(F)=1.0/(1.0+exp(+2.0*F/KBT))

set terminal pngcairo size 1400,850 enhanced font "Arial,14"
set output "../../plots/O2/Ocupacion_vs_F.png"
set border linewidth 1.3
set tics out
set title sprintf("O2 - Ocupacion frente a fuerza; A=%g, eta=%g",AFORCE,ETAFORCE)
set xlabel "F"
set ylabel "Ocupacion"
set yrange [0:1]
set grid back
set key left top

plot archivo u 1:($13==1 && $14==1 && $24==1 ? $2 : 1/0) w p pt 7 ps 1.25 title "P izquierda (validada)", \
     archivo u 1:($13==1 && $14==1 && $24==1 ? $3 : 1/0) w p pt 5 ps 1.25 title "P derecha (validada)", \
     archivo u 1:($13!=1 || $14!=1 || $24!=1 ? $2 : 1/0) w p pt 2 ps 1.3 title "P izquierda (no validada)", \
     archivo u 1:($13!=1 || $14!=1 || $24!=1 ? $3 : 1/0) w p pt 4 ps 1.3 title "P derecha (no validada)", \
     archivo u 1:($13==1 && $14==1 && $24==1 ? $18 : 1/0) w p pt 4 ps 1.05 title "P izquierda Boltzmann exacta", \
     archivo u 1:($13==1 && $14==1 && $24==1 ? 1.0-$18 : 1/0) w p pt 6 ps 1.05 title "P derecha Boltzmann exacta", \
     PL(x) w l lw 2 dt 2 title "P_L logistica (aprox. dos estados)", \
     PR(x) w l lw 2 dt 2 title "P_R logistica (aprox. dos estados)"

unset output
