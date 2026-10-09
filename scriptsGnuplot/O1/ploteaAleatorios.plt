# Rutas de entrada y salida
input_file = "../../results/O1/datos_aleatorios.txt"
output_file = "../../plots/O1/Prueba_Aleatoriedad.png"

# Configuracion del terminal 
set terminal pngcairo size 800,800 enhanced font 'Arial,12'
set output output_file

# Configuracion del grafico
set title "Prueba de Aleatoriedad (Generador Parisi-Rapuano)"
set xlabel "Numero aleatorio i"
set ylabel "Numero aleatorio i+1"
set grid

# Forzamos los ejes de 0 a 1 porque la funcion Random() da valores en ese rango
set xrange [0:1]
set yrange [0:1]

# Dibujamos usando puntos muy pequeños para ver la densidad
plot input_file using 1:2 title "Pares (x, y)" with dots linecolor rgb "blue"