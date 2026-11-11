# O3 - Termalizacion para un N concreto
reset

N = 32
KBT = 1.0

archivo = sprintf("../../results/O3/N%d/termalizacion_N%d.dat",N,N)
salida = sprintf("../../plots/O3/N%d/Termalizacion_N%d.png",N,N)

# Un extremo esta fijo -> 3(N-1) grados de libertad cineticos
Ek_ref = 1.5*(N-1)*KBT

# N-1 enlaces armonicos; referencia usada en la practica
Ebond_ref = 0.5*(N-1)*KBT

set terminal pngcairo size 1000,650 enhanced font "Arial,12"
set output salida

set title sprintf("Termalizacion del polimero, N=%d",N)
set xlabel "Tiempo"
set ylabel "Energia / referencia de equiparticion"
set yrange [0:1.5]
set grid
set key bottom right

# termalizacion_N*.dat:
# 1 t
# 2 <Ek>
# 3 <Ebond>
# 4 <Ebend>
# 5 <Eev>
# 6 Ek_teo
# 7 <Ree>
# 8 <Rg>
# 9 <bond>

plot archivo using 1:($2/Ek_ref) with lines lw 2 title "<Ek>(t) / [3(N-1)kBT/2]", \
     archivo using 1:($3/Ebond_ref) with lines lw 2 title "<Ebond>(t) / [(N-1)kBT/2]", \
     1.0 with lines dt 2 lw 2 title "Referencia"

unset output
