O3 - COMPARACION BENDING ARMONICO vs WLC
==========================================

Selector:
    BENDING_MODEL = 0  -> sin bending
    BENDING_MODEL = 1  -> armonico
    BENDING_MODEL = 2  -> Worm-Like Chain (WLC)

Potenciales:
    Armonico:
        V = 1/2 K (theta-theta0)^2

    WLC:
        V = K [1-cos(theta-theta0)]

En esta practica se usa theta0=0, por lo que la cadena localmente recta
corresponde a theta=0.

Para theta pequeno:
    1-cos(theta) ~ theta^2/2

por tanto, para el mismo K, ambos modelos deben aproximarse cuando
las fluctuaciones angulares son pequenas.

El PowerShell:
    barrido_comparacion_armonico_WLC.ps1

ejecuta para ambos modelos:
    K = 0, 0.1, 0.25, 0.5, 1, 2, 5, 10, 20, 50

con:
    N = 64
    F_ext = 0

y genera:
    results/O3/bending_armonico_N64.dat
    results/O3/bending_WLC_N64.dat

Columnas:
    1 K
    2 <Ree>
    3 <Rg>
    4 <Ebond>
    5 <Ebend>
    6 <theta>
    7 <cos(theta)>
    8 <longitud_enlace>
    9 muestras

Scripts Gnuplot:
    O3_W01_compara_Rg_Ree.plt
    O3_W02_compara_angulos.plt
    O3_W03_compara_energias.plt

La implementacion de fuerza de ambos modelos fue contrastada numericamente
contra -grad(V) en una configuracion 3D no trivial antes de empaquetarla.
