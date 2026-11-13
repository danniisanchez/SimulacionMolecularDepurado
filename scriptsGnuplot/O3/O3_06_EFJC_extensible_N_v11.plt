reset
if(!exists("N")) N=64
archivo=sprintf("../../results/O3/ree_vs_fuerza_N%d.dat",N)
salida=sprintf("../../plots/O3/N%d/EFJC_Ree_vs_F_N%d.png",N,N)

b=1.0
KBT=1.0
KE_code=100.0
L0=(N-1)*b

Langevin(z)=(abs(z)<1e-8) ? z/3.0 : 1.0/tanh(z)-1.0/z
FJC(F)=L0*Langevin(F*b/KBT)

# Extensible FJC:
# orientación FJC + elongación Hookeana F/Keff por enlace.
Keff=100.0
EFJC(F)= (N-1)*( b*Langevin(F*b/KBT) + F/Keff )

# Ajustamos solo Keff; b y kBT son parámetros conocidos del código.
fit [0.03:*] EFJC(x) archivo u 1:($7==1 ? $2 : 1/0) via Keff

HighF(F)=(N-1)*(b+F/Keff)

set terminal pngcairo size 1500,1050 enhanced font "Arial,14"
set output salida
set multiplot layout 2,1 title sprintf("O3 - Fuerza-extension, N=%d; K_eff fit=%.4g (K_E codigo=100)",N,Keff)
set border linewidth 1.3
set tics out
set grid back
set key top left

set xrange [0:50]
set xlabel "F"; set ylabel "<R_{ee,parallel}>"
set title "Rango completo: FJC ideal frente a FJC extensible"
plot archivo u 1:($7==1 ? $2 : 1/0) w p pt 7 ps 1.35 title "Simulacion convergida", \
     archivo u 1:($7==0 ? $2 : 1/0) w p pt 5 ps 1.35 title "No convergida", \
     FJC(x) w l lw 2 dt 2 title "FJC ideal", \
     EFJC(x) w l lw 2 title "EFJC ajustada", \
     HighF(x) w l lw 2 dt 3 title "Limite lineal fuerte"

set xrange [0:10]
set xlabel "F"; set ylabel "<R_{ee,parallel}> / [(N-1)b]"
set title "Regimen FJC y comienzo de extensibilidad"
plot archivo u 1:($7==1 ? $2/L0 : 1/0) w p pt 7 ps 1.35 title "Simulacion", \
     FJC(x)/L0 w l lw 2 dt 2 title "Langevin", \
     EFJC(x)/L0 w l lw 2 title "Langevin + F/(K_eff b)"
unset multiplot
unset output

set print sprintf("../../results/O3/ajuste_EFJC_N%d.txt",N)
print sprintf("N=%d",N)
print sprintf("Keff ajustado = %.12g",Keff)
print "KE del codigo = 100"
print "Modelo: Ree_parallel=(N-1)[b L(Fb/kBT)+F/Keff]"
print "Limite F grande: Ree_parallel ~ (N-1)(b+F/Keff), salvo correccion -kBT/F."
set print
