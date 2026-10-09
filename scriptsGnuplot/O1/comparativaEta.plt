# Definición de variables
metodo = "Verlet"
h = "0.0001"

# Rutas de entrada para distintas etas (0.1, 1, 10)
file_eta01 = sprintf("../../results/O1/%s/datosEnergia_%s_0.1_%s.txt", metodo, h, metodo)
file_eta1  = sprintf("../../results/O1/%s/datosEnergia_%s_1_%s.txt", metodo, h, metodo)
file_eta10 = sprintf("../../results/O1/%s/datosEnergia_%s_10_%s.txt", metodo, h, metodo)

# Ruta de salida (imagen más ancha para que quepan dos gráficas)
output_file = sprintf("../../plots/O1/Comparativa/ComparacionEta_Sep_%s_%s.png", metodo, h)

# Configuración del terminal
set terminal pngcairo size 1200,600 enhanced font 'Arial,12'
set output output_file

# Activar multiplot para dividir el lienzo en 1 fila y 2 columnas
set multiplot layout 1,2 title sprintf("Efecto del parámetro {/Symbol h}: %s (h=%s)", metodo, h) font ",14"

# Definir la recta teórica para Ek y Ep (0.5 kBT)
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
     file_eta01 using 1:2 title "{/Symbol h} = 0.1" with lines linewidth 1.5 linecolor rgb "orange", \
     file_eta1 using 1:2 title "{/Symbol h} = 1" with lines linewidth 1.5 linecolor rgb "forest-green", \
     file_eta10 using 1:2 title "{/Symbol h} = 10" with lines linewidth 1.5 linecolor rgb "purple"


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
     file_eta01 using 1:3 title "{/Symbol h} = 0.1" with lines linewidth 1.5 linecolor rgb "orange", \
     file_eta1 using 1:3 title "{/Symbol h} = 1" with lines linewidth 1.5 linecolor rgb "forest-green", \
     file_eta10 using 1:3 title "{/Symbol h} = 10" with lines linewidth 1.5 linecolor rgb "purple"

unset multiplot