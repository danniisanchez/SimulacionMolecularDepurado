# ==============================================================
# O1: Determinacion del metodo y paso  (E - E teorico)
#
# Para cada metodo, h y eta se calcula  <E> - E_teorico  (E_teorico = kBT/2 = 0.5)
# y se representa frente a h. Cuanto mas cerca de 0, mejor.
#   Fila superior : energia cinetica   <Ek> - 0.5
#   Fila inferior : energia potencial  <Ep> - 0.5
#   Columnas      : eta = 0.1, 1, 10
#
# Genera:  results/O1/datos_decision.dat          (unico fichero de datos)
#          plots/O1/Comparativa/Decision_metodo_paso.png
#
# Uso: ejecutar desde scriptsGnuplot/O1  ->  gnuplot decisionMetodoH.plt
# ==============================================================
reset session

# ---------------- PARAMETROS ----------------
metodos = "Euler RK2 Verlet"
hs      = "0.1 0.01 0.001 0.0001"
etas    = "0.1 1 10"
dir_res = "../../results/O1"
dir_out = "../../plots/O1/Comparativa"            # aqui solo se guarda la imagen
fdatos  = "../../results/O1/datos_decision.dat"   # unico fichero de datos
Eteo    = 0.5                  # kBT/2
ymax    = 0.1                  # rango vertical: [-ymax, +ymax]

nm = words(metodos) ; nh = words(hs) ; ne = words(etas)

# ---------------- 1) CALCULO: <E> - E_teorico ----------------
# El fichero guarda el promedio acumulado, asi que el ultimo valor es el promedio total.
# Todo se guarda en UN UNICO fichero (en results/O1).
set print fdatos
print "# eta  n_metodo  metodo  posicion  h  Ek-Eteo  Ep-Eteo"
do for [ie=1:ne] {
  et = word(etas, ie)
  do for [im=1:nm] {
    me = word(metodos, im)
    do for [ih=1:nh] {
      hh = word(hs, ih)
      fE = sprintf("%s/%s/datosEnergia_%s_%s_%s.txt", dir_res, me, hh, et, me)
      stats fE u 1 nooutput ; ni = STATS_records - 1
      stats fE u 2 every ::ni nooutput ; Ek = STATS_mean
      stats fE u 3 every ::ni nooutput ; Ep = STATS_mean
      # posicion en el eje x: h menor a la izquierda, h mayor a la derecha
      print sprintf("%s %d %s %d %s %.6e %.6e", et, im, me, nh-ih+1, hh, Ek-Eteo, Ep-Eteo)
    }
  }
}
unset print

# ---------------- 2) GRAFICA ----------------
set terminal pngcairo size 1800,1050 enhanced font 'Arial,14'
set output sprintf("%s/Decision_metodo_paso.png", dir_out)

set style line 1 lc rgb "#d62728" lw 3 pt 7 ps 1.8     # Euler
set style line 2 lc rgb "#1f77b4" lw 3 pt 5 ps 1.8     # RK2
set style line 3 lc rgb "#2ca02c" lw 3 pt 9 ps 1.8     # Verlet

# eje x categorico: una posicion por cada valor de h (sin escala logaritmica)
set xtics ()
do for [ih=1:nh] { set xtics add (word(hs,ih) nh-ih+1) }
set xrange [0.6:nh+0.4]
set yrange [-ymax:ymax]
set format y "%g"
set grid lc rgb "#dddddd"

set multiplot title "Determinacion del metodo y paso (E-Eteorico)" font ",20"

do for [fila=1:2] {
  do for [ie=1:ne] {
    et = word(etas, ie)
    set origin 0.015+(ie-1)*0.328, (fila==1) ? 0.50 : 0.11
    set size 0.31, 0.40
    if (fila == 1) { set title sprintf("E_k - E_{teorico}    ({/Symbol h} = %s)", et); cd = 6 }
    if (fila == 2) { set title sprintf("E_p - E_{teorico}    ({/Symbol h} = %s)", et); cd = 7 }
    set xlabel "Paso h"
    if (ie == 1) { set ylabel "E - E_{teorico}" } else { unset ylabel }
    unset key
    # columnas del fichero: 1 eta, 2 n_metodo, 3 metodo, 4 posicion, 5 h, 6 Ek-Eteo, 7 Ep-Eteo
    plot 0 w l lc rgb "black" lw 1.5 notitle, \
         fdatos u (($1==et+0 && $2==1) ? $4 : 1/0):(column(cd)) w lp ls 1 notitle, \
         fdatos u (($1==et+0 && $2==2) ? $4 : 1/0):(column(cd)) w lp ls 2 notitle, \
         fdatos u (($1==et+0 && $2==3) ? $4 : 1/0):(column(cd)) w lp ls 3 notitle
  }
}

# ---- leyenda unica, debajo de todo
set origin 0.25, 0.0
set size 0.5, 0.07
unset title ; unset xlabel ; unset ylabel ; unset grid
unset xtics ; unset ytics ; unset border
set xrange [0:1] ; set yrange [0:1]
set key center center horizontal samplen 4 spacing 1.4 font ",16" box lw 1 lc rgb "#999999"
plot 2 w lp ls 1 title "Euler", 2 w lp ls 2 title "RK2", 2 w lp ls 3 title "Verlet"

unset multiplot
unset output
print sprintf("Datos en:   %s", fdatos)
print sprintf("Grafica en: %s/Decision_metodo_paso.png", dir_out)