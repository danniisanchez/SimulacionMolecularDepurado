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
#define F_ext 0.0
#define TERM_STEPS 10000000L
#define MEASURE_STEPS 20000000L
#define SAMPLE_EVERY 100L
#define SEED 89886523
#define PI (2.0 * asin(1.0))
#define NORM_RANU (2.3283063671E-10F)

typedef struct { double x, y, z; } Vec3;
typedef struct { Vec3 r, v; } Bead;

extern unsigned int irr[256];
extern unsigned int ir1;
extern unsigned char ind_ran, ig1, ig2, ig3;

float Random(void);
float randomIn(double min, double max);
void ini_ran(int SEMILLA);
double random_gaussiano(void);

void inicializa_cadena(Bead *beads, int N);
void calcula_fuerzas(const Bead *beads, Vec3 *f, int N);
double energia_potencial(const Bead *beads, int N);
double energia_cinetica(const Bead *beads, int N);
double distancia_extremo_extremo(const Bead *beads, int N);
double ree_direccion_fuerza(const Bead *beads, int N);
double radio_giro(const Bead *beads, int N);
double longitud_media_enlace(const Bead *beads, int N);

void paso_verlet_gjf(Bead *beads, int N, Vec3 *f_old, Vec3 *f_new, Vec3 *beta);

int asegura_directorios(int N);
void guarda_snapshot(const Bead *beads, int N);

#endif




