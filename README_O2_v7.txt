O2 v7 — termalización local + mezcla global + calidad estadística

INSTALACION
1. Copiar:
   main_O2_v7.c       -> src/main.c
   head_O2_v7.h       -> src/head.h
   funciones_O2_v7.c -> src/funciones.c
   Mantener tu src/random.c.

2. Copiar TODOS los .plt de scriptsGnuplot_O2_v7/ a:
   scriptsGnuplot/O2/

3. Copiar O2_master_v7_calidad.ps1 a la raíz del proyecto.

4. Ejecutar:
   .\O2_master_v7_calidad.ps1

Para regenerar únicamente figuras desde datos ya existentes:
   .\O2_master_v7_calidad.ps1 -SoloGraficas

CAMBIOS FISICOS PRINCIPALES

A) Termalización local:
   - bloques de 1,000,000 pasos;
   - compara <Ek>, <V> y <x^2> entre bloques;
   - exige <Ek> próximo a kBT/2;
   - exige 3 bloques locales consecutivos estables.

B) Mezcla global durante termalización:
   - calcula P_izq teorica integrando exp[-V(x)/kBT];
   - por tanto F=0 exige aproximadamente 1/2, pero F!=0 usa la ocupación
     de Boltzmann correspondiente al potencial inclinado;
   - exige |P_izq - P_izq_teoria| < 0.04;
   - exige al menos 20 transiciones confirmadas con histéresis XC=0.2.
   - la termalización SOLO termina si A y B se cumplen simultáneamente.

C) Medida:
   - mínimo 600 estancias completas totales y 200 por pozo;
   - |P_izq - P_izq_teoria| < 0.03;
   - error relativo estimado de tau_izq y tau_der < 8%;
   - si no se alcanza la calidad, continúa hasta el máximo y marca
     stats_converged=0 en lugar de fingir convergencia.

D) Límites adaptativos:
   - termalización máxima: 150,000,000 pasos;
   - medida máxima: 300,000,000 pasos;
   - son límites de seguridad, no tiempos fijos: los casos fáciles paran antes.
   - guardar_cada=1000, desacoplado del límite máximo para no degradar
     la resolución de histogramas en simulaciones que paran pronto.

E) Diagnóstico nuevo:
   - se escribe termalizacion_bloques_*.txt;
   - nueva gráfica plots/O2/Detalles/termalizacion/Termalizacion_*.png
     muestra medias energéticas por bloque y P_izq frente a Boltzmann.

F) Histogramas:
   - siguen siendo densidades normalizadas: hist/(N*dx);
   - la curva verde usa su propia normalización Boltzmann;
   - x=+-1 se dibuja ahora como referencia VERTICAL solo para F=0.

COLUMNAS NUEVAS DEL RESUMEN
Las primeras 21 columnas se conservan. Se añaden:
22 Pizq_teoria
23 occ_err_term
24 term_mix_trans
25 occ_err_measure
26 relerr_tau_izq
27 relerr_tau_der
28 term_global_ok

NOTA
Los casos de barrera alta, fricción extrema o fuerza sesgada pueden llegar al
máximo sin cumplir la calidad. Eso no es un fallo del automatizador: se conserva
el resultado, pero stats_converged=0 indica que no debe tratarse como estadística
de alta calidad sin ampliar el muestreo.
