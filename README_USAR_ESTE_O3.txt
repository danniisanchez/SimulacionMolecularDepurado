O3 v12 — paquete unificado limpio
=================================

ESTE ES EL PAQUETE QUE DEBES USAR.

Ya no hay que elegir entre main v11/v12 ni entre automatizadores antiguos.

NÚCLEO ÚNICO
------------
Los archivos definitivos están ya con el nombre que deben tener:

  srcO3/main.c
  srcO3/head.h
  srcO3/funciones.c
  srcO3/random.c

Son las versiones v12.

AUTOMATIZADOR ÚNICO
-------------------
Desde la raíz:

  .\O3_master_unificado_v12.ps1

abre un menú con:
  1) barrido de tamaños N=4,8,16,32,64
  2) barrido de fuerza para un N
  3) fuerza para todos los N
  4) regenerar gráficas

También puede usarse sin menú:

  .\O3_master_unificado_v12.ps1 -Modo tamanos -ReusarExistentes
  .\O3_master_unificado_v12.ps1 -Modo fuerza -N 16 -ReusarExistentes
  .\O3_master_unificado_v12.ps1 -Modo fuerzas-todos -ReusarExistentes
  .\O3_master_unificado_v12.ps1 -Modo graficas

El modo fuerza ejecuta automáticamente KE=100 y KE=1000 con EXACTAMENTE el
mismo conjunto de fuerzas:
  0, 0.03, 0.1, 0.3, 0.5, 1, 2, 3, 5, 10, 20, 50, 100, 200.

Los scripts de _internos/ son auxiliares del master. No necesitas lanzarlos
manualmente.

QUÉ INCLUYE
-----------
- termalización larga y adaptativa;
- todos los N = 4,8,16,32,64;
- equipartición;
- Ree y Rg frente a N;
- ajuste R=C(N-B)^nu con B libre y comparación B=1;
- comparación con FJC ideal;
- FJC extensible;
- KE=100 vs KE=1000 usando el mismo F;
- Gnuplot enhanced;
- gráficas por N y gráficas globales.

IMPORTANTE
----------
Ignora/elimina de tu carpeta de trabajo los antiguos:
  main_O3_v11.c
  head_O3_v11.h
  funciones_O3_v11.c
  random_O3_v11.c
  barrido_fuerza_O3_v11.ps1

y cualquier copia previa de main/head que no esté en srcO3 con estos nombres.

La única entrada de usuario debe ser:
  O3_master_unificado_v12.ps1
