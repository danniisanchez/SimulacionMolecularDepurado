reset
# Sustitucion nueva del archivo NO aportado en la primera auditoria.
# Residuo de la ocupacion izquierda respecto a la logistica de dos estados.
# Contrato: resumen_F.dat de 24 columnas (13=TERM, 14=STATS, 24=GLOBAL;
# 18=P_izq teorica exacta por integral de Boltzmann).
archivo="../../results/O2/resumen_F.dat"
salida="../../plots/O2/Residuo_logistica_vs_F.png"
KBT=0.2

es_validado(tc,sc,go)=(tc==1 && sc==1 && go==1)
PL_log(F)=1.0/(1.0+exp(2.0*F/KBT))

set terminal pngcairo size 1400,800 enhanced font "Arial,14"
set output salida
set border linewidth 1.3
set tics out
set title "O2 - Residuo de ocupacion izquierda frente a logistica de dos estados"
set xlabel "F"
set ylabel "P_izquierda - P_izquierda(logistica)"
set grid back
set key top left

plot 0 with lines lw 1 dt 2 title "Residuo nulo", \
     archivo using 1:(es_validado($13,$14,$24) ? $2-PL_log($1) : 1/0) with points pt 7 ps 1.3 title "Simulacion validada", \
     archivo using 1:(!es_validado($13,$14,$24) ? $2-PL_log($1) : 1/0) with points pt 2 ps 1.3 title "Simulacion no validada", \
     archivo using 1:($18-PL_log($1)) with linespoints lw 1.5 pt 4 ps 0.8 title "Boltzmann exacta - logistica (aprox.)"

unset output
