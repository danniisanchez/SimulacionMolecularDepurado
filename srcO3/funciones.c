#include "head.h"

#ifdef _WIN32
#include <direct.h>
#else
#include <sys/stat.h>
#include <sys/types.h>
#endif

static Vec3 resta(Vec3 a,Vec3 b) {
    Vec3 c={a.x-b.x,a.y-b.y,a.z-b.z};
    return c;
}

static double norma(Vec3 a) {
    return sqrt(a.x*a.x+a.y*a.y+a.z*a.z);
}

static double producto(Vec3 a,Vec3 b) {
    return a.x*b.x+a.y*b.y+a.z*b.z;
}

void paso_verlet_gjf(Bead *beads,int N,Vec3 *f_old,Vec3 *f_new,Vec3 *beta) {
    const double alpha=ETA*M;
    const double denom=1.0+alpha*H/(2.0*M);
    const double a=(1.0-alpha*H/(2.0*M))/denom;
    const double b=1.0/denom;
    const double sigma=sqrt(2.0*alpha*KBT*H);

    beta[0].x=beta[0].y=beta[0].z=0.0;
    calcula_fuerzas(beads,f_old,N);

    for (int i=1;i<N;i++) {
        beta[i].x=sigma*random_gaussiano();
        beta[i].y=sigma*random_gaussiano();
        beta[i].z=sigma*random_gaussiano();

        beads[i].r.x+=b*H*beads[i].v.x+b*H*H*f_old[i].x/(2.0*M)+b*H*beta[i].x/(2.0*M);
        beads[i].r.y+=b*H*beads[i].v.y+b*H*H*f_old[i].y/(2.0*M)+b*H*beta[i].y/(2.0*M);
        beads[i].r.z+=b*H*beads[i].v.z+b*H*H*f_old[i].z/(2.0*M)+b*H*beta[i].z/(2.0*M);
    }

    calcula_fuerzas(beads,f_new,N);

    for (int i=1;i<N;i++) {
        beads[i].v.x=a*beads[i].v.x+H*(a*f_old[i].x+f_new[i].x)/(2.0*M)+b*beta[i].x/M;
        beads[i].v.y=a*beads[i].v.y+H*(a*f_old[i].y+f_new[i].y)/(2.0*M)+b*beta[i].y/M;
        beads[i].v.z=a*beads[i].v.z+H*(a*f_old[i].z+f_new[i].z)/(2.0*M)+b*beta[i].z/M;
    }
}

void inicializa_cadena(Bead *beads,int N) {
    for (int i=0;i<N;i++) {
        beads[i].r.x=i*B0;
        beads[i].r.y=0.0;
        beads[i].r.z=0.0;
        beads[i].v.x=beads[i].v.y=beads[i].v.z=0.0;
    }
}

void calcula_fuerzas_bending(const Bead *beads,Vec3 *f,int N) {
    if (BENDING_MODEL==0 || KBEND==0.0 || N<3) return;

    for (int i=1;i<N-1;i++) {
        Vec3 va=resta(beads[i].r,beads[i-1].r);
        Vec3 vb=resta(beads[i+1].r,beads[i].r);
        double la=norma(va),lb=norma(vb);
        if (la<1e-14 || lb<1e-14) continue;

        Vec3 ua={va.x/la,va.y/la,va.z/la};
        Vec3 ub={vb.x/lb,vb.y/lb,vb.z/lb};

        double c=producto(ua,ub);
        if (c>1.0) c=1.0;
        if (c<-1.0) c=-1.0;

        double theta=acos(c);
        double s=sqrt(fmax(0.0,1.0-c*c));
        double factor=0.0;

        if (BENDING_MODEL==1) {
            double dtheta=theta-THETA0;
            if (s<1e-10 && theta<1e-8 && fabs(THETA0)<1e-14) factor=KBEND;
            else if (s<1e-10) continue;
            else factor=KBEND*dtheta/s;
        }
        else if (BENDING_MODEL==2) {
            if (fabs(THETA0)<1e-14) factor=KBEND;
            else if (s<1e-10) continue;
            else factor=KBEND*sin(theta-THETA0)/s;
        }

        Vec3 Fprev={
            -(factor/la)*(ub.x-c*ua.x),
            -(factor/la)*(ub.y-c*ua.y),
            -(factor/la)*(ub.z-c*ua.z)
        };

        Vec3 Fnext={
            +(factor/lb)*(ua.x-c*ub.x),
            +(factor/lb)*(ua.y-c*ub.y),
            +(factor/lb)*(ua.z-c*ub.z)
        };

        Vec3 Fmid={
            -(Fprev.x+Fnext.x),
            -(Fprev.y+Fnext.y),
            -(Fprev.z+Fnext.z)
        };

        f[i-1].x+=Fprev.x; f[i-1].y+=Fprev.y; f[i-1].z+=Fprev.z;
        f[i].x+=Fmid.x;    f[i].y+=Fmid.y;    f[i].z+=Fmid.z;
        f[i+1].x+=Fnext.x; f[i+1].y+=Fnext.y; f[i+1].z+=Fnext.z;
    }
}

