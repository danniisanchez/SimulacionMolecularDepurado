# O3 - Punto v: observables al variar N
# El ajuste de la ley de escala de Rg corresponde al punto vi.
reset
archivo = "../../results/O3/resumen_tamanos.dat"
salida = "../../plots/O3/Ree_Rg_vs_N.png"
set terminal pngcairo size 1000,700 enhanced font "Arial,12"
set output salida
set title "Objetivo 3: tamaño conformacional del polimero"
set xlabel "Numero de beads, N"
set ylabel "Longitud media"
set grid
set key top left
plot archivo using 1:6 with linespoints lw 2 pt 7 title "<Ree>", \
     archivo using 1:8 with linespoints lw 2 pt 5 title "<Rg>"
unset output
