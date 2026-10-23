O3 - VOLUMEN EXCLUIDO WCA
=========================

Modelo añadido
--------------
Para pares no enlazados |i-j|>1:

V_WCA(r) =
    4 epsilon [(sigma/r)^12-(sigma/r)^6] + epsilon,
    si r < 2^(1/6) sigma

    0,
    si r >= 2^(1/6) sigma

Parámetros por defecto:
    EPSILON_EV = 1
    SIGMA_EV   = 1

Con kBT=1:
    epsilon_EV / kBT = 1

Selector:
    USE_EXCLUDED_VOLUME = 0 -> desactivado
    USE_EXCLUDED_VOLUME = 1 -> WCA activado

El módulo es independiente de:
    BENDING_MODEL = 0, 1 o 2

Por tanto después puede usarse:
    flexible + WCA
    bending armonico + WCA
    WLC + WCA

Nuevos observables
------------------
    Eev       = energia WCA
    dmin      = distancia minima entre beads no enlazadas

Automatización
--------------
barrido_volumen_excluido_O3.ps1

Compara cadena ideal y WCA para:
    N = 4, 8, 16, 32, 64

Para aislar EV fuerza automáticamente:
    BENDING_MODEL = 0
    F_ext = 0

Genera:
    results/O3/excluded_ideal_sizes.dat
    results/O3/excluded_WCA_sizes.dat

Gráficas principales
--------------------
O3_EV01_Rg_Ree_vs_N.plt
O3_EV02_ley_escala_Rg.plt
O3_EV03_diagnosticos_WCA.plt

La comparación de escala usa:
    Rg_rms = sqrt(<Rg^2>) ~ (N-1)^nu

Referencia física:
    cadena ideal: nu ~ 1/2
    self-avoiding walk 3D asintótico: nu ~ 0.588

Con N <= 64 no debe exigirse obtener exactamente 0.588:
hay fuertes correcciones de tamaño finito.
