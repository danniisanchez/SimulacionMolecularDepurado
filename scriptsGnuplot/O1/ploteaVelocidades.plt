# Definición de variables
h = "0.001"
eta = "10"
metodo = "verlet"

# Rutas de entrada y salida
input_file = sprintf("../../results/O1/%s/HistogramaVelocidades_%s_%s_%s.txt", metodo, h, eta, metodo)
output_file = sprintf("../../plots/O1/%s/HistogramaVelocidades_%s_%s_%s.png", metodo, h, eta, metodo)

# Configuración del terminal 
set terminal pngcairo size 900,600 enhanced font 'Arial,12'
set output output_file

# Configuración del gráfico
set title sprintf("Histograma de velocidades - %s (h=%s, {/Symbol h}=%s)", metodo, h, eta)
set xlabel "Velocidad (v)"
set ylabel "P(v)"
set grid
set style fill solid 0.5 border -1

# Distribución teórica de Maxwell-Boltzmann (M = kBT = 1)
M = 1.0
KBT = 1.0
P_teorica(v) = sqrt(M/(2.0*pi*KBT)) * exp(-M*v**2/(2.0*KBT))

# Ancho de bin a partir del rango de v
stats input_file using 1 nooutput
bin = (STATS_max - STATS_min) / (STATS_records - 1)

# Dibujar el histograma y la curva teórica
plot input_file using 1:2:(bin) title "Simulación" with boxes linecolor rgb "red", \
     P_teorica(x) title "Valor teórico" with lines linewidth 2 linecolor rgb "black"