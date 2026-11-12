#include "head.h"
#include <stdint.h>

/* El estado Parisi-Rapuano usa aritmetica modular de 32 bits.
 * Evitamos desbordamiento de int con signo (comportamiento indefinido en C).
 */
_Static_assert(sizeof(unsigned int) == sizeof(uint32_t),
               "Parisi-Rapuano requiere unsigned int de 32 bits");

unsigned int irr[256];
unsigned int ir1;
unsigned char ind_ran,ig1,ig2,ig3;

float randomIn(double min, double max) {
    return (float)(min + (max - min) * Random());
}

float Random(void)
{
    float r;
    ig1=ind_ran-24;
    ig2=ind_ran-55;
    ig3=ind_ran-61;
    irr[ind_ran]=irr[ig1]+irr[ig2];
    ir1=(irr[ind_ran]^irr[ig3]);
    ind_ran++;
    r=(float)ir1*NormRANu;

    return r;
}

void ini_ran(int SEMILLA)
{
    const uint32_t FACTOR = UINT32_C(67397);
    const uint32_t SUM = UINT32_C(7364893);
    uint32_t ini = (uint32_t)SEMILLA;

    srand((unsigned int)SEMILLA); /* Mantener la inicializacion anterior */
    for (int i = 0; i < 256; i++) {
        ini = ini * FACTOR + SUM; /* Wrap-around modulo 2^32, definido por C */
        irr[i] = (unsigned int)ini;
    }
    ind_ran = ig1 = ig2 = ig3 = 0;
}
