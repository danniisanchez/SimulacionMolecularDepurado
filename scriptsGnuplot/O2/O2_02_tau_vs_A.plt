reset
archivo="../../results/O2/resumen_A.dat"
salida="../../plots/O2/Dependencia_tau_A.png"

# Ajuste OLS de ln(tau) vs A, solo con 13=14=24=1 y tau>0.
# 'stats' en DOS columnas calcula directamente pendiente/intercepto:
# evita el fit singular de Levenberg-Marquardt y los parametros iniciales nulos.
stats archivo using 1:($13==1 && $14==1 && $24==1 && $9>0 ? log($9) : 1/0) name "S" nooutput
HAS_FIT=(S_records>=3 && S_min_x<S_max_x)
m=0.0
b=0.0
xmin_fit=0.0
xmax_fit=0.0
if (HAS_FIT) {
    m=S_slope
    b=S_intercept
    xmin_fit=S_min_x
    xmax_fit=S_max_x
}
g(x)=m*x+b
f(x)=exp(g(x))
# No dibujar la curva ajustada fuera del intervalo de puntos validados.
trazo(x)=(HAS_FIT && x>=xmin_fit && x<=xmax_fit ? f(x) : 1/0)
trazo_log(x)=(HAS_FIT && x>=xmin_fit && x<=xmax_fit ? g(x) : 1/0)

set terminal pngcairo size 1450,950 enhanced font "Arial,14"
set output salida
set multiplot layout 2,1 title "O2 - Dependencia del tiempo de residencia con la barrera"
set border linewidth 1.3
set tics out
set grid back
set key top left

set xlabel "A"
set ylabel "<tau> global (escala log)"
set logscale y
set title "Dependencia con A; ajuste solo en tramo validado"
plot archivo using 1:($13==1 && $14==1 && $24==1 ? $9 : 1/0) with points pt 7 ps 1.35 title "Validado: TERM=STATS=GLOBAL=1", \
     archivo using 1:(($13==0 || $14==0 || $24==0) ? $9 : 1/0) with points pt 5 ps 1.35 title "No validado (solo referencia)", \
     trazo(x) with lines lw 2 title (HAS_FIT ? sprintf("Ajuste: tau=%.3g exp(%.3g A)",exp(b),m) : "Sin ajuste")

unset logscale y
set xlabel "A"
set ylabel "ln <tau>"
set title sprintf("Comprobacion semilogaritmica%s", HAS_FIT ? sprintf(": pendiente=%.4g",m) : " (datos insuficientes para fit)")
plot archivo using 1:($13==1 && $14==1 && $24==1 && $9>0 ? log($9) : 1/0) with points pt 7 ps 1.35 title "Validado: TERM=STATS=GLOBAL=1", \
     trazo_log(x) with lines lw 2 title "Ajuste lineal"

unset multiplot
unset output
