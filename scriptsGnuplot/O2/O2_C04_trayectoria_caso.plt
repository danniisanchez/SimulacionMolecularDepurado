reset
if (!exists("VALID")) VALID=0
calidad=(VALID==1)?"VALIDADO":"NO VALIDADO"
if (!exists("datafile")) datafile="../../results/O2/analisis/trayectoria.dat"
if (!exists("outprefix")) outprefix="../../plots/O2/Detalles/trayectorias/Trayectoria_default"
if (!exists("AVAL")) AVAL=1.0
if (!exists("ETAVAL")) ETAVAL=1.0
if (!exists("FVAL")) FVAL=0.0

if (!exists("zoomfile")) zoomfile="../../results/O2/analisis/trayectoria_zoom.dat"
stats datafile using 1 name "T" nooutput
stride=int(T_records/50000.0)+1
if(stride<1) stride=1
dt=(T_records>1)?(T_max-T_min)/(T_records-1):0
zoom_end=(T_min+50.0<T_max)?T_min+50.0:T_max

set border linewidth 1.3
set tics out
set grid back

set terminal pngcairo size 1500,700 enhanced font "Arial,14"
set output sprintf("%s_x_completa.png",outprefix)
set title sprintf("O2 - x(t) completa; A=%g, eta=%g, F=%g [%s]",AVAL,ETAVAL,FVAL,calidad)
set xlabel "t"; set ylabel "x(t)"
set xrange [T_min:T_max]
plot datafile every stride u 1:2 w l lw 1 title "x(t)"
unset output

set output sprintf("%s_v_completa.png",outprefix)
set title sprintf("O2 - v(t) completa; A=%g, eta=%g, F=%g [%s]",AVAL,ETAVAL,FVAL,calidad)
set xlabel "t"; set ylabel "v(t)"
set xrange [T_min:T_max]
plot datafile every stride u 1:3 w l lw 1 title "v(t)"
unset output

set terminal pngcairo size 900,850 enhanced font "Arial,14"
set output sprintf("%s_fase.png",outprefix)
set title sprintf("O2 - Espacio de fases; A=%g, eta=%g, F=%g [%s]",AVAL,ETAVAL,FVAL,calidad)
set xlabel "x"; set ylabel "v"
set size square
plot datafile every stride u 2:3 w p pt 7 ps 0.22 notitle
unset output
set size noratio

set terminal pngcairo size 1500,700 enhanced font "Arial,14"
# OBLIGATORIO: usar ventana de alta resolucion (no se inventan oscilaciones).
# La cadencia real de salida se calcula abajo a partir de los tiempos del archivo zoom.
if (strlen(zoomfile)>0) {
    stats zoomfile using 1 name "Z" nooutput
    zoom_dt=(Z_records>1)?(Z_max-Z_min)/(Z_records-1):0
    set output sprintf("%s_zoom.png",outprefix)
    set xrange [Z_min:Z_max]
    set title sprintf("O2 - Zoom real de x(t); Delta t de salida ~= %.4g",zoom_dt)
    set xlabel "t"; set ylabel "x(t)"
    plot zoomfile u 1:2 w l lw 1.2 title "x(t) alta resolucion"
    unset output
}
