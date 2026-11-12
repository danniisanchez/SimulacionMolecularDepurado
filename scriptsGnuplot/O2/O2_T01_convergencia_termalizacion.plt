reset
archivo="../../results/O2/termalizacion_scan/resumen_termalizacion.dat"
set terminal pngcairo size 1400,900 enhanced font "Arial,14"
set output "../../plots/O2/TermalizacionScan/Diagnostico_vs_t_term.png"
set multiplot layout 2,1 title "O2 - Estudio controlado de termalizacion (A=1, eta=1, F=0)"
set grid back
set tics out
set border linewidth 1.3
set xlabel "Pasos de termalizacion (impuestos)"
set ylabel "Distancia L1 de P(x) a Boltzmann"
set title "Mejora del acuerdo con Boltzmann"
plot archivo u 1:3 w lp pt 7 ps 1.3 lw 1.2 title "Integral |P_sim-P_B| dx"
set xlabel "Pasos de termalizacion"
set ylabel "Indicador (0/1)"
set yrange [-0.1:1.15]
set title "Banderas de equilibrio local, mezcla global y estadistica"
plot archivo u 1:5 w p pt 7 ps 1.3 title "term_converged", \
     archivo u 1:6 w p pt 5 ps 1.3 title "term_global_ok", \
     archivo u 1:7 w p pt 9 ps 1.3 title "stats_converged"
unset multiplot
unset output
