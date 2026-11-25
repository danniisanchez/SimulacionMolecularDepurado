# O3 Rg/Ree RMS versus N - cadenas libres de N monomeros.
reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Ree_Rg_vs_N.png"
b=1.0
ReeIdeal(N)=b*sqrt(N-1.0)
RgIdeal(N)=b*sqrt((N*N-1.0)/(6.0*N))
set terminal pngcairo size 2000,1080 enhanced font "Arial,21"
set border 15 lw 1.7 lc rgb "#303B47"
set tics out nomirror font ",20"
set grid xtics ytics back lc rgb "#D4DDE5" lw 1 dt 3
set xlabel "Numero de monomeros, N" font ",27"
set lmargin at screen 0.13
set rmargin at screen 0.745
set bmargin at screen 0.15
set tmargin at screen 0.89
set key outside right top vertical box opaque spacing 1.65 samplen 2.5 font ",18"

set output salida
set title "O3 - Tamano conformacional frente a N" font ",27"
set ylabel "Longitud RMS" font ",26"
set xrange [2:66]
set yrange [0:*]
plot archivo using 1:(sqrt($7)) with points pt 7 ps 2.3 lc rgb "#D55E00" title "R_{ee,rms} simulado", \
     archivo using 1:(sqrt($9)) with points pt 5 ps 2.5 lc rgb "#0072B2" title "R_{g,rms} simulado", \
     ReeIdeal(x) with lines lw 2.8 dt 2 lc rgb "#CC79A7" title "FJC: b sqrt(N-1)", \
     RgIdeal(x) with lines lw 2.8 dt 3 lc rgb "#009E73" title "FJC: b sqrt[(N^2-1)/(6N)]"
unset output
