
reset
if (!exists("datafile")) datafile="../../results/O2/analisis/trayectoria.dat"
if (!exists("outfile")) outfile="../../plots/O2/Detalles/trayectorias/Trayectoria_default.png"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0
set terminal pngcairo size 1400,800 enhanced font "Arial,12"
set output outfile
set multiplot title sprintf("O2 - Trayectoria / fases; A=%g, eta=%g, F=%g",AVAL,ETAVAL,FVAL)
set origin 0.0,0.5; set size 0.5,0.45; set title "x(t)"; set xlabel "t"; set ylabel "x"; set grid
plot datafile every ::0::30000 u 1:2 w l lw 1 title "x(t)"
set origin 0.0,0.05; set size 0.5,0.45; set title "v(t)"; set xlabel "t"; set ylabel "v"; set grid
plot datafile every ::0::30000 u 1:3 w l lw 1 title "v(t)"
set origin 0.5,0.05; set size 0.5,0.90; set size square; set title "Espacio de fases"; set xlabel "x"; set ylabel "v"; unset key; set grid
plot datafile every ::0::30000 u 2:3 w p pt 7 ps 0.22
unset multiplot; unset output
