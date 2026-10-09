# Definición de variables
h = "0.001"
eta = "0.1"
metodo = "RK2"

# Rutas de entrada y salida
input_file = sprintf("../../results/O2/%s/datosEnergia_%s_%s_%s.txt", metodo, h, eta, metodo)
output_file = sprintf("../../plots/O2/%s/Energias_Separadas_%s_%s_%s.png", metodo, h, eta, metodo)

# Configuración del terminal 
set terminal pngcairo size 900,600 enhanced font 'Arial,12'
set output output_file

# Configuración del gráfico
set title sprintf("Termalización: Energía Cinética y Potencial - %s (h=%s, {/Symbol h}=%s)", metodo, h, eta)
set xlabel "Tiempo (t)"
set ylabel "Energía"
set grid

# Restringimos el eje Y para ver bien las fluctuaciones alrededor de 0.5
set yrange [0.0:1.0] 
set key top right box opaque

# Definir la recta teórica para Ek y Ep (0.5 kBT)
E_teorica(x) = 0.5

# Dibujar la recta teórica, la cinética (col 2) y la potencial (col 3)
plot E_teorica(x) title "Valor teórico (0.5 k_BT)" with lines dashtype 2 linewidth 2 linecolor rgb "black", \
     input_file using 1:2 title "<E_k>" with lines linewidth 1.5 linecolor rgb "red", \
     input_file using 1:3 title "<E_p>" with lines linewidth 1.5 linecolor rgb "blue"