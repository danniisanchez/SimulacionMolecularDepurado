# O3 - Volumen excluido: ley de escala Rg ~ (N-1)^nu

reset

ideal="../../results/O3/excluded_ideal_sizes.dat"
wca="../../results/O3/excluded_WCA_sizes.dat"
salida="../../plots/O3/EV_ley_escala_Rg.png"

# Ajustamos Rg_rms = sqrt(<Rg^2>) = A (N-1)^nu
A0=0.4
nu0=0.5
A1=0.4
nu1=0.58

f0(x)=A0*x**nu0
f1(x)=A1*x**nu1

fit f0(x) ideal using ($1-1):(sqrt($4)) via A0,nu0
fit f1(x) wca   using ($1-1):(sqrt($4)) via A1,nu1

set terminal pngcairo size 1000,700 enhanced font "Arial,12"
set output salida

set logscale xy
set xlabel "N-1"
set ylabel "sqrt(<R_g^2>)"
set title "Ley de escala del radio de giro"
set grid
set key top left

plot ideal using ($1-1):(sqrt($4)) with points pt 7 ps 1.3 title "Ideal", \
     f0(x) with lines lw 2 title sprintf("Fit ideal: nu=%.4f",nu0), \
     wca using ($1-1):(sqrt($4)) with points pt 5 ps 1.3 title "WCA", \
     f1(x) with lines lw 2 title sprintf("Fit WCA: nu=%.4f",nu1)

unset output

print sprintf("nu ideal = %.8f",nu0)
print sprintf("nu WCA   = %.8f",nu1)
print sprintf("Figura guardada en: %s",salida)
