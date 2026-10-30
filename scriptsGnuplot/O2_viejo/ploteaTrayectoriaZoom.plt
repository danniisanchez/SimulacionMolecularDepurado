h = "0.001"
A = 1
eta = "0.1"
metodo = "Verlet"

# Ajusta el nombre según cómo lo guarde tu C
input_file = sprintf("../../results/O2/%s/datosTrayectoria_h%s_A%g_eta%s_%s.txt", metodo, h, A, eta, metodo)
output_file = "../../plots/O2/Trayectoria_Zoom_Salto.png"

set terminal pngcairo size 1000,500 enhanced font 'Arial,12'
set output output_file

set title "Zoom en transición de pozo (Régimen subamortiguado)"
set xlabel "Tiempo (t)"
set ylabel "Posición x(t)"
set grid


# Ajusta estos números si el salto en tu archivo exacto ocurre en otro segundo
set xrange [800:850] 
set yrange [-1.5:1.5]

# Dibujamos con líneas finas para ver bien la oscilación
plot input_file using 1:2 with lines linewidth 1.5 linecolor rgb "purple" title "x(t)"