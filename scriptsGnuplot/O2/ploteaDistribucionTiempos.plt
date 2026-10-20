# ==============================
# DISTRIBUCION TIEMPOS ESTANCIA
# ==============================

A = 1
eta = 0.01

set terminal pngcairo size 800,600 enhanced font "Arial,14"

set output sprintf( \
    "../../plots/O2/Verlet/Distribucion_Tiempos_A%g_eta%g.png", \
    A, eta \
)

set title sprintf( \
    "Distribucion de tiempos de estancia (A=%g, eta=%g)", \
    A, eta \
)

set xlabel "Tiempo de estancia"
set ylabel "Frecuencia"

set logscale y
set grid

binwidth = 2.0

bin(x,width) = \
    width * floor(x/width) + width/2.0

set style fill transparent solid 0.5 border -1


archivo_der = sprintf( \
    "../../results/O2/Verlet/tiempos_derecha_A%g_eta%g.txt", \
    A, eta \
)

archivo_izq = sprintf( \
    "../../results/O2/Verlet/tiempos_izquierda_A%g_eta%g.txt", \
    A, eta \
)


plot \
    archivo_der \
    using (bin($1,binwidth)):(1.0) \
    smooth freq \
    with boxes \
    title "Pozo derecho", \
\
    archivo_izq \
    using (bin($1,binwidth)):(1.0) \
    smooth freq \
    with boxes \
    title "Pozo izquierdo"


unset output