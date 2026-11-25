# O3 equiparticion - cadena libre; nueva referencia cinetica = 3 NkBT/2.
reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Equiparticion_vs_N.png"
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
set title "O3 - Equiparticion y termalizacion frente a N" font ",27"
set ylabel "Energia media / referencia" font ",26"
set yrange [0.75:1.25]
plot 1.0 with lines lw 2.1 dt 2 lc rgb "#303B47" title "Equiparticion = 1", \
 archivo using 1:($2/$3) with points pt 7 ps 2.3 lc rgb "#0072B2" title "Cinetica: E_k / (3Nk_{B}T/2)", \
 archivo using 1:($4/$5) with points pt 5 ps 2.5 lc rgb "#D55E00" title "Enlace: E_{bond} / [(N-1)k_{B}T/2]"
unset output
