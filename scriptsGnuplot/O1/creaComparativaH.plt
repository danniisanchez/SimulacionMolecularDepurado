# Definición de variables
metodo = "RK2"
eta = "0.1"

# Rutas de entrada para los distintos pasos h
file_h01    = sprintf("../../results/O1/%s/datosEnergia_0.1_%s_%s.txt", metodo, eta, metodo)
file_h001   = sprintf("../../results/O1/%s/datosEnergia_0.01_%s_%s.txt", metodo, eta, metodo)
file_h0001  = sprintf("../../results/O1/%s/datosEnergia_0.001_%s_%s.txt", metodo, eta, metodo)
file_h00001 = sprintf("../../results/O1/%s/datosEnergia_0.0001_%s_%s.txt", metodo, eta, metodo)

# Ruta de salida (imagen más ancha para que quepan dos gráficas)
output_file = sprintf("../../plots/O1/Comparativa/ComparacionH_Sep_%s_%s.png", metodo, eta)

# Configuración del terminal
set terminal pngcairo size 1200,600 enhanced font 'Arial,12'
set output output_file

# Activar multiplot para dividir el lienzo en 1 fila y 2 columnas
set multiplot layout 1,2 title sprintf("Efecto del paso h: %s ({/Symbol h}=%s)", metodo, eta) font ",14"

# Definir la recta teórica para Ek y Ep
E_teorica(x) = 0.5

# ==========================================
# GRÁFICA 1: ENERGÍA CINÉTICA (Izquierda)
# ==========================================
set title "Energía Cinética <E_k>"
set xlabel "Tiempo (t)"
set ylabel "<E_k>"
set grid
set yrange [0.0:1.0] 
set key top right box opaque

# Dibujamos usando la columna 2 (using 1:2)
plot E_teorica(x) title "Valor teórico (0.5)" with lines dashtype 2 linewidth 2 linecolor rgb "black", \
     file_h01 using 1:2 title "h = 0.1" with lines linewidth 1.5 linecolor rgb "forest-green", \
     file_h001 using 1:2 title "h = 0.01" with lines linewidth 1.5 linecolor rgb "dark-violet", \
     file_h0001 using 1:2 title "h = 0.001" with lines linewidth 1.5 linecolor rgb "blue", \
     file_h00001 using 1:2 title "h = 0.0001" with lines linewidth 1.5 linecolor rgb "red"

# ==========================================
# GRÁFICA 2: ENERGÍA POTENCIAL (Derecha)
# ==========================================
set title "Energía Potencial <E_p>"
set xlabel "Tiempo (t)"
set ylabel "<E_p>"
set grid
set yrange [0.0:1.0] 
set key top right box opaque

# Dibujamos usando la columna 3 (using 1:3)
plot E_teorica(x) title "Valor teórico (0.5)" with lines dashtype 2 linewidth 2 linecolor rgb "black", \
     file_h01 using 1:3 title "h = 0.1" with lines linewidth 1.5 linecolor rgb "forest-green", \
     file_h001 using 1:3 title "h = 0.01" with lines linewidth 1.5 linecolor rgb "dark-violet", \
     file_h0001 using 1:3 title "h = 0.001" with lines linewidth 1.5 linecolor rgb "blue", \
     file_h00001 using 1:3 title "h = 0.0001" with lines linewidth 1.5 linecolor rgb "red"

unset multiplot