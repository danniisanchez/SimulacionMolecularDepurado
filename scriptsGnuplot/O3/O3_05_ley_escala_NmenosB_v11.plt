# O3 Ley de escala con exponente 1/2 FIJO: R_rms=C (N-B)^(1/2).
# Datos: col 7 <Ree^2> y col 9 <Rg^2> - valores RMS.
reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Ley_escala_NmenosB.png"
salida_log="../../plots/O3/Ley_escala_NmenosB_loglog.png"
b=1.0
nu=0.5
C_rg=0.50; B_rg=0.86
C_ree=1.10; B_ree=1.60
RgFit(x)=C_rg*(x-B_rg)**nu
ReeFit(x)=C_ree*(x-B_ree)**nu
FIT_LIMIT=1e-9
fit RgFit(x) archivo using 1:(sqrt($9)) via C_rg,B_rg
fit ReeFit(x) archivo using 1:(sqrt($7)) via C_ree,B_ree
RgExact(x)=b*sqrt((x*x-1.0)/(6.0*x))
ReeExact(x)=b*sqrt(x-1.0)

set terminal pngcairo size 2350,1230 enhanced font "Arial,21"
set border 15 lw 1.8 lc rgb "#303B47"
set tics out nomirror font ",20"
set grid xtics ytics back lc rgb "#D4DDE5" lw 1 dt 3
set lmargin at screen 0.12
set rmargin at screen 0.67
set bmargin at screen 0.14
set tmargin at screen 0.90
set key outside right top vertical
set key box lw 1.3 lc rgb "#303B47"
set key opaque
set key spacing 1.8 samplen 2.4 font ",17"
set output salida
set title "O3 - Ley de escala: R_g y R_{ee}" font ",28"
set xlabel "Numero de monomeros, N" font ",28"
set ylabel "Distancia cuadratica media (RMS)" font ",26"
set xrange [2:66]
set yrange [0:*]
plot RgFit(x) with lines lw 3.2 lc rgb "#0072B2" \
  title sprintf("R_g: C=%.4g, B=%.4g, nu=1/2",C_rg,B_rg), \
 ReeFit(x) with lines lw 3.2 lc rgb "#D55E00" \
  title sprintf("R_{ee}: C=%.4g, B=%.4g, nu=1/2",C_ree,B_ree), \
 RgExact(x) with lines lw 2.6 dt 3 lc rgb "#009E73" \
  title "FJC: R_{g,rms}=b sqrt[(N^2-1)/(6N)]", \
 ReeExact(x) with lines lw 2.6 dt 3 lc rgb "#CC79A7" \
  title "FJC: R_{ee,rms}=b sqrt(N-1)", \
 archivo using 1:(sqrt($9)) with points pt 7 ps 2.3 lc rgb "#0072B2" title "Datos R_g", \
 archivo using 1:(sqrt($7)) with points pt 5 ps 2.6 lc rgb "#D55E00" title "Datos R_{ee}"
unset output

set output salida_log
set title "O3 - Comprobacion logaritmica de la ley de escala" font ",28"
set xlabel "ln(N - B_{ajustado})" font ",28"
set ylabel "ln(R_{rms})" font ",26"
set xrange [*:*]
set yrange [*:*]
plot log(C_rg)+nu*x with lines lw 3.2 lc rgb "#0072B2" \
  title sprintf("R_g: ln(C)=%.3f, B=%.3f, nu=0.5",log(C_rg),B_rg), \
 log(C_ree)+nu*x with lines lw 3.2 lc rgb "#D55E00" \
  title sprintf("R_{ee}: ln(C)=%.3f, B=%.3f, nu=0.5",log(C_ree),B_ree), \
 archivo using ($1>B_rg && $9>0 ? log($1-B_rg):1/0):($9>0?log(sqrt($9)):1/0) \
   with points pt 7 ps 2.3 lc rgb "#0072B2" title "Datos ln(R_g)", \
 archivo using ($1>B_ree && $7>0 ? log($1-B_ree):1/0):($7>0?log(sqrt($7)):1/0) \
   with points pt 5 ps 2.6 lc rgb "#D55E00" title "Datos ln(R_{ee})"
unset output
set print "../../results/O3/ajuste_nu_NmenosB.txt"
print "Ajuste con nu=1/2 FIJO: R_rms=C sqrt(N-B); N=4..64 (11 N previstos)"
print sprintf("Rg:  C=%.12g, B=%.12g, nu=0.5",C_rg,B_rg)
print sprintf("Ree: C=%.12g, B=%.12g, nu=0.5",C_ree,B_ree)
print "FJC: Ree_rms=b sqrt(N-1), Rg_rms=b sqrt[(N^2-1)/(6N)]"
print "Nota: resultados heredados deben ser de la MISMA fisica (F=0 y sin anclaje)."
set print
