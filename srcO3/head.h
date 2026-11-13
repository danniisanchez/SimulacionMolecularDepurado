#ifndef HEAD_O3_H
#define HEAD_O3_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define M 1.0
#define KBT 1.0
#define KE 1000.0
#define B0 1.0
#define ETA 1.0
#define H 0.001

/*
 * Compatibilidad:
 * TERM_STEPS y MEASURE_STEPS se mantienen, pero ahora son limites maximos.
 * El programa puede terminar antes si los criterios adaptativos convergen.
 */
#define TERM_STEPS 100000000L
#define MEASURE_STEPS 50000000L
#define SAMPLE_EVERY 100L

/************* TERMALIZACION ADAPTATIVA O3 *************/
/*
 * Minimo base para N=8. main.c lo escala ~N^2 como guia Rouse:
 * N=4,8 -> 5e4; N=16 -> 2e5; N=32 -> 8e5; N=64 -> 3.2e6.
 * Es solo el minimo: la convergencia por bloques decide cuando parar.
 */
#define TERM_MIN_N8 1000000L
#define TERM_MAX_STEPS TERM_STEPS
#define TERM_BLOCK_STEPS 500000L
#define TERM_STABLE_BLOCKS 5

#define TERM_TOL_EK 0.04
#define TERM_TOL_RG 0.04
#define TERM_TOL_REE 0.05
#define TERM_TOL_BOND 0.015
#define TERM_TOL_EK_THEORY 0.08

/************* MEDIDA ADAPTATIVA O3 ********************/
#define MEASURE_MIN_STEPS 5000000L
#define MEASURE_MAX_STEPS MEASURE_STEPS
#define MEASURE_BLOCK_STEPS 500000L
#define MEASURE_MIN_BLOCKS 8

/* Error relativo de la media estimado a partir de medias por bloques. */
#define MEASURE_RELERR_RG 0.03
#define MEASURE_RELERR_REE 0.05

#define O3_V11_TUTOR_REVIEW 1
#define O3_V12_KE_COMPARISON 1

#define F_ext 0.10000000000000001

/* 0 = sin bending, 1 = armonico, 2 = WLC */
#define BENDING_MODEL 0
#define KBEND 0.5
#define THETA0 0.0

/* Volumen excluido WCA entre pares no enlazados |i-j|>1 */
#define USE_EXCLUDED_VOLUME 0
#define EPSILON_EV 1.0
#define SIGMA_EV 1.0

#define SEED 89886523
#define PI (2.0*asin(1.0))
#define NORM_RANU (2.3283063671E-10F)

typedef struct { double x,y,z; } Vec3;
typedef struct { Vec3 r,v; } Bead;

extern unsigned int irr[256];
extern unsigned int ir1;
extern unsigned char ind_ran,ig1,ig2,ig3;

float Random(void);
float randomIn(double min,double max);
void ini_ran(int SEMILLA);
double random_gaussiano(void);

void inicializa_cadena(Bead *beads,int N);
void calcula_fuerzas(const Bead *beads,Vec3 *f,int N);
void calcula_fuerzas_bending(const Bead *beads,Vec3 *f,int N);
void calcula_fuerzas_excluded(const Bead *beads,Vec3 *f,int N);

double energia_potencial(const Bead *beads,int N);
double energia_bending(const Bead *beads,int N);
double energia_excluded(const Bead *beads,int N);
double energia_cinetica(const Bead *beads,int N);

double distancia_extremo_extremo(const Bead *beads,int N);
double ree_direccion_fuerza(const Bead *beads,int N);
double radio_giro(const Bead *beads,int N);
double longitud_media_enlace(const Bead *beads,int N);
double distancia_minima_no_enlazada(const Bead *beads,int N);

double angulo_medio(const Bead *beads,int N);
double cos_angulo_medio(const Bead *beads,int N);

void paso_verlet_gjf(Bead *beads,int N,Vec3 *f_old,Vec3 *f_new,Vec3 *beta);

int asegura_directorios(int N);
void guarda_snapshot(const Bead *beads,int N);

#endif















