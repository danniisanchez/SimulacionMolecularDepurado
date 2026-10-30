reset
archivo="../../results/O2/analisis/trayectoria.dat"
max_lineas=30000
set terminal pngcairo size 1400,800 enhanced font "Arial,12"
set output "../../plots/O2/Trayectorias/Trayectoria_fase_referencia.png"
set multiplot title "O2 - Trayectoria y espacio de fases (caso de referencia)"
set origin 0.0,0.5; set size 0.5,0.45; set title "x(t)"; set xlabel "t"; set ylabel "x"; set grid; set size noratio
plot archivo every ::0::max_lineas u 1:2 w l lw 1 title "x(t)"
set origin 0.0,0.05; set size 0.5,0.45; set title "v(t)"; set xlabel "t"; set ylabel "v"; set grid
plot archivo every ::0::max_lineas u 1:3 w l lw 1 title "v(t)"
set origin 0.5,0.05; set size 0.5,0.90; set size square; set title "Espacio de fases"; set xlabel "x"; set ylabel "v"; unset key; set grid
plot archivo every ::0::max_lineas u 2:3 w p pt 7 ps 0.25
unset multiplot; unset output
