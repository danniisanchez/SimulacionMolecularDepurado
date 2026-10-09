# ==============================================================
# SCRIPT COMBINADO: x(t), v(t) y Espacio de Fases (Ejes ajustados)
# ==============================================================

# Variables del sistema y método
metodo = "RK2"
h = "0.001"
eta = "10"

# Límite de puntos a representar 
max_lineas = 3000

# Tiempo máximo para ajustar el eje X (cada línea guardada avanza 0.1)
t_max = max_lineas * 0.1

# Archivo de datos de entrada
archivo = sprintf("../../results/O1/%s/datosTrayectoria_%s_%s_%s.txt", metodo, h, eta, metodo)

# Archivo de salida
salida = sprintf("../../plots/O1/Trayectorias/Trayectorias_%s_%s_%s.png", h, eta, metodo)

# Configuración del terminal 
set terminal pngcairo size 1400,800 enhanced font "Arial,12"
set output salida

# Iniciar modo multiplot general
set multiplot title sprintf("Análisis del Sistema (%s, h=%s, {/Symbol h}=%s) - Primeros %d pasos", metodo, h, eta, max_lineas) font "Arial,16" offset 0,-1

# ---------------------------------------------------------
# GRÁFICO 1: TRAYECTORIA DE LA POSICIÓN (Arriba Izquierda)
# ---------------------------------------------------------
set origin 0.0, 0.5 
set size 0.5, 0.45  
set title "Trayectoria de la posición"
set xlabel "Tiempo"
set ylabel "x(t)"
set xrange [0:t_max]  # Ajuste exacto del eje temporal
set grid
set key top right
set size noratio
plot archivo every ::0::max_lineas using 1:2 \
     with lines linewidth 1 \
     title "x(t)"

# ---------------------------------------------------------
# GRÁFICO 2: TRAYECTORIA DE LA VELOCIDAD (Abajo Izquierda)
# ---------------------------------------------------------
set origin 0.0, 0.05 
set size 0.5, 0.45  
set title "Trayectoria de la velocidad"
set xlabel "Tiempo"
set ylabel "v(t)"
set xrange [0:t_max]  # Ajuste exacto del eje temporal
set grid
set key top right
set size noratio
plot archivo every ::0::max_lineas using 1:3 \
     with lines linewidth 1 \
     title "v(t)"

# ---------------------------------------------------------
# GRÁFICO 3: DIAGRAMA DE FASES x-v (Derecha, grande y cuadrado)
# ---------------------------------------------------------
set origin 0.5, 0.05 
set size 0.5, 0.90   
set size square      
set title "Espacio de fases"
set xlabel "Posición x"
set ylabel "Velocidad v"
set autoscale x       # Devolvemos el control del eje X a Gnuplot para las posiciones
set grid
unset key
plot archivo every ::0::max_lineas using 2:3 \
     with points pointtype 7 pointsize 0.25

# Finalizar multiplot
unset multiplot