reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Ree_Rg_vs_N.png"
b=1.0
ReeIdeal(N)=b*sqrt(N-1.0)
RgIdeal(N)=b*sqrt((N*N-1.0)/(6.0*N))

stats archivo using 1 name "NN" nooutput

set terminal pngcairo size 1500,950 enhanced font "Arial,14"
set output salida
set border linewidth 1.3
set tics out
set grid back
set title "O3 - Tamano conformacional frente a N"
set xlabel "Numero de beads, N"
set ylabel "Longitud RMS"
set xrange [NN_min-1:NN_max+4]
set key top left
plot archivo u 1:(sqrt($7)) w p pt 7 ps 1.5 title "R_{ee,rms} simulacion", \
     archivo u 1:(sqrt($9)) w p pt 5 ps 1.5 title "R_{g,rms} simulacion", \
     ReeIdeal(x) w l lw 2 dt 2 title "FJC: b sqrt(N-1)", \
     RgIdeal(x) w l lw 2 dt 3 title "FJC finita: b sqrt[(N^2-1)/(6N)]"
unset output
