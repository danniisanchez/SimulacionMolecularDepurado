# ==========================================================
# OBJETIVO 2 - DISTRIBUCION DE TIEMPOS DE ESTANCIA
# ==========================================================
#
# Este script:
#
# 1) Lee los tiempos completos de residencia de cada pozo.
# 2) Calcula el tiempo medio con "stats".
# 3) Dibuja histogramas NORMALIZADOS.
# 4) Superpone la distribucion exponencial
#
#       P(tau) = exp(-tau/<tau>) / <tau>
#
#    esperada si los escapes son aproximadamente
#    procesos de Poisson/Kramers.
#
# IMPORTANTE:
# A, eta, h y XC son NUMEROS.
# Solo "metodo" es una cadena.
# Esto evita el error:
#
# f_sprintf: attempt to print numeric value with string format
# ==========================================================


# -----------------------
# PARAMETROS DE LA CORRIDA
# -----------------------

metodo = "Verlet"

h   = 0.001
A   = 1.2
eta = 5.0
XC  = 0.2


# -----------------------
# ARCHIVOS
# -----------------------

archivo_der = sprintf( \
    "../../results/O2/%s/tiempos_derecha_h%g_A%g_eta%g_XC%g.txt", \
    metodo, h, A, eta, XC \
)

archivo_izq = sprintf( \
    "../../results/O2/%s/tiempos_izquierda_h%g_A%g_eta%g_XC%g.txt", \
    metodo, h, A, eta, XC \
)


salida = sprintf( \
    "../../plots/O2/%s/Distribucion_Tiempos_h%g_A%g_eta%g_XC%g.png", \
    metodo, h, A, eta, XC \
)


# -----------------------
# ESTADISTICA
# -----------------------

stats archivo_der using 1 name "DER" nooutput
stats archivo_izq using 1 name "IZQ" nooutput


tau_der = DER_mean
tau_izq = IZQ_mean

n_der = DER_records
n_izq = IZQ_records


print "------------------------------------------"
print sprintf("Metodo = %s", metodo)
print sprintf("h      = %g", h)
print sprintf("A      = %g", A)
print sprintf("eta    = %g", eta)
print sprintf("XC     = %g", XC)
print sprintf("N derecha   = %g", n_der)
print sprintf("N izquierda = %g", n_izq)
print sprintf("<tau> derecha   = %g", tau_der)
print sprintf("<tau> izquierda = %g", tau_izq)
print "------------------------------------------"


# -----------------------
# BINS
# -----------------------
#
# Anchura inicial adaptada al tiempo medio.
# Si quieres mas/menos resolucion, cambia el factor 0.1.
#

tau_ref = 0.5 * (tau_der + tau_izq)

binwidth = 0.1 * tau_ref

if (binwidth <= 0) {
    binwidth = 1.0
}


bin(x,w) = w * floor(x/w) + w/2.0


# -----------------------
# DISTRIBUCIONES TEORICAS
# -----------------------

Pder(x) = \
    (x >= 0 && tau_der > 0) \
    ? exp(-x/tau_der) / tau_der \
    : 1/0


Pizq(x) = \
    (x >= 0 && tau_izq > 0) \
    ? exp(-x/tau_izq) / tau_izq \
    : 1/0


# -----------------------
# FIGURA
# -----------------------

set terminal pngcairo size 1100,700 enhanced font "Arial,13"

set output salida


set title sprintf( \
    "Tiempos de estancia: %s, h=%g, A=%g, eta=%g, XC=%g", \
    metodo, h, A, eta, XC \
)


set xlabel "Tiempo de estancia, tau"

set ylabel "Densidad de probabilidad"


set xrange [0:*]

set logscale y

set grid

set key top right


set style fill transparent solid 0.35 border

set boxwidth binwidth * 0.85


# Histogramas normalizados:
#
# cada observacion pesa 1/(N*binwidth),
# por lo que el area del histograma es aproximadamente 1.

plot \
    archivo_der \
        using (bin($1,binwidth)):(1.0/(n_der*binwidth)) \
        smooth freq \
        with boxes \
        title sprintf("Derecha, N=%g",n_der), \
    \
    archivo_izq \
        using (bin($1,binwidth)):(1.0/(n_izq*binwidth)) \
        smooth freq \
        with boxes \
        title sprintf("Izquierda, N=%g",n_izq), \
    \
    Pder(x) \
        with lines linewidth 2 \
        title sprintf("Exp derecha, <tau>=%.3g",tau_der), \
    \
    Pizq(x) \
        with lines linewidth 2 \
        title sprintf("Exp izquierda, <tau>=%.3g",tau_izq)


unset output

print sprintf("Figura guardada en: %s", salida)
