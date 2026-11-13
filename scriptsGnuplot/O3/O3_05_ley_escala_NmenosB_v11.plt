# O3 - Ley de escala, DOS PNG independientes: curva normal y comprobacion ln-ln.
# Se conserva el nombre del script y del PNG normal para compatibilidad.
# Los datos de tamaño contienen <Ree^2> en columna 7 y <Rg^2> en columna 9.
# Las magnitudes representadas son RMS = sqrt(<R^2>), no <R>.
reset
archivo="../../results/O3/resumen_tamanos.dat"
salida="../../plots/O3/Ley_escala_NmenosB.png"
salida_log="../../plots/O3/Ley_escala_NmenosB_loglog.png"
b=1.0

# Mismos ajustes que en la version anterior: no se altera la fisica ni el fit.
C_rg=0.4; nu_rg=0.5; B_rg=1.0
C_ree=1.0; nu_ree=0.5; B_ree=1.0
frg(x)=C_rg*(x-B_rg)**nu_rg
free(x)=C_ree*(x-B_ree)**nu_ree
FIT_LIMIT=1e-10
fit frg(x) archivo using 1:(sqrt($9)) via C_rg,nu_rg,B_rg
fit free(x) archivo using 1:(sqrt($7)) via C_ree,nu_ree,B_ree

# Contraste con B=1 fijo: sigue calculandose y escribiendose en el informe.
C_rg1=0.4; nu_rg1=0.5
C_ree1=1.0; nu_ree1=0.5
frg1(x)=C_rg1*(x-1.0)**nu_rg1
free1(x)=C_ree1*(x-1.0)**nu_ree1
fit frg1(x) archivo using 1:(sqrt($9)) via C_rg1,nu_rg1
fit free1(x) archivo using 1:(sqrt($7)) via C_ree1,nu_ree1

# Cadena ideal FJC de N monomeros y N-1 enlaces de longitud b.
RgExact(x)=b*sqrt((x*x-1.0)/(6.0*x))
ReeExact(x)=b*sqrt(x-1.0)

# Estilo comun: grafica grande a la izquierda y leyenda en caja a la derecha.
set terminal pngcairo size 2200,1120 enhanced font "Arial,18"
set border 15 lw 1.6 lc rgb "#334155"
set tics out nomirror
set grid xtics ytics back lc rgb "#CCD6E2" lw 1 dt 3
set lmargin at screen 0.095
set rmargin at screen 0.665
set bmargin at screen 0.15
set tmargin at screen 0.88
set key outside right top vertical
set key box lw 1.2 lc rgb "#334155"
set key opaque
set key spacing 1.8 samplen 2.7 font ",15"

# ----------------------- PNG 1: tendencia normal -----------------------
set output salida
set title "O3 - Ley de escala N-B: R_g y R_{ee} frente a N" font ",22"
set xlabel "Numero de monomeros, N" font ",18"
set ylabel "Distancia cuadratica media (RMS)" font ",18"
set xrange [0:*]
set yrange [0:*]
plot frg(x) with lines lw 2.7 lc rgb "#6232A3" \
       title sprintf("R_g: C=%.3f, {/Symbol n}=%.4f, B=%.3f",C_rg,nu_rg,B_rg), \
     free(x) with lines lw 2.7 lc rgb "#1279B3" \
       title sprintf("R_{ee}: C=%.3f, {/Symbol n}=%.4f, B=%.3f",C_ree,nu_ree,B_ree), \
     RgExact(x) with lines lw 2.4 dt 3 lc rgb "#9B75D3" \
       title "FJC ideal: R_{g,rms}=b sqrt[(N^2-1)/(6N)]", \
     ReeExact(x) with lines lw 2.4 dt 3 lc rgb "#59ABD2" \
       title "FJC ideal: R_{ee,rms}=b sqrt(N-1)", \
     archivo using 1:(sqrt($9)) with points pt 7 ps 1.7 lc rgb "#6232A3" \
       title "Datos R_g", \
     archivo using 1:(sqrt($7)) with points pt 5 ps 1.7 lc rgb "#1279B3" \
       title "Datos R_{ee}"
unset output

# ----------------------- PNG 2: comprobacion ln-ln --------------------
# Los valores horizontales de R_g y R_ee son distintos porque cada ajuste
# tiene su propio desplazamiento B: ln(N-B_rg) y ln(N-B_ree).
set output salida_log
set title "O3 - Ley N-B: comprobacion logaritmica de ambos ajustes" font ",22"
set xlabel "ln(N - B_{ajustado})" font ",18"
set ylabel "ln(R_{rms})" font ",18"
set xrange [*:*]
set yrange [*:*]
plot log(C_rg)+nu_rg*x with lines lw 2.7 lc rgb "#6232A3" \
       title sprintf("R_g: ln(C)=%.3f, {/Symbol n}=%.4f, B=%.3f", log(C_rg),nu_rg,B_rg), \
     log(C_ree)+nu_ree*x with lines lw 2.7 lc rgb "#1279B3" \
       title sprintf("R_{ee}: ln(C)=%.3f, {/Symbol n}=%.4f, B=%.3f",log(C_ree),nu_ree,B_ree), \
     archivo using ($1>B_rg && $9>0 ? log($1-B_rg) : 1/0):($9>0 ? log(sqrt($9)) : 1/0) \
       with points pt 7 ps 1.7 lc rgb "#6232A3" title "Datos ln(R_g)", \
     archivo using ($1>B_ree && $7>0 ? log($1-B_ree) : 1/0):($7>0 ? log(sqrt($7)) : 1/0) \
       with points pt 5 ps 1.7 lc rgb "#1279B3" title "Datos ln(R_{ee})"
unset output

# El informe numerico de ajustes se conserva igual que antes.
set print "../../results/O3/ajuste_nu_NmenosB.txt"
print "Modelo de ajuste: R_rms = C (N-B)^nu; n=N-1 enlaces"
print sprintf("Rg libre:  C=%.12g  nu=%.12g  B=%.12g",C_rg,nu_rg,B_rg)
print sprintf("Rg B=1:    C=%.12g  nu=%.12g",C_rg1,nu_rg1)
print sprintf("Ree libre: C=%.12g  nu=%.12g  B=%.12g",C_ree,nu_ree,B_ree)
print sprintf("Ree B=1:   C=%.12g  nu=%.12g",C_ree1,nu_ree1)
print "FJC teorica: Ree_rms=b sqrt(N-1), Rg_rms=b sqrt[(N^2-1)/(6N)]"
print "Aviso: con solo 5 tamanos, C/nu/B pueden estar fuertemente correlacionados."
set print
print sprintf("O3 ley de escala normal: %s",salida)
print sprintf("O3 ley de escala log-log: %s",salida_log)
