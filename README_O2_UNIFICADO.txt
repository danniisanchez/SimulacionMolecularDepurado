O2 UNIFICADO

Este paquete elimina las incompatibilidades de nombres que existian entre
main.c, funciones.c, PowerShell y los scripts Gnuplot.

NUCLEO A USAR
-------------
Copiar:
  head_O2_unificado.h      -> src/head.h
  main_O2_unificado.c      -> src/main.c
  funciones_O2_unificado.c -> src/funciones.c

Conservar tu src/random.c.

Luego copiar los .plt a:
  scriptsGnuplot/O2/

y O2_master.ps1 a la raiz del repositorio.

EJECUCION
---------
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  .\O2_master.ps1

Opciones:
  .\O2_master.ps1 -SoloGraficas
  .\O2_master.ps1 -SinGraficas
  .\O2_master.ps1 -ReusarExistentes

QUE AUTOMATIZA
--------------
1. Caso de referencia A=0.7, eta=1, F=0:
   - energia durante termalizacion
   - trayectoria x(t), v(t)
   - histograma P(x), P(v)
   - distribuciones de tiempos de residencia

2. Barrido A con eta=1, F=0:
   A = 0.5,0.7,0.9,1.0,1.1,1.2,1.4,1.6,2.0

3. Barrido eta con A=1, F=0:
   eta = 0.01,0.03,0.1,0.3,0.5,1,2,3,5
   Este mismo barrido representa el estudio de turnover de Kramers.

4. Barrido fuerza con A=1, eta=1:
   F = -0.4 ... 0.4

TABLAS CANONICAS
----------------
results/O2/resumen_A.dat
results/O2/resumen_eta.dat
results/O2/resumen_F.dat

Columnas de las tres:
1 parametro (A, eta o F)
2 P_izq
3 P_der
4 transiciones
5 estancias_izq
6 estancias_der
7 tau_izq
8 tau_der
9 tau_global
10 k_sim
11 term_steps
12 measure_steps
13 term_converged
14 stats_converged
15 dEk_term
16 dEp_term
17 dX2_term

CASO DE REFERENCIA
------------------
results/O2/analisis/
  resumen_referencia.txt
  tiempos_derecha.dat
  tiempos_izquierda.dat
  energia.dat
  trayectoria.dat
  histograma.dat
  parametros.dat

NOTAS IMPORTANTES
-----------------
- El potencial y la fuerza son coherentes:
    V(x)=A(x^2-1)^2-FEXT*x
    F(x)=-4A*x*(x^2-1)+FEXT
- Los ficheros de energia, trayectoria e histograma incluyen FEXT en su
  nombre interno para que un barrido de fuerza no sobrescriba resultados.
- Los Gnuplot ya no dependen de tmp_*.dat ni de nombres legacy.
- Los puntos de A grande pueden llegar a MEASURE_MAX_STEPS sin conseguir
  300 estancias. No es un fallo del automatizador: se marca stats_converged=0.
  Esos puntos deben interpretarse con cautela.
- Los archivos tmp_*.dat antiguos pueden eliminarse: ahora son productos
  intermedios obsoletos.
