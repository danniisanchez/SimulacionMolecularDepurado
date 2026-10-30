reset
archivo="../../results/O2/resumen_A.dat"
salida="../../plots/O2/Dependencia_tau_A.png"
m=5.0; b=1.0; f(x)=m*x+b
fit f(x) archivo using 1:(log($9)) via m,b
set terminal pngcairo size 1000,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title "O2 - Dependencia con la altura de barrera A"
set grid; set key top left
set xlabel "A"; set ylabel "<tau> global"; set title "Tiempo medio de residencia"
plot archivo using 1:9 with linespoints lw 2 pt 7 title "<tau>(A)"
set xlabel "A"; set ylabel "ln <tau>"; set title sprintf("Ajuste semilogaritmico: pendiente=%.3g",m)
plot archivo using 1:(log($9)) with points pt 7 ps 1.2 title "Datos", f(x) w l lw 2 title "Ajuste"
unset multiplot; unset output
