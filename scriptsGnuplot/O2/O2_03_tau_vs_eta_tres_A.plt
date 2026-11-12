reset
f05="../../results/O2/resumen_eta_A0.5.dat"
f10="../../results/O2/resumen_eta_A1.dat"
f20="../../results/O2/resumen_eta_A2.dat"
es_validado(tc,sc,go)=(tc==1 && sc==1 && go==1)
set terminal pngcairo size 1500,950 enhanced font "Arial,14"
set output "../../plots/O2/Tau_vs_eta_A0.5_A1_A2_lineal.png"
set multiplot layout 2,1 title "O2 - Comparacion tau(eta) para A=0.5, 1 y 2; F=0"
set grid back
set border linewidth 1.3
set tics out
unset logscale
set key top left
set xlabel "eta (escala lineal)"
set ylabel "<tau> global"
set title "Mediciones independientes; cruces = estadistica/termalizacion insuficiente"
plot f05 u 1:(es_validado($13,$14,$24) ? $9 : 1/0) w p pt 7 ps 1.35 title "A=0.5 validado", \
     f10 u 1:(es_validado($13,$14,$24) ? $9 : 1/0) w p pt 5 ps 1.35 title "A=1 validado", \
     f20 u 1:(es_validado($13,$14,$24) ? $9 : 1/0) w p pt 9 ps 1.35 title "A=2 validado", \
     f05 u 1:(!es_validado($13,$14,$24) ? $9 : 1/0) w p pt 2 ps 1.1 title "A=0.5 no validado", \
     f10 u 1:(!es_validado($13,$14,$24) ? $9 : 1/0) w p pt 4 ps 1.1 title "A=1 no validado", \
     f20 u 1:(!es_validado($13,$14,$24) ? $9 : 1/0) w p pt 6 ps 1.1 title "A=2 no validado"

set xlabel "eta (escala lineal)"
set ylabel "k_{sim} = 1/<tau>"
set title "Comparacion de tasas de escape"
plot f05 u 1:(es_validado($13,$14,$24) ? $10 : 1/0) w p pt 7 ps 1.35 title "A=0.5", \
     f10 u 1:(es_validado($13,$14,$24) ? $10 : 1/0) w p pt 5 ps 1.35 title "A=1", \
     f20 u 1:(es_validado($13,$14,$24) ? $10 : 1/0) w p pt 9 ps 1.35 title "A=2", \
     f05 u 1:(!es_validado($13,$14,$24) ? $10 : 1/0) w p pt 2 ps 1.1 title "A=0.5 no validado", \
     f10 u 1:(!es_validado($13,$14,$24) ? $10 : 1/0) w p pt 4 ps 1.1 title "A=1 no validado", \
     f20 u 1:(!es_validado($13,$14,$24) ? $10 : 1/0) w p pt 6 ps 1.1 title "A=2 no validado"
unset multiplot
unset output
