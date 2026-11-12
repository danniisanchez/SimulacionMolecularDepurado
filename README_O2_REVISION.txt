O2 — master y scripts revisados para cerrar tutoría
===================================================

ESTE PAQUETE NO MODIFICA EL NUCLEO C.
Solo sustituye:
  O2_master.ps1
  scriptsGnuplot/O2/*.plt

Cambio principal del automatizador:
al arrancar pregunta:
  "Que valor de A quieres fijar para el barrido de eta"

También puede darse sin interacción:
  .\O2_master.ps1 -Aeta 0.5 -ReusarExistentes
  .\O2_master.ps1 -Aeta 1.0 -ReusarExistentes
  .\O2_master.ps1 -Aeta 2.0 -ReusarExistentes

Cada A se conserva en un fichero independiente:
  results/O2/resumen_eta_A0.5.dat
  results/O2/resumen_eta_A1.dat
  results/O2/resumen_eta_A2.dat

Así no se pisan entre compañeros.

Cambios gráficos:
- tau(eta) en ejes lineales;
- puntos de barridos no unidos;
- ajuste lineal en régimen eta>=1 cuando hay datos convergidos suficientes;
- tau(A): puntos + ajuste exponencial;
- ocupación frente a F en forma logística;
- tau(F): puntos + aproximación exponencial de dos estados;
- fuerza externa incluida en V(x)=A(x^2-1)^2-Fx;
- trayectorias sin corte artificial a 30000 filas;
- x(t), v(t) y espacio de fases en archivos separados;
- zoom por intervalo de tiempo, no por número fijo de líneas;
- Gnuplot pngcairo enhanced y tipografía más legible;
- histogramas muestran número real de bins y anchura de caja;
- tiempos de residencia usan binning adaptativo sqrt(N), no 100 cajas fijas.

IMPORTANTE SOBRE tau(A):
El O2_master.ps1 conserva el array $Avals tal como estaba en el archivo que
subiste (actualmente solo A=0.5). No lo he ampliado automáticamente para evitar
lanzarte muchas simulaciones costosas sin pedirlo.
Para que el ajuste tau(A) tenga sentido, results/O2/resumen_A.dat debe contener
al menos dos A convergidos (idealmente varios). Si vosotros ya estáis repartiendo
los A entre compañeros, combinad esos puntos antes de generar la figura final.

No hace falta cambiar main.c/head.h/funciones.c por estas modificaciones.
