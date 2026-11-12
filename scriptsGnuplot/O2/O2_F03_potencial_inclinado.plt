reset
if (!exists("AFORCE")) AFORCE=0.5
A=AFORCE

V(x,F)=A*(x*x-1.0)**2-F*x

set terminal pngcairo size 1400,800 enhanced font "Arial,14"
set output "../../plots/O2/Potencial_doble_pozo_con_fuerza.png"
set border linewidth 1.3
set tics out
set title sprintf("O2 - Doble pozo inclinado; A=%g",A)
set xlabel "x"
set ylabel "V(x)"
set xrange [-1.8:1.8]
set grid back
set key top center

plot V(x,-0.5) w l lw 2 title "F=-0.5", \
     V(x,-0.25) w l lw 2 title "F=-0.25", \
     V(x,0) w l lw 2 title "F=0", \
     V(x,0.25) w l lw 2 title "F=+0.25", \
     V(x,0.5) w l lw 2 title "F=+0.5"

unset output
