reset
if(!exists("N")) N=64
archivo=sprintf("../../results/O3/ree_vs_fuerza_N%d.dat",N)
salida=sprintf("../../plots/O3/N%d/EFJC_Ree_vs_F_log_N%d.png",N,N)
b=1.0; KBT=1.0; L0=(N-1)*b
Langevin(z)=(abs(z)<1e-8) ? z/3.0 : 1.0/tanh(z)-1.0/z
Keff=100.0
EFJC(F)=(N-1)*(b*Langevin(F*b/KBT)+F/Keff)
fit [0.03:*] EFJC(x) archivo u 1:($7==1 ? $2 : 1/0) via Keff

set terminal pngcairo size 1500,900 enhanced font "Arial,14"
set output salida
set border linewidth 1.3
set tics out
set grid back
set logscale x
set xrange [0.009:55]
set xlabel "F"
set ylabel "<R_{ee,parallel}>"
set title sprintf("O3 - Fuerza-extension en escala logaritmica, N=%d",N)
plot archivo u 1:($1>0 && $7==1 ? $2 : 1/0) w p pt 7 ps 1.35 title "Simulacion", \
     EFJC(x) w l lw 2 title sprintf("EFJC, K_eff=%.4g",Keff)
unset output
