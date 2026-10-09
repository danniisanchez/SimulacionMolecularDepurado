//*************DEFINICIONES****************
#define seed 89886523 //semilla parisi
#define M 1.0
#define K 1.0
#define A 1.0
#define KBT 0.2
#define PI (2 * asin(1.0))

#define paso_h 0.001           // paso de integración (0.1, 0.01, 0.001, 0.0001)
#define termSteps 100000000      //el tiempo que este termalizando sera termsteps * paso
#define numberSteps 100000000    //el tiempo que este midiendo sera numbersteps * paso
#define eta 10.0           // fluct 0.1, 1.0, 10.0
#define flag 1               // 0: Euler, 1: RK2, 2: Verlet

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
extern void guardaEnergias(FILE *file,double t,double ek,double ep);
extern void guardaPosiciones(FILE *file,double x);
extern void guardaVelocidades(FILE *file,double v);
extern void guardaTrayectoria(FILE *file, double t, double x, double v);
extern void creaHistoPosiciones(char *nombre_metodo);
extern void creaHistoVelocidades(char *nombre_metodo);
extern void guardaAleatorios();
extern double fuerza(double x);