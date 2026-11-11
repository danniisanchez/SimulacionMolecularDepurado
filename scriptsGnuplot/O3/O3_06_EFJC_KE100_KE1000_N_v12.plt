reset
if(!exists("N")) N=64

f100=sprintf("../../results/O3/ree_vs_fuerza_N%d_KE100.dat",N)
f1000=sprintf("../../results/O3/ree_vs_fuerza_N%d_KE1000.dat",N)
salida=sprintf("../../plots/O3/N%d/EFJC_KE100_vs_KE1000_N%d.png",N,N)

b=1.0
KBT=1.0
L0=(N-1)*b

Langevin(z)=(abs(z)<1e-8) ? z/3.0 : 1.0/tanh(z)-1.0/z
FJC(F)=L0*Langevin(F*b/KBT)

# Se ajusta un Keff independiente a cada conjunto, pero con EL MISMO eje F.
K100=100.0
K1000=1000.0
EFJC100(F)=(N-1)*(b*Langevin(F*b/KBT)+F/K100)
EFJC1000(F)=(N-1)*(b*Langevin(F*b/KBT)+F/K1000)

fit [0.03:*] EFJC100(x) f100 using 1:($7==1 ? $2 : 1/0) via K100
fit [0.03:*] EFJC1000(x) f1000 using 1:($7==1 ? $2 : 1/0) via K1000

HF100(F)=(N-1)*(b+F/K100)
HF1000(F)=(N-1)*(b+F/K1000)

set terminal pngcairo size 1550,1100 enhanced font "Arial,14"
set output salida
set multiplot layout 2,1 title sprintf("O3 - Misma fuerza, distinta rigidez de enlace; N=%d",N)
set border linewidth 1.3
set tics out
set grid back
set key top left

set xlabel "F"
set ylabel "<R_{ee,parallel}>"
set title sprintf("Rango completo: K_{eff}=%.4g (KE=100), %.4g (KE=1000)",K100,K1000)
plot f100 u 1:($7==1 ? $2 : 1/0) w p pt 7 ps 1.3 title "Sim. KE=100", \
     f1000 u 1:($7==1 ? $2 : 1/0) w p pt 5 ps 1.3 title "Sim. KE=1000", \
     EFJC100(x) w l lw 2 title "EFJC fit KE=100", \
     EFJC1000(x) w l lw 2 title "EFJC fit KE=1000", \
     FJC(x) w l lw 2 dt 2 title "FJC inextensible"

set xlabel "F"
set ylabel "<R_{ee,parallel}> / [(N-1)b]"
set xrange [0:200]
set title "La diferencia aparece por extensibilidad, no por desplazar el barrido"
plot f100 u 1:($7==1 ? $2/L0 : 1/0) w p pt 7 ps 1.3 title "KE=100", \
     f1000 u 1:($7==1 ? $2/L0 : 1/0) w p pt 5 ps 1.3 title "KE=1000", \
     EFJC100(x)/L0 w l lw 2 title "EFJC KE=100", \
     EFJC1000(x)/L0 w l lw 2 title "EFJC KE=1000"

unset multiplot
unset output

set print sprintf("../../results/O3/ajuste_EFJC_KEcomparacion_N%d.txt",N)
print sprintf("N=%d",N)
print sprintf("Keff fit para KE=100  : %.12g",K100)
print sprintf("Keff fit para KE=1000 : %.12g",K1000)
print sprintf("Cociente Keff1000/Keff100 = %.12g",K1000/K100)
print "Ambos ajustes usan exactamente el mismo conjunto de fuerzas."
print "Modelo: Ree_parallel=(N-1)[b L(Fb/kBT)+F/Keff]."
print "Alta fuerza: pendiente dRee/dF ~ (N-1)/Keff."
set print
