OBJETIVO 3 - PUNTOS i) A v)
===============================

Modelo bead-spring/FJC con enlaces armonicos:
V_i = 1/2 * ke * (|r_{i+1}-r_i| - b)^2  (esto es el pozo para 3D )

Cubre:
i)  fuerzas 3D derivadas del potencial;
ii) dinamica molecular Langevin con Verlet G-JF;
iii) kBT=1, ke=100, b=1;
iv) comprobacion de equiparticion;
v) barrido N=4,8,16,32,64.
vi)
vii)
viii)
ix)
x)
xi)
xii)

Estructura en la raiz del repositorio:
srcO3/
  head.h
  main.c
  funciones.c
  integrador.c
  random.c
scriptsGnuplot/O3/
  O3_01_equiparticion.plt
  O3_02_observables_vs_N.plt
  O3_03_termalizacion.plt
  O3_04_polimero3D.plt
barrido_tamanos_O3.ps1

Uso:
1) Abrir PowerShell en la raiz.
2) Si Windows bloquea scripts en esa sesion:
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
3) Ejecutar:
   .\barrido_tamanos_O3.ps1
   .\barrido_fuerza_Ree_O3.ps1
El codigo se compila una sola vez. El script ejecuta luego:
o3.exe 4
o3.exe 8
o3.exe 16
o3.exe 32
o3.exe 64


esto es por si el powershell no le apetece trabajar
""""
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
"""



Resultados agregados:
results/O3/resumen_tamanos.dat

Columnas:
1 N
2 <Ek>
3 Ek de referencia = 3 N kBT / 2
4 <Ep>
5 Ep armonica de referencia = (N-1) kBT / 2
6 <Ree>
7 <Ree^2>
8 <Rg>
9 <Rg^2>
10 longitud media de enlace
11 numero de muestras
