O2 v8 — Barridos ampliados + muestreo adaptativo extendido
===========================================================

INSTALACION
-----------
Copiar:
  main_O2_v8.c       -> src/main.c
  head_O2_v8.h       -> src/head.h
  funciones_O2_v8.c  -> src/funciones.c

Mantener:
  src/random.c

Copiar todos los .plt de scriptsGnuplot_O2_v8/ a:
  scriptsGnuplot/O2/

Colocar O2_master_v8_ampliado.ps1 en la raiz.

EJECUCION
---------
  .\O2_master_v8_ampliado.ps1

Para reutilizar SOLO casos que ya convergieron en las tres condiciones:
  .\O2_master_v8_ampliado.ps1 -ReusarExistentes

La opcion -ReusarExistentes NO reutiliza un caso con:
  term_converged=0, stats_converged=0 o term_global_ok=0.
Lo vuelve a simular con los limites v8.

BARRIDOS
--------
A:
  0.25, 0.35, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2,
  1.3, 1.4, 1.5, 1.6, 1.8, 2.0, 2.2

eta:
  0.005, 0.01, 0.02, 0.03, 0.05, 0.1, 0.2, 0.3, 0.5,
  0.7, 1.0, 1.5, 2.0, 3.0, 5.0, 7.0, 10.0

F:
  -0.50 ... +0.50 en paso 0.05.

LIMITES ADAPTATIVOS POR DIFICULTAD
----------------------------------
NORMAL:
  TERM_MAX    = 2e8
  MEASURE_MAX = 4e8

DIFICIL (A>=1.4 o eta<=0.03 o eta>=5):
  TERM_MAX    = 4e8
  MEASURE_MAX = 9e8

EXTREMO (A>=1.8 o eta<=0.01 o eta>=10):
  TERM_MAX    = 6e8
  MEASURE_MAX = 1.5e9

Estos son LIMITES, no duraciones obligatorias. El programa termina antes
cuando satisface term_converged, term_global_ok y stats_converged.

INTERPRETACION DE F
-------------------
Para V=A(x^2-1)^2-Fx, la desaparicion matematica de un minimo ocurre en:
  |Fcrit| = 8 A / (3 sqrt(3)).

Con A_force=1:
  Fcrit ~= 1.5396.

Por ello F=+-0.5 rompe fuertemente la simetria y sesga las ocupaciones,
pero NO elimina uno de los dos minimos. Esto se conserva asi porque el
barrido solicitado es [-0.5,+0.5] y sigue siendo un doble pozo metastable.

CALIDAD DE LAS GRAFICAS
-----------------------
Las graficas de tau(A) y tau(eta) usan para lineas/ajustes solamente
puntos con stats_converged=1. Los puntos no convergidos se muestran
separados y no contaminan el ajuste.
