# O3 - Bending armónico: energías y longitud de enlace

reset

N=64
archivo=sprintf("../../results/O3/bending_armonico_N%d.dat",N)
salida=sprintf("../../plots/O3/Bending_energias_N%d.png",N)

set terminal pngcairo size 1000,820 enhanced font "Arial,12"
set output salida

set multiplot layout 2,1 title sprintf("Energetica del bending armonico, N=%d",N)

set title "Contribuciones potenciales"
set xlabel "K_{bend} / k_BT  (k_BT=1)"
set ylabel "Energia media"
set grid
set key top left
plot archivo using 1:4 with linespoints lw 2 pt 7 title "<E_bond>", \
     archivo using 1:5 with linespoints lw 2 pt 5 title "<E_bend>"

set title "Longitud media de enlace"
set xlabel "K_{bend} / k_BT  (k_BT=1)"
set ylabel "<l>"
set grid
set key top left
plot archivo using 1:8 with linespoints lw 2 pt 7 title "<l>", \
     1.0 with lines dt 2 lw 2 title "b=1"

unset multiplot
unset output
print sprintf("Figura guardada en: %s",salida)
