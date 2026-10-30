reset
A=1.0; V(x,F)=A*(x*x-1.0)**2-F*x
set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output "../../plots/O2/Potencial_doble_pozo_con_fuerza.png"
set title "O2 - Doble pozo inclinado por fuerza externa"
set xlabel "x"; set ylabel "V(x)"; set xrange [-1.8:1.8]; set grid; set key top center
plot V(x,-0.3) w l lw 2 title "F=-0.3", V(x,0) w l lw 2 title "F=0", V(x,0.3) w l lw 2 title "F=+0.3"
unset output
