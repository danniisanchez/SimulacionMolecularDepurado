reset
if (!exists("AVAL")) AVAL=0.5
if (!exists("FITMIN")) FITMIN=1.0
if (!exists("DOFIT")) DOFIT=1
if (!exists("datafile")) datafile=sprintf("../../results/O2/resumen_eta_A%g.dat",AVAL)
if (!exists("outfile")) outfile=sprintf("../../plots/O2/Tau_vs_eta_A%g_lineal.png",AVAL)

# Agregados: $13=term_converged, $14=stats_converged, $24=term_global_ok.
# Solo la interseccion de esos tres indicadores es un dato validado.
es_validado(tc,sc,go)=(tc==1 && sc==1 && go==1)
# Cuenta filas utiles (incluso cuando no se solicita el ajuste), sin 1/0 en stats.
es_apto(x,tc,sc,go,t)=(es_validado(tc,sc,go) && x>=FITMIN && t>0)
stats datafile using (es_apto($1,$13,$14,$24,$9) ? 1 : 0) name "CN" nooutput
HAS_FIT=(DOFIT && CN_sum>=3)
m=0.0
b=0.0
eta_max_fit=FITMIN
f(x)=m*x+b
if (HAS_FIT) {
    stats datafile using 1:(es_apto($1,$13,$14,$24,$9) ? $9 : 1/0) name "SV" nooutput
    if (SV_min_x>=SV_max_x) {
        HAS_FIT=0
    } else {
        m=SV_slope
        b=SV_intercept
        eta_max_fit=SV_max_x
    }
}
trazo_eta(x)=(HAS_FIT && x>=FITMIN && x<=eta_max_fit ? f(x) : 1/0)

set terminal pngcairo size 1450,950 enhanced font "Arial,14"
set output outfile
set multiplot layout 2,1 title sprintf("O2 - Escape frente a friccion; A=%g, F=0",AVAL)
set grid back
set border linewidth 1.3
set tics out
unset logscale
set xlabel "eta (lineal)"
set ylabel "<tau> global"
set key top left
set title "Puntos de simulacion (sin unir); ajuste local de alta friccion"
plot datafile u 1:(es_validado($13,$14,$24) ? $9 : 1/0) w p pt 7 ps 1.3 title "Datos validados", \
     datafile u 1:(!es_validado($13,$14,$24) ? $9 : 1/0) w p pt 2 ps 1.3 title "Sin convergencia completa", \
     trazo_eta(x) w l lw 2 title (HAS_FIT ? sprintf("Ajuste local eta>=%.3g (N=%d)",FITMIN,int(CN_sum)) : "Sin ajuste: menos de 3 puntos validos")

set xlabel "eta (lineal)"
set ylabel "k_{sim}=1/<tau>"
set title "Tasa de escape, sin unir mediciones"
plot datafile u 1:(es_validado($13,$14,$24) ? $10 : 1/0) w p pt 7 ps 1.3 title "Datos validados", \
     datafile u 1:(!es_validado($13,$14,$24) ? $10 : 1/0) w p pt 2 ps 1.3 title "Sin convergencia completa"
unset multiplot
unset output