/*
   Weeks-Chandler-Andersen (WCA):
     V(r)=4 eps [(sigma/r)^12-(sigma/r)^6]+eps,  r<2^(1/6)sigma
     V(r)=0,                                      resto

   Se aplica SOLO a pares no enlazados: |i-j|>1.
*/
void calcula_fuerzas_excluded(const Bead *beads,Vec3 *f,int N) {
    if (!USE_EXCLUDED_VOLUME || EPSILON_EV==0.0 || N<3) return;

    const double rc=pow(2.0,1.0/6.0)*SIGMA_EV;
    const double rc2=rc*rc;
    const double sigma2=SIGMA_EV*SIGMA_EV;

    for (int i=0;i<N-2;i++) {
        for (int j=i+2;j<N;j++) {
            Vec3 d=resta(beads[j].r,beads[i].r);
            double r2=producto(d,d);

            if (r2>=rc2) continue;
            if (r2<1e-20) continue;

            double sr2=sigma2/r2;
            double sr6=sr2*sr2*sr2;
            double sr12=sr6*sr6;

            /* F_i = -24 eps (2 sr12-sr6) d/r^2 :
               d apunta de i hacia j, por eso F_i apunta alejandose de j. */
            double pref=24.0*EPSILON_EV*(2.0*sr12-sr6)/r2;
            Vec3 Fi={-pref*d.x,-pref*d.y,-pref*d.z};

            f[i].x+=Fi.x; f[i].y+=Fi.y; f[i].z+=Fi.z;
            f[j].x-=Fi.x; f[j].y-=Fi.y; f[j].z-=Fi.z;
        }
    }
}

void calcula_fuerzas(const Bead *beads,Vec3 *f,int N) {
    for (int i=0;i<N;i++) f[i].x=f[i].y=f[i].z=0.0;

    for (int i=0;i<N-1;i++) {
        Vec3 d=resta(beads[i+1].r,beads[i].r);
        double l=norma(d);
        if (l<1e-14) continue;

        double pref=KE*(l-B0)/l;
        Vec3 fij={pref*d.x,pref*d.y,pref*d.z};

        f[i].x+=fij.x;     f[i].y+=fij.y;     f[i].z+=fij.z;
        f[i+1].x-=fij.x;   f[i+1].y-=fij.y;   f[i+1].z-=fij.z;
    }

    calcula_fuerzas_bending(beads,f,N);
    calcula_fuerzas_excluded(beads,f,N);
    f[N-1].x+=F_ext;
}

double energia_potencial(const Bead *beads,int N) {
    double ep=0.0;

    for (int i=0;i<N-1;i++) {
        Vec3 d=resta(beads[i+1].r,beads[i].r);
        double dl=norma(d)-B0;
        ep+=0.5*KE*dl*dl;
    }

    return ep;
}

double energia_bending(const Bead *beads,int N) {
    if (BENDING_MODEL==0 || KBEND==0.0 || N<3) return 0.0;

    double e=0.0;

    for (int i=1;i<N-1;i++) {
        Vec3 a=resta(beads[i].r,beads[i-1].r);
        Vec3 b=resta(beads[i+1].r,beads[i].r);
        double la=norma(a),lb=norma(b);
        if (la<1e-14 || lb<1e-14) continue;

        double c=producto(a,b)/(la*lb);
        if (c>1.0) c=1.0;
        if (c<-1.0) c=-1.0;

        double theta=acos(c);

        if (BENDING_MODEL==1) {
            double dtheta=theta-THETA0;
            e+=0.5*KBEND*dtheta*dtheta;
        }
        else if (BENDING_MODEL==2) {
            e+=KBEND*(1.0-cos(theta-THETA0));
        }
    }

    return e;
}

