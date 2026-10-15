set terminal pngcairo size 800,600 enhanced font 'Arial,14'
set output "../../plots/O2/Kramers_Turnover_A0.5.png"

set title "Turnover de Kramers: Tiempo medio vs Friccion (A=0.5)"
set xlabel "Friccion ({/Symbol h}) [escala log]"
set ylabel "Tiempo medio de estancia (t_m) [escala log]"

# Ponemos ambos ejes en logaritmo para ver bien todos los regimenes
set logscale xy
set grid

# Ajustes de estilo para imitar el dibujo de la pizarra
set style line 1 lc rgb "dark-green" lw 3 pt 7 ps 1.5

plot "../../results/O2/Verlet/datos_kramers_A0.5.txt" using 1:2 with linespoints ls 1 title "Tiempo Medio (Global)"