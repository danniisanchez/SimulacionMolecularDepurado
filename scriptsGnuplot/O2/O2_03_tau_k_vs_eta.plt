reset
archivo="../../results/O2/resumen_eta.dat"
salida="../../plots/O2/Dependencia_tau_eta.png"
set terminal pngcairo size 1000,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title "O2 - Dependencia con la friccion / turnover de Kramers"
set grid; set logscale x; set key top right
set xlabel "eta"; set ylabel "<tau> global"; set title "Tiempo medio de residencia"
plot archivo using 1:9 with linespoints lw 2 pt 7 title "<tau>(eta)"
set xlabel "eta"; set ylabel "k_sim=1/<tau>"; set title "Tasa de escape"
plot archivo using 1:10 with linespoints lw 2 pt 7 title "k(eta)"
unset logscale x; unset multiplot; unset output
