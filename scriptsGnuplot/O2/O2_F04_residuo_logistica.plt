reset
archivo="../../results/O2/resumen_F.dat"
KBT=0.2
PR(F)=1.0/(1.0+exp(-2.0*F/KBT))
PL(F)=1.0-PR(F)
valid(tc,sc,go)=(tc==1 && sc==1 && go==1)
set terminal pngcairo size 1400,850 enhanced font "Arial,14"
set output "../../plots/O2/Residuos_ocupacion_vs_F.png"
set grid back
set border linewidth 1.3
set tics out
set key top left
set xlabel "F"
set ylabel "P_izq(sim)-P_izq(teoria)"
set title "O2 - Desviacion frente a Boltzmann exacta y logistica (aprox. dos estados)"
plot 0 w l dt 2 lw 2 title "Acuerdo perfecto", \
     archivo u 1:(valid($13,$14,$24) ? $2-$18 : 1/0) w p pt 7 ps 1.35 title "Sim. - Boltzmann exacta", \
     archivo u 1:(valid($13,$14,$24) ? $2-PL($1) : 1/0) w p pt 5 ps 1.35 title "Sim. - logistica aproximada"
unset output
