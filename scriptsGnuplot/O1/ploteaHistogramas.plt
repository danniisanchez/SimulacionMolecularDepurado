# Definición de variables
h = "0.001"
eta = "10"
metodo = "RK2"

# Rutas de entrada y salida
input_file = sprintf("../../results/O1/%s/Histogramas_%s_%s_%s.txt", metodo, h, eta, metodo)
output_file = sprintf("../../plots/O1/%s/Histogramas_%s_%s_%s.png", metodo, h, eta, metodo)

# Configuración del terminal 
set terminal pngcairo size 1200,600 enhanced font 'Arial,12'
set output output_file

# Activar multiplot con 1 fila y 2 columnas
set multiplot layout 1,2 title sprintf("Distribuciones - %s (h=%s, {/Symbol h}=%s)", metodo, h, eta) font ",14"

# --- Constantes del sistema ---
K = 1.0
M = 1.0
KBT = 1.0  

# ==========================================
# PLOT 1: POSICIONES (Izquierda)
# ==========================================
set title "Distribución de Posiciones"
set xlabel "Posición (x)"
set ylabel "P(x)"
set grid
set style fill solid 0.5 border -1

# Distribución teórica de Boltzmann P(x)
P_teorica_x(x) = sqrt(K / (2.0 * pi * KBT)) * exp(-(0.5 * K * x**2) / KBT)

# Ancho de bin usando la columna 1 (x_centro)
stats input_file using 1 nooutput
bin_pos = (STATS_max - STATS_min) / (STATS_records - 1)

# Dibujar el histograma de posiciones (columnas 1 y 2)
plot input_file using 1:2:(bin_pos) title "Simulación" with boxes linecolor rgb "blue", \
     P_teorica_x(x) title "Teórica" with lines linewidth 2 linecolor rgb "black"

# ==========================================
# PLOT 2: VELOCIDADES (Derecha)
# ==========================================
set title "Distribución de Velocidades"
set xlabel "Velocidad (v)"
set ylabel "P(v)"

# Distribución teórica de Boltzmann P(v)
P_teorica_v(x) = sqrt(M / (2.0 * pi * KBT)) * exp(-(0.5 * M * x**2) / KBT)

# Ancho de bin usando la columna 3 (v_centro)
stats input_file using 3 nooutput
bin_vel = (STATS_max - STATS_min) / (STATS_records - 1)

# Dibujar el histograma de velocidades (columnas 3 y 4)
plot input_file using 3:4:(bin_vel) title "Simulación" with boxes linecolor rgb "red", \
     P_teorica_v(x) title "Teórica" with lines linewidth 2 linecolor rgb "black"

# Desactivar multiplot
unset multiplot