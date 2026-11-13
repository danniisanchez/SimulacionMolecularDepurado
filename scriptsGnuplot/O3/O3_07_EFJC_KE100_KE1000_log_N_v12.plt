reset
if(!exists("N")) N=64

f100=sprintf("../../results/O3/ree_vs_fuerza_N%d_KE100.dat",N)
f1000=sprintf("../../results/O3/ree_vs_fuerza_N%d_KE1000.dat",N)
salida=sprintf("../../plots/O3/N%d/EFJC_KE100_vs_KE1000_log_N%d.png",N,N)

b=1.0
KBT=1.0
L0=(N-1)*b
Langevin(z)=(abs(z)<1e-8) ? z/3.0 : 1.0/tanh(z)-1.0/z

K100=100.0
K1000=1000.0
E100(F)=(N-1)*(b*Langevin(F*b/KBT)+F/K100)
E1000(F)=(N-1)*(b*Langevin(F*b/KBT)+F/K1000)

fit [0.03:*] E100(x) f100 using 1:($7==1 ? $2 : 1/0) via K100
fit [0.03:*] E1000(x) f1000 using 1:($7==1 ? $2 : 1/0) via K1000

set terminal pngcairo size 1500,900 enhanced font "Arial,14"
set output salida
set border linewidth 1.3
set tics out
set grid back
set logscale x
set xrange [0.009:55]
set xlabel "F"
set ylabel "<R_{ee,parallel}>"
set title sprintf("O3 - KE=100 vs KE=1000 con el mismo barrido de F; N=%d",N)

plot f100 u 1:($1>0 && $7==1 ? $2 : 1/0) w p pt 7 ps 1.3 title "Sim. KE=100", \
     f1000 u 1:($1>0 && $7==1 ? $2 : 1/0) w p pt 5 ps 1.3 title "Sim. KE=1000", \
     E100(x) w l lw 2 title sprintf("EFJC, K_eff=%.4g",K100), \
     E1000(x) w l lw 2 title sprintf("EFJC, K_eff=%.4g",K1000)

unset output