double energia_excluded(const Bead *beads,int N) {
    if (!USE_EXCLUDED_VOLUME || EPSILON_EV==0.0 || N<3) return 0.0;

    const double rc=pow(2.0,1.0/6.0)*SIGMA_EV;
    const double rc2=rc*rc;
    const double sigma2=SIGMA_EV*SIGMA_EV;
    double e=0.0;

    for (int i=0;i<N-2;i++) {
        for (int j=i+2;j<N;j++) {
            Vec3 d=resta(beads[j].r,beads[i].r);
            double r2=producto(d,d);

            if (r2>=rc2) continue;
            if (r2<1e-20) continue;

            double sr2=sigma2/r2;
            double sr6=sr2*sr2*sr2;
            double sr12=sr6*sr6;

            e+=4.0*EPSILON_EV*(sr12-sr6)+EPSILON_EV;
        }
    }

    return e;
}

double distancia_minima_no_enlazada(const Bead *beads,int N) {
    if (N<3) return 0.0;

    double dmin=HUGE_VAL;

    for (int i=0;i<N-2;i++) {
        for (int j=i+2;j<N;j++) {
            double r=norma(resta(beads[j].r,beads[i].r));
            if (r<dmin) dmin=r;
        }
    }

    return isfinite(dmin) ? dmin : 0.0;
}

double angulo_medio(const Bead *beads,int N) {
    if (N<3) return 0.0;

    double suma=0.0;
    int cuenta=0;

    for (int i=1;i<N-1;i++) {
        Vec3 a=resta(beads[i].r,beads[i-1].r);
        Vec3 b=resta(beads[i+1].r,beads[i].r);
        double la=norma(a),lb=norma(b);
        if (la<1e-14 || lb<1e-14) continue;

        double c=producto(a,b)/(la*lb);
        if (c>1.0) c=1.0;
        if (c<-1.0) c=-1.0;

        suma+=acos(c);
        cuenta++;
    }

    return cuenta>0 ? suma/cuenta : 0.0;
}

double cos_angulo_medio(const Bead *beads,int N) {
    if (N<3) return 1.0;

    double suma=0.0;
    int cuenta=0;

    for (int i=1;i<N-1;i++) {
        Vec3 a=resta(beads[i].r,beads[i-1].r);
        Vec3 b=resta(beads[i+1].r,beads[i].r);
        double la=norma(a),lb=norma(b);
        if (la<1e-14 || lb<1e-14) continue;

        double c=producto(a,b)/(la*lb);
        if (c>1.0) c=1.0;
        if (c<-1.0) c=-1.0;

        suma+=c;
        cuenta++;
    }

    return cuenta>0 ? suma/cuenta : 1.0;
}

double energia_cinetica(const Bead *beads,int N) {
    double ek=0.0;

    for (int i=1;i<N;i++) {
        double v2=beads[i].v.x*beads[i].v.x+
                  beads[i].v.y*beads[i].v.y+
                  beads[i].v.z*beads[i].v.z;
        ek+=0.5*M*v2;
    }

    return ek;
}

double distancia_extremo_extremo(const Bead *beads,int N) {
    return norma(resta(beads[N-1].r,beads[0].r));
}

double ree_direccion_fuerza(const Bead *beads,int N) {
    return beads[N-1].r.x-beads[0].r.x;
}

double radio_giro(const Bead *beads,int N) {
    Vec3 rcm={0.0,0.0,0.0};

    for (int i=0;i<N;i++) {
        rcm.x+=beads[i].r.x; rcm.y+=beads[i].r.y; rcm.z+=beads[i].r.z;
    }

    rcm.x/=N; rcm.y/=N; rcm.z/=N;

    double rg2=0.0;

    for (int i=0;i<N;i++) {
        double dx=beads[i].r.x-rcm.x;
        double dy=beads[i].r.y-rcm.y;
        double dz=beads[i].r.z-rcm.z;
        rg2+=dx*dx+dy*dy+dz*dz;
    }

    return sqrt(rg2/N);
}

double longitud_media_enlace(const Bead *beads,int N) {
    double suma=0.0;
    for (int i=0;i<N-1;i++) suma+=norma(resta(beads[i+1].r,beads[i].r));
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

void guarda_snapshot(const Bead *beads,int N) {
    char nombre[256];
    snprintf(nombre,sizeof(nombre),"results/O3/N%d/snapshot_final_N%d.dat",N,N);

    FILE *f=fopen(nombre,"w");
    if (!f) return;

    fprintf(f,"# i x y z\n");

    for (int i=0;i<N;i++)
        fprintf(f,"%d %.12g %.12g %.12g\n",
                i,beads[i].r.x,beads[i].r.y,beads[i].r.z);

    fclose(f);
}
