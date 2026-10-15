set terminal pngcairo size 800,600 enhanced font 'Arial,14'
set output sprintf("../../plots/O2/Verlet/Distribucion_Tiempos_A%g_eta%s.png", A, eta)

# Define aqui los parametros que vas a plotear
A = 0.5
eta = "0.01"

set title sprintf("Distribucion de Tiempos de Estancia (A=%g, eta=%s)", A, eta)
set xlabel "Tiempo de estancia (t)"
set ylabel "Frecuencia (Escala Logaritmica)"
set logscale y
set grid

# Configuracion del histograma
binwidth = 2.0
bin(x,width) = width*floor(x/width) + width/2.0
set style fill transparent solid 0.5 border -1


plot sprintf("../../results/O2/Verlet/tiempos_derecha_A%g_eta%s.txt", A, eta) using (bin($1,binwidth)):(1.0) smooth freq with boxes lc rgb "blue" title "Estado x > 0 (Derecha)", \
     sprintf("../../results/O2/Verlet/tiempos_izquierda_A%g_eta%s.txt", A, eta) using (bin($1,binwidth)):(1.0) smooth freq with boxes lc rgb "red" title "Estado x < 0 (Izquierda)"