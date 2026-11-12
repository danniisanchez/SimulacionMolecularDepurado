reset
f05="../../results/O2/resumen_eta_A0.5.dat"
f10="../../results/O2/resumen_eta_A1.dat"
f20="../../results/O2/resumen_eta_A2.dat"
es_validado(tc,sc,go)=(tc==1 && sc==1 && go==1)
set terminal pngcairo size 1500,900 enhanced font "Arial,14"
set output "../../plots/O2/Ocupaciones_eta_A0.5_A1_A2.png"
set multiplot layout 2,1 title "O2 - Ocupaciones versus friccion y altura de barrera; F=0"
set border linewidth 1.3
set tics out
set grid back
set yrange [0:1]
set key bottom right
set xlabel "eta"
set ylabel "P izquierda"
set title "Ocupacion izquierda; simbolos huecos = no validado"
plot 0.5 w l lw 2 dt 2 title "Boltzmann: 0.5", \
     f05 u 1:(es_validado($13,$14,$24) ? $2 : 1/0) w p pt 7 ps 1.3 title "A=0.5", \
     f10 u 1:(es_validado($13,$14,$24) ? $2 : 1/0) w p pt 5 ps 1.3 title "A=1", \
     f20 u 1:(es_validado($13,$14,$24) ? $2 : 1/0) w p pt 9 ps 1.3 title "A=2", \
     f05 u 1:(!es_validado($13,$14,$24) ? $2 : 1/0) w p pt 2 ps 1.0 title "A=0.5 no validado", \
     f10 u 1:(!es_validado($13,$14,$24) ? $2 : 1/0) w p pt 4 ps 1.0 title "A=1 no validado", \
     f20 u 1:(!es_validado($13,$14,$24) ? $2 : 1/0) w p pt 6 ps 1.0 title "A=2 no validado"
set xlabel "eta"
set ylabel "P derecha"
set title "Ocupacion derecha; simbolos huecos = no validado"
plot 0.5 w l lw 2 dt 2 title "Boltzmann: 0.5", \
     f05 u 1:(es_validado($13,$14,$24) ? $3 : 1/0) w p pt 7 ps 1.3 title "A=0.5", \
     f10 u 1:(es_validado($13,$14,$24) ? $3 : 1/0) w p pt 5 ps 1.3 title "A=1", \
     f20 u 1:(es_validado($13,$14,$24) ? $3 : 1/0) w p pt 9 ps 1.3 title "A=2", \
     f05 u 1:(!es_validado($13,$14,$24) ? $3 : 1/0) w p pt 2 ps 1.0 title "A=0.5 no validado", \
     f10 u 1:(!es_validado($13,$14,$24) ? $3 : 1/0) w p pt 4 ps 1.0 title "A=1 no validado", \
     f20 u 1:(!es_validado($13,$14,$24) ? $3 : 1/0) w p pt 6 ps 1.0 title "A=2 no validado"
unset multiplot
unset output
