#include "head.h"
#include <stdint.h>

/* Variables globales mantenidas por compatibilidad con head.h */
unsigned int irr[256];
unsigned int ir1;
unsigned char ind_ran, ig1, ig2, ig3;

/* Constantes del generador Ran2 (Numerical Recipes, periodo > 2e18) */
#define IM1  2147483563
#define IM2  2147483399
#define AM   (1.0 / IM1)
#define IMM1 (IM1 - 1)
#define IA1  40014
#define IA2  40692
#define IQ1  53668
#define IQ2  52774
#define IR1  12211
#define IR2  3791
#define NTAB 32
#define NDIV (1 + IMM1 / NTAB)
#define EPS  1.2e-7
#define RNMX (1.0 - EPS)

/* Estado interno del generador Ran2 */
static int32_t idum = 1;
static int32_t idum2 = 123456789;
static int32_t iy = 0;
static int32_t iv[NTAB];
static int ran2_inicializado = 0;

void ini_ran(int SEMILLA)
{
    int32_t s = (int32_t)SEMILLA;
    if (s < 0) s = -s;
    if (s == 0) s = 1;

    idum = s;
    idum2 = idum;

    /* Calentamiento de la tabla de barajado (Bays-Durham) */
    for (int j = NTAB + 7; j >= 0; j--) {
        int32_t k = idum / IQ1;
        idum = IA1 * (idum - k * IQ1) - k * IR1;
        if (idum < 0) idum += IM1;
        if (j < NTAB) iv[j] = idum;
    }
    iy = iv[0];
    ran2_inicializado = 1;
}

float Random(void)
{
    if (!ran2_inicializado) {
        ini_ran(1);
    }

    /* Primer generador congruencial lineal (metodo de Schrage) */
    int32_t k = idum / IQ1;
    idum = IA1 * (idum - k * IQ1) - k * IR1;
    if (idum < 0) idum += IM1;

    /* Segundo generador congruencial lineal */
    k = idum2 / IQ2;
    idum2 = IA2 * (idum2 - k * IQ2) - k * IR2;
    if (idum2 < 0) idum2 += IM2;

    /* Combinacion y barajado */
    int j = (int)(iy / NDIV);
    iy = iv[j] - idum2;
    iv[j] = idum;
    if (iy < 1) iy += IMM1;

    float temp = (float)(AM * iy);
    if (temp > (float)RNMX) return (float)RNMX;
    return temp;
}

float randomIn(double min, double max)
{
    return (float)(min + (max - min) * Random());
}
