//*************DEFINICIONES****************
#define seed 89886523 //semilla parisi
#define M 1.0
#define K 1.0
#define A 1.0
#define KBT 0.2
#define PI (2 * asin(1.0))

#define paso_h 0.001           // paso de integración (0.1, 0.01, 0.001, 0.0001)
#define termSteps 100000000    //el tiempo que este termalizando sera termsteps * paso
#define numberSteps 100000000  //el tiempo que este midiendo sera numbersteps * paso
#define eta 5.0                // fluct 0.1, 1.0, 10.0 (para 2.4 lo voy cambiando a más valores)
#define flag 2                 // 0: Euler, 1: RK2, 2: Verlet
#define flag_Objetivo 2        // 1: Oscilador Armónico (O1), 2: Doble Pozo (O2)
#define numDatosGuardar 100000
#define guardar_cada (numberSteps / numDatosGuardar)  // para 100.000 datos guardar para cada[steps / 100.000]

//*************INCLUDES****************
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

//**********PARISI RAPUANO*************
#define NormRANu (2.3283063671E-10F)

extern unsigned int irr[256];
extern unsigned int ir1;
extern unsigned char ind_ran,ig1,ig2,ig3;

extern float Random(void);
extern void ini_ran(int SEMILLA);
extern float randomIn(double min, double max);

//**************FUNCIONES********************
extern void paso_euler_maruyama(double *x, double *p);
extern void paso_rk2_estocastico(double *x, double *p);
extern void paso_verlet(double *x, double *p);
extern double random_gaussiano(void);
extern double energia_cinetica(double p);
extern double energia_potencial(double x);
extern double fuerza(double x);
extern void guardaAleatorios();

// Nuevas funciones optimizadas con arrays
extern void guardaEnergiasArray(char *nombre_metodo, double h_val, double eta_val, double *t, double *ek, double *ep, long n);
extern void guardaTrayectoriaArray(char *nombre_metodo, double h_val, double eta_val, double *t, double *x, double *v, long n);
extern void creaHistogramasArray(char *nombre_metodo, double h_val, double eta_val, double *x, double *v, long n);