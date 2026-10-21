# ============================================================
# OBJETIVO 3 - PUNTO vi)
# LEY DE ESCALA DEL RADIO DE GIRO
#
# Usa:
#   ../../results/O3/resumen_tamanos.dat
#
# Columnas esperadas:
# 1  N
# 2  <Ek>
# 3  Ek_teorica
# 4  <Ep>
# 5  Ep_teorica
# 6  <Ree>
# 7  <Ree^2>
# 8  <Rg>
# 9  <Rg^2>
# 10 <longitud_enlace>
# 11 numero_muestras
#
# Ejecutar desde:
#   scriptsGnuplot/O3
# ============================================================

reset

archivo = "../../results/O3/resumen_tamanos.dat"
salida  = "../../plots/O3/Ley_escala_Rg.png"

b0 = 1.0

# Para una cadena ideal:
#       Rg ~ N^nu
# con nu = 1/2.
#
# Trabajamos con:
#       Rg_rms = sqrt(<Rg^2>)
#
# y usamos N-1 como numero de enlaces.

nu = 0.5
logC = log(b0/sqrt(6.0))

# log(Rg_rms) = log(C) + nu*log(N-1)
f(x) = logC + nu*x

fit f(x) archivo using (log($1-1)):(log(sqrt($9))) via logC,nu

C = exp(logC)

Rg_fit(N) = C * (N-1)**nu
Rg_ideal(N) = b0 * sqrt((N*N - 1.0)/(6.0*N))

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida

set multiplot layout 2,1 title "Objetivo 3 - Ley de escala del radio de giro"

# Panel 1
set title sprintf("Radio de giro frente al tamano; ajuste: nu = %.4f", nu)
set xlabel "Numero de beads, N"
set ylabel "R_g,rms = sqrt(<R_g^2>)"
set grid
set key top left

plot archivo using 1:(sqrt($9)) with points pt 7 ps 1.3 title "Simulacion",      Rg_fit(x) with lines lw 2 title sprintf("Ajuste C(N-1)^{nu}, nu=%.3f",nu),      Rg_ideal(x) with lines lw 2 dt 2 title "FJC ideal (formula finita)"

# Panel 2
set title "Representacion log-log"
set xlabel "log(N-1)"
set ylabel "log(R_g,rms)"
set grid
set key top left

plot archivo using (log($1-1)):(log(sqrt($9))) with points pt 7 ps 1.3 title "Datos",      f(x) with lines lw 2 title sprintf("Ajuste lineal: pendiente = %.4f",nu)

unset multiplot
unset output

print "=============================================="
print "OBJETIVO 3 - LEY DE ESCALA DEL RADIO DE GIRO"
print "=============================================="
print sprintf("Exponente ajustado nu = %.8g", nu)
print sprintf("Prefactor C           = %.8g", C)
print sprintf("Referencia FJC ideal  = 0.5")
print sprintf("Diferencia nu-0.5     = %.8g", nu-0.5)
print ""
print "Modelo ajustado:"
print sprintf("Rg_rms = %.8g * (N-1)^(%.8g)", C, nu)
print "=============================================="
print sprintf("Figura guardada en: %s", salida)
