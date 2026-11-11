reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Ley_escala_NmenosB.png"

# Ajustes no lineales: R = C (N-B)^nu.
# B se inicia en 1 y se deja libre. Con 5 tamanos, se informa tambien
# del ajuste restringido B=1 para comprobar estabilidad.
C_rg=0.4; nu_rg=0.5; B_rg=1.0
C_ree=1.0; nu_ree=0.5; B_ree=1.0
frg(x)=C_rg*(x-B_rg)**nu_rg
free(x)=C_ree*(x-B_ree)**nu_ree

FIT_LIMIT=1e-10
fit frg(x) archivo u 1:(sqrt($9)) via C_rg,nu_rg,B_rg
fit free(x) archivo u 1:(sqrt($7)) via C_ree,nu_ree,B_ree

# Restricción físicamente motivada por el número de enlaces N-1.
C_rg1=0.4; nu_rg1=0.5
C_ree1=1.0; nu_ree1=0.5
frg1(x)=C_rg1*(x-1.0)**nu_rg1
free1(x)=C_ree1*(x-1.0)**nu_ree1
fit frg1(x) archivo u 1:(sqrt($9)) via C_rg1,nu_rg1
fit free1(x) archivo u 1:(sqrt($7)) via C_ree1,nu_ree1

RgExact(N)=sqrt((N*N-1.0)/(6.0*N))
ReeExact(N)=sqrt(N-1.0)

set terminal pngcairo size 1550,1100 enhanced font "Arial,14"
set output salida
set multiplot layout 2,2 title "O3 - Ley de escala: R = C (N-B)^{nu}"
set border linewidth 1.3
set tics out
set grid back
set key top left

set xlabel "N"; set ylabel "R_{g,rms}"
set title sprintf("R_g: nu=%.4f, B=%.4f",nu_rg,B_rg)
plot archivo u 1:(sqrt($9)) w p pt 7 ps 1.5 title "Datos", \
     frg(x) w l lw 2 title "C(N-B)^{nu}", \
     frg1(x) w l lw 2 dt 2 title sprintf("B=1: nu=%.4f",nu_rg1), \
     RgExact(x) w l lw 2 dt 3 title "FJC finita exacta"

set xlabel "N"; set ylabel "R_{ee,rms}"
set title sprintf("R_ee: nu=%.4f, B=%.4f",nu_ree,B_ree)
plot archivo u 1:(sqrt($7)) w p pt 7 ps 1.5 title "Datos", \
     free(x) w l lw 2 title "C(N-B)^{nu}", \
     free1(x) w l lw 2 dt 2 title sprintf("B=1: nu=%.4f",nu_ree1), \
     ReeExact(x) w l lw 2 dt 3 title "FJC exacta"

set xlabel "log(N-B_{fit})"; set ylabel "log R_g"
set title "R_g: comprobacion log-log con B ajustado"
plot archivo u (log($1-B_rg)):(log(sqrt($9))) w p pt 7 ps 1.5 title "Datos", \
     log(C_rg)+nu_rg*x w l lw 2 title sprintf("pendiente nu=%.4f",nu_rg)

set xlabel "log(N-B_{fit})"; set ylabel "log R_{ee}"
set title "R_ee: comprobacion log-log con B ajustado"
plot archivo u (log($1-B_ree)):(log(sqrt($7))) w p pt 7 ps 1.5 title "Datos", \
     log(C_ree)+nu_ree*x w l lw 2 title sprintf("pendiente nu=%.4f",nu_ree)

unset multiplot
unset output

set print "../../results/O3/ajuste_nu_NmenosB.txt"
print "Modelo: R = C (N-B)^nu"
print sprintf("Rg libre:  C=%.12g  nu=%.12g  B=%.12g",C_rg,nu_rg,B_rg)
print sprintf("Rg B=1:    C=%.12g  nu=%.12g",C_rg1,nu_rg1)
print sprintf("Ree libre: C=%.12g  nu=%.12g  B=%.12g",C_ree,nu_ree,B_ree)
print sprintf("Ree B=1:   C=%.12g  nu=%.12g",C_ree1,nu_ree1)
print "Ideal FJC asintotica: nu=0.5; numero natural de pasos=N-1 -> B=1."
set print
