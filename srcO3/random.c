#include "head.h"

unsigned int irr[256];
unsigned int ir1;
unsigned char ind_ran,ig1,ig2,ig3;

float randomIn(double min, double max) {
    return (float)(min + (max-min)*Random());
}

float Random(void) {
    ig1=ind_ran-24; ig2=ind_ran-55; ig3=ind_ran-61;
    irr[ind_ran]=irr[ig1]+irr[ig2];
    ir1=(irr[ind_ran]^irr[ig3]);
    ind_ran++;
    return ir1*NORM_RANU;
}

void ini_ran(int SEMILLA) {
    int INI=SEMILLA, FACTOR=67397, SUM=7364893;
    srand(SEMILLA);
    for (int i=0; i<256; i++) {
        INI=INI*FACTOR+SUM;
        irr[i]=(unsigned int)INI;
    }
    ind_ran=ig1=ig2=ig3=0;
}

double random_gaussiano(void) {
    double u1,u2;
    do { u1=randomIn(0.0,1.0); } while (u1<=0.0);
    u2=randomIn(0.0,1.0);
    return sqrt(-2.0*log(u1))*cos(2.0*PI*u2);
}
