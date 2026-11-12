reset
archivo="../../results/O2/resumen_F.dat"
KBT=0.2

# Aproximacion de dos estados cerca de x=+-1:
# Delta V_L ~= A-F, Delta V_R ~= A+F
# => tau_L ~ C_L exp(-F/kBT), tau_R ~ C_R exp(+F/kBT).
# Con las pendientes termicas fijadas, las funciones son lineales en C_L/C_R.
# Minimos cuadrados EXACTOS sin optimizador no lineal:
# C = sum_j tau_j h_j / sum_j h_j^2, h_L=exp(-F/kBT), h_R=exp(F/kBT).
# Las filas NO validadas contribuyen cero a numerador y denominador.
es_valido(tc,sc,go)=(tc==1 && sc==1 && go==1)
stats archivo using (es_valido($13,$14,$24) && $7>0 ? 1 : 0) name "NCL" nooutput
stats archivo using (es_valido($13,$14,$24) && $8>0 ? 1 : 0) name "NCR" nooutput
stats archivo using (es_valido($13,$14,$24) && $7>0 ? $7*exp(-$1/KBT) : 0) name "NUML" nooutput
stats archivo using (es_valido($13,$14,$24) && $7>0 ? exp(-2.0*$1/KBT) : 0) name "DENL" nooutput
stats archivo using (es_valido($13,$14,$24) && $8>0 ? $8*exp(+$1/KBT) : 0) name "NUMR" nooutput
stats archivo using (es_valido($13,$14,$24) && $8>0 ? exp(+2.0*$1/KBT) : 0) name "DENR" nooutput
HASL=(NCL_sum>=3 && DENL_sum>0)
HASR=(NCR_sum>=3 && DENR_sum>0)
CL=(HASL ? NUML_sum/DENL_sum : 1.0)
CR=(HASR ? NUMR_sum/DENR_sum : 1.0)
TL(F)=CL*exp(-F/KBT)
TR(F)=CR*exp(+F/KBT)

g(F)=2.0*F/KBT

set terminal pngcairo size 1450,950 enhanced font "Arial,14"
set output "../../plots/O2/Tiempos_vs_F.png"
set multiplot layout 2,1 title "O2 - Respuesta dinamica a la fuerza"
set border linewidth 1.3
set tics out
set grid back
set key top left

set xlabel "F"
set ylabel "Tiempo medio"
set logscale y
set title "Tiempos validados y Kramers (aproximacion local de dos estados)"
plot archivo u 1:($13==1 && $14==1 && $24==1 ? $7 : 1/0):($7*$22) w yerrorbars pt 7 ps 1.1 title "<tau> izquierda (error relativo)", \
     archivo u 1:($13==1 && $14==1 && $24==1 ? $8 : 1/0):($8*$23) w yerrorbars pt 5 ps 1.1 title "<tau> derecha (error relativo)", \
     archivo u 1:($13!=1 || $14!=1 || $24!=1 ? $7 : 1/0) w p pt 2 ps 1.1 title "<tau> izquierda no validado", \
     archivo u 1:($13!=1 || $14!=1 || $24!=1 ? $8 : 1/0) w p pt 4 ps 1.1 title "<tau> derecha no validado", \
     (HASL ? TL(x) : 1/0) w l lw 2 title "C_L exp(-F/k_BT), MC validado", \
     (HASR ? TR(x) : 1/0) w l lw 2 title "C_R exp(+F/k_BT), MC validado"

unset logscale y
set xlabel "F"
set ylabel "ln(<tau_R>/<tau_L>)"
set title "Cociente de tiempos: prediccion de dos estados"
plot archivo u 1:($13==1 && $14==1 && $24==1 && $7>0 && $8>0 ? log($8/$7) : 1/0) w p pt 7 ps 1.25 title "Simulacion validada", \
     archivo u 1:(($13!=1 || $14!=1 || $24!=1) && $7>0 && $8>0 ? log($8/$7) : 1/0) w p pt 2 ps 1.2 title "Simulacion no validada", \
     g(x) w l lw 2 dt 2 title "2F/k_BT (aproximacion)"

unset multiplot
unset output
