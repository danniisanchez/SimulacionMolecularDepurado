# O3 - Ley de escala del radio de giro
# Ejecutar desde scriptsGnuplot/O3
#
# resumen_tamanos.dat:
# 1 N, 9 <Rg^2>
reset

archivo = "../../results/O3/resumen_tamanos.dat"
salida  = "../../plots/O3/Ley_escala_Rg.png"

b0 = 1.0

# Rg_rms = C (N-1)^nu
nu = 0.5
logC = log(b0/sqrt(6.0))
f(x) = logC + nu*x

fit f(x) archivo using (log($1-1)):(log(sqrt($9))) via logC,nu

C = exp(logC)
Rg_fit(N) = C*(N-1)**nu
Rg_ideal(N) = b0*sqrt((N*N-1.0)/(6.0*N))

set terminal pngcairo size 1050,850 enhanced font "Arial,12"
set output salida
set multiplot layout 2,1 title "Objetivo 3 - Ley de escala del radio de giro"

set title sprintf("Radio de giro frente al tamano; ajuste: nu = %.4f",nu)
set xlabel "Numero de beads, N"
set ylabel "R_{g,rms} = sqrt(<R_g^2>)"
set grid
set key top left

plot archivo using 1:(sqrt($9)) with points pt 7 ps 1.3 title "Simulacion", \
     Rg_fit(x) with lines lw 2 title sprintf("Ajuste C(N-1)^{nu}, nu=%.3f",nu), \
     Rg_ideal(x) with lines lw 2 dt 2 title "FJC ideal (referencia finita)"

set title "Representacion log-log"
set xlabel "log(N-1)"
set ylabel "log(R_{g,rms})"
set grid
set key top left

plot archivo using (log($1-1)):(log(sqrt($9))) with points pt 7 ps 1.3 title "Datos", \
     f(x) with lines lw 2 title sprintf("Ajuste lineal: pendiente = %.4f",nu)

unset multiplot
unset output

print sprintf("nu ajustado = %.8g",nu)
print sprintf("C ajustado  = %.8g",C)
print sprintf("nu ideal FJC = 0.5")
print sprintf("Figura guardada en: %s",salida)
