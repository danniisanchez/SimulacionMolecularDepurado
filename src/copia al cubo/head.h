#ifndef HEAD_H
#define HEAD_H

#define seed 89886523
#define M 1.0
#define K 1.0

/* Parametros O2 modificados automaticamente por PowerShell */
#define A 0.7
#define FEXT 0.0
#define KBT 0.2

#define PI (2.0*asin(1.0))

#define paso_h 0.001
#define eta 1.0
#define flag 2
#define flag_Objetivo 2

/* Limites duros; la parada real es adaptativa.
 * El master puede sustituirlos caso a caso:
 *   produccion A=0.5: min term=1e8, max term=3e8; min medida=3e8, max medida=1e9
 * (termalizacion / medida).
 */
#define termSteps 300000000L
#define numberSteps 1000000000L

/* Termalizacion adaptativa */
#define TERM_MIN_STEPS 100000000L
#define TERM_MAX_STEPS termSteps
#define TERM_BLOCK_STEPS 1000000L
#define TERM_STABLE_BLOCKS 3
#define TERM_TOL_EK 0.06
#define TERM_TOL_EP 0.06
#define TERM_TOL_X2 0.05
#define TERM_TOL_EK_THEORY 0.08

/* Mezcla global durante termalizacion.
 * La ocupacion se compara con la prediccion de Boltzmann para el mismo FEXT.
 */
#define TERM_MIX_START_STEPS 1000000L
#define TERM_TOL_OCC 0.04
#define TERM_MIN_TRANSITIONS 20L

/* Medida adaptativa */
#define MEASURE_MIN_STEPS 300000000L
#define MEASURE_MAX_STEPS numberSteps
#define MIN_ESTANCIAS_TOTAL 1000L
#define MIN_ESTANCIAS_POR_POZO 400L
#define MEASURE_CHECK_EVERY 500000L
#define MEASURE_TOL_OCC 0.03
#define MEASURE_MAX_RELERR_TAU 0.08

/* Modos de campaña para la revisión de tutoría. */
#define TERM_FIXED_STEPS_MODE 0
#define MEASURE_FORCE_MAX 0

/* Marca de version para que el automatizador no mezcle nucleos. */
#define O2_V8_EXTENDED_SWEEPS 1
#define O2_V9_TUTOR_REVIEW 1
#define O2_V10_MANUAL_ETA_AND_ZOOM 1
#define O2_V11_LONG_PRODUCTION 1

/* Salida. Se desacopla la resolucion del limite maximo:
 * si una simulacion facil para pronto, no pierde resolucion por tener
 * un MEASURE_MAX_STEPS grande.
 */
#define guardar_cada 1000L

/* Ventana de alta resolución para visualizar las oscilaciones locales.
 * La trayectoria larga sigue guardándose cada 1000 pasos.
 * Esta ventana guarda los primeros 50 000 pasos de medida cada 10 pasos:
 *   h=0.001 -> Delta t_zoom=0.01, ventana total t=50.
 * Para A=1 hay ~200 puntos por periodo armónico local.
 */
#define ZOOM_SAVE_EVERY 10L
#define ZOOM_CAPTURE_STEPS 50000L

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define NormRANu (2.3283063671E-10F)

extern unsigned int irr[256];
extern unsigned int ir1;
extern unsigned char ind_ran,ig1,ig2,ig3;

extern float Random(void);
extern void ini_ran(int SEMILLA);
extern float randomIn(double min,double max);

extern void paso_euler_maruyama(double *x,double *p);
extern void paso_rk2_estocastico(double *x,double *p);
extern void paso_verlet(double *x,double *p);
extern double random_gaussiano(void);
extern double energia_cinetica(double p);
extern double energia_potencial(double x);
extern double fuerza(double x);
extern void guardaAleatorios(void);

extern void guardaEnergiasArray(char *nombre_metodo,double h_val,double eta_val,
                                double *t,double *ek,double *ep,long n);
extern void guardaTrayectoriaArray(char *nombre_metodo,double h_val,double eta_val,
                                   double *t,double *x,double *v,long n);
extern void creaHistogramasArray(char *nombre_metodo,double h_val,double eta_val,
                                 double *x,double *v,long n);

#endif
