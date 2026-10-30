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

/* Limites duros; la parada real es adaptativa. */
#define termSteps 100000000L
#define numberSteps 100000000L

/* Termalizacion adaptativa */
#define TERM_MIN_STEPS 1000000L
#define TERM_MAX_STEPS termSteps
#define TERM_BLOCK_STEPS 200000L
#define TERM_STABLE_BLOCKS 4
#define TERM_TOL_EK 0.05
#define TERM_TOL_EP 0.05
#define TERM_TOL_X2 0.05
#define TERM_TOL_EK_THEORY 0.10

/* Medida adaptativa */
#define MEASURE_MIN_STEPS 5000000L
#define MEASURE_MAX_STEPS numberSteps
#define MIN_ESTANCIAS_TOTAL 300L
#define MIN_ESTANCIAS_POR_POZO 100L
#define MEASURE_CHECK_EVERY 10000L

/* Salida: maximo aproximado de 100000 puntos por trayectoria */
#define numDatosGuardar 100000L
#define guardar_cada ((MEASURE_MAX_STEPS/numDatosGuardar)>0 ? \
                      (MEASURE_MAX_STEPS/numDatosGuardar) : 1L)

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















