reset
archivo="../../results/O2/resumen_F.dat"
KBT=0.2; g(F)=2.0*F/KBT
set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output "../../plots/O2/Tiempos_vs_F.png"
set multiplot layout 2,1 title "O2 - Respuesta dinamica a la fuerza"
set grid; set key top left; set xlabel "F"; set ylabel "Tiempo medio"; set logscale y
plot archivo u 1:7 w lp lw 2 pt 7 title "<tau> izquierda", archivo u 1:8 w lp lw 2 pt 5 title "<tau> derecha"
unset logscale y; set xlabel "F"; set ylabel "ln(<tau_R>/<tau_L>)"
plot archivo u 1:(log($8/$7)) w p pt 7 ps 1.2 title "Simulacion", g(x) w l lw 2 dt 2 title "2F/kBT"
unset multiplot; unset output
