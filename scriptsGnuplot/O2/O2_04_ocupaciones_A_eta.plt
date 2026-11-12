reset
if (!exists("AETA")) AETA=0.5

a="../../results/O2/resumen_A.dat"
e=sprintf("../../results/O2/resumen_eta_A%g.dat",AETA)
salida="../../plots/O2/Ocupaciones_A_eta.png"

set terminal pngcairo size 1450,700 enhanced font "Arial,14"
set output salida
set multiplot layout 1,2 title "O2 - Ocupacion de los dos pozos"
set border linewidth 1.3
set tics out
set grid back
set yrange [0:1]
set ylabel "Ocupacion"
set key bottom right

set xlabel "A"
set title "Variacion con A (eta=1, F=0); simbolos huecos = no validados"
plot 0.5 w l dt 2 lw 2 title "Equilibrio simetrico: P=0.5", \
     a u 1:($13==1 && $14==1 && $24==1 ? $2 : 1/0) w p pt 7 ps 1.25 title "P izquierda", \
     a u 1:($13==1 && $14==1 && $24==1 ? $3 : 1/0) w p pt 5 ps 1.25 title "P derecha", \
     a u 1:(($13!=1 || $14!=1 || $24!=1) ? $2 : 1/0) w p pt 2 ps 1.05 title "P izq no validada", \
     a u 1:(($13!=1 || $14!=1 || $24!=1) ? $3 : 1/0) w p pt 4 ps 1.05 title "P der no validada"

set xlabel "eta"
set title sprintf("Variacion con eta (A=%g, F=0)",AETA)
plot 0.5 w l dt 2 lw 2 title "Equilibrio simetrico: P=0.5", \
     e u 1:($13==1 && $14==1 && $24==1 ? $2 : 1/0) w p pt 7 ps 1.25 title "P izquierda", \
     e u 1:($13==1 && $14==1 && $24==1 ? $3 : 1/0) w p pt 5 ps 1.25 title "P derecha", \
     e u 1:(($13!=1 || $14!=1 || $24!=1) ? $2 : 1/0) w p pt 2 ps 1.05 title "P izq no validada", \
     e u 1:(($13!=1 || $14!=1 || $24!=1) ? $3 : 1/0) w p pt 4 ps 1.05 title "P der no validada"

unset multiplot
unset output
