# Definición de variables 
h = "0.0001"
eta = "10"

# Rutas de entrada para los tres métodos
file_euler  = sprintf("../../results/O1/Euler/datosEnergia_%s_%s_Euler.txt", h, eta)
file_rk2    = sprintf("../../results/O1/RK2/datosEnergia_%s_%s_RK2.txt", h, eta)
file_verlet = sprintf("../../results/O1/Verlet/datosEnergia_%s_%s_Verlet.txt", h, eta)

# Ruta de salida (imagen más ancha para dos gráficas)
output_file = sprintf("../../plots/O1/Comparativa/ComparacionMetodos_Sep_%s_%s.png", h, eta)

# Configuración del terminal
set terminal pngcairo size 1200,600 enhanced font 'Arial,12'
set output output_file

# Activar multiplot para dividir el lienzo en 1 fila y 2 columnas
set multiplot layout 1,2 title sprintf("Comparación de Métodos (h=%s, {/Symbol h}=%s)", h, eta) font ",14"

# Definir la recta teórica para Ek y Ep (0.5)
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

# Dibujar la recta teórica y la energía cinética (columna 2)
plot E_teorica(x) title "Valor teórico (0.5)" with lines dashtype 2 linewidth 2 linecolor rgb "black", \
     file_euler using 1:2 title "Euler" with lines linewidth 1.5 linecolor rgb "red", \
     file_rk2 using 1:2 title "RK2" with lines linewidth 2.5 linecolor rgb "blue", \
     file_verlet using 1:2 title "Verlet" with lines linewidth 1.5 linecolor rgb "forest-green"


# ==========================================
# GRÁFICA 2: ENERGÍA POTENCIAL (Derecha)
# ==========================================
set title "Energía Potencial <E_p>"
set xlabel "Tiempo (t)"
set ylabel "<E_p>"
set grid
set yrange [0.0:1.0]
set key top right box opaque

# Dibujar la recta teórica y la energía potencial (columna 3)
plot E_teorica(x) title "Valor teórico (0.5)" with lines dashtype 2 linewidth 2 linecolor rgb "black", \
     file_euler using 1:3 title "Euler" with lines linewidth 1.5 linecolor rgb "red", \
     file_rk2 using 1:3 title "RK2" with lines linewidth 2.5 linecolor rgb "blue", \
     file_verlet using 1:3 title "Verlet" with lines linewidth 1.5 linecolor rgb "forest-green"

unset multiplot