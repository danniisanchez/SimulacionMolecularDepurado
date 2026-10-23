#include "head.h"

#ifdef _WIN32
#include <direct.h>
#else
#include <sys/stat.h>
#include <sys/types.h>
#endif
void paso_verlet_gjf(Bead *beads, int N, Vec3 *f_old, Vec3 *f_new, Vec3 *beta) {
    const double alpha = ETA*M;
    const double denom = 1.0 + alpha*H/(2.0*M);
    const double a = (1.0 - alpha*H/(2.0*M))/denom;
    const double b = 1.0/denom;
    const double sigma = sqrt(2.0*alpha*KBT*H);
    beta[0].x = 0.0;
    beta[0].y = 0.0;
    beta[0].z = 0.0;
    
    calcula_fuerzas(beads,f_old,N);

    for (int i=1; i<N; i++) {
        beta[i].x = sigma*random_gaussiano();
        beta[i].y = sigma*random_gaussiano();
        beta[i].z = sigma*random_gaussiano();

        beads[i].r.x += b*H*beads[i].v.x + b*H*H*f_old[i].x/(2.0*M) + b*H*beta[i].x/(2.0*M);
        beads[i].r.y += b*H*beads[i].v.y + b*H*H*f_old[i].y/(2.0*M) + b*H*beta[i].y/(2.0*M);
        beads[i].r.z += b*H*beads[i].v.z + b*H*H*f_old[i].z/(2.0*M) + b*H*beta[i].z/(2.0*M);
    }

    calcula_fuerzas(beads,f_new,N);

    for (int i=1; i<N; i++) {
        beads[i].v.x = a*beads[i].v.x + H*(a*f_old[i].x+f_new[i].x)/(2.0*M) + b*beta[i].x/M;
        beads[i].v.y = a*beads[i].v.y + H*(a*f_old[i].y+f_new[i].y)/(2.0*M) + b*beta[i].y/M;
        beads[i].v.z = a*beads[i].v.z + H*(a*f_old[i].z+f_new[i].z)/(2.0*M) + b*beta[i].z/M;
    }
}

static Vec3 resta(Vec3 a, Vec3 b) {
    Vec3 c = {a.x-b.x, a.y-b.y, a.z-b.z};
    return c;
}

static double norma(Vec3 a) {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
}

void inicializa_cadena(Bead *beads, int N) {
    double centro = 0.5*(N-1)*B0;
    for (int i=0; i<N; i++) {
        beads[i].r.x = i*B0-centro;
        beads[i].r.y = 0.0;
        beads[i].r.z = 0.0;
        beads[i].v.x = beads[i].v.y = beads[i].v.z = 0.0;
    }
}

void calcula_fuerzas(const Bead *beads, Vec3 *f, int N) {
    for (int i=0; i<N; i++) f[i].x=f[i].y=f[i].z=0.0;
    f[N-1].x+=F_ext;
    for (int i=0; i<N-1; i++) {
        Vec3 d = resta(beads[i+1].r, beads[i].r);
        double l = norma(d);
        if (l < 1e-14) continue;

        double pref = KE*(l-B0)/l;
        Vec3 fij = {pref*d.x, pref*d.y, pref*d.z};

        f[i].x += fij.x;   f[i].y += fij.y;   f[i].z += fij.z;
        f[i+1].x -= fij.x; f[i+1].y -= fij.y; f[i+1].z -= fij.z;
        
    }
}

double energia_potencial(const Bead *beads, int N) {
    double ep=0.0;
    for (int i=0; i<N-1; i++) {
        Vec3 d = resta(beads[i+1].r, beads[i].r);
        double dl = norma(d)-B0;
        ep += 0.5*KE*dl*dl;
    }
    return ep;
}

double energia_cinetica(const Bead *beads, int N) {
    double ek=0.0;
    for (int i=1; i<N; i++) {
        double v2 = beads[i].v.x*beads[i].v.x + beads[i].v.y*beads[i].v.y + beads[i].v.z*beads[i].v.z;
        ek += 0.5*M*v2;
    }
    return ek;
}

double distancia_extremo_extremo(const Bead *beads, int N) {
    return norma(resta(beads[N-1].r, beads[0].r));
}
double ree_direccion_fuerza(const Bead *beads, int N)
{
    return beads[N-1].r.x - beads[0].r.x;
}

double radio_giro(const Bead *beads, int N) {
    Vec3 rcm = {0.0,0.0,0.0};
    for (int i=0; i<N; i++) {
        rcm.x += beads[i].r.x; rcm.y += beads[i].r.y; rcm.z += beads[i].r.z;
    }
    rcm.x/=N; rcm.y/=N; rcm.z/=N;

    double rg2=0.0;
    for (int i=0; i<N; i++) {
        double dx=beads[i].r.x-rcm.x, dy=beads[i].r.y-rcm.y, dz=beads[i].r.z-rcm.z;
        rg2 += dx*dx+dy*dy+dz*dz;
    }
    return sqrt(rg2/N);
}

double longitud_media_enlace(const Bead *beads, int N) {
    double suma=0.0;
    for (int i=0; i<N-1; i++) suma += norma(resta(beads[i+1].r, beads[i].r));
    return suma/(N-1);
}

static void crea_dir(const char *ruta) {
#ifdef _WIN32
    _mkdir(ruta);
#else
    mkdir(ruta,0777);
#endif
}

int asegura_directorios(int N) {
    char ruta[256];
    crea_dir("results"); crea_dir("results/O3"); crea_dir("plots"); crea_dir("plots/O3");
    snprintf(ruta,sizeof(ruta),"results/O3/N%d",N); crea_dir(ruta);
    snprintf(ruta,sizeof(ruta),"plots/O3/N%d",N); crea_dir(ruta);
    return 0;
}

void guarda_snapshot(const Bead *beads, int N) {
    char nombre[256];
    snprintf(nombre,sizeof(nombre),"results/O3/N%d/snapshot_final_N%d.dat",N,N);
    FILE *f=fopen(nombre,"w");
    if (!f) return;
    fprintf(f,"# i x y z\n");
    for (int i=0; i<N; i++) fprintf(f,"%d %.12g %.12g %.12g\n",i,beads[i].r.x,beads[i].r.y,beads[i].r.z);
    fclose(f);
}
