#include "head.h"

static int N_permitido(int N) {
    return N==4 || N==8 || N==16 || N==32 || N==64;
}

int main(int argc, char **argv) {
    if (argc!=2) {
        printf("Uso: %s N\nValores previstos: 4, 8, 16, 32, 64\n",argv[0]);
        return 1;
    }

    int N=atoi(argv[1]);
    if (!N_permitido(N)) {
        printf("ERROR: N=%d no pertenece al barrido previsto.\n",N);
        return 1;
    }

    asegura_directorios(N);
    ini_ran(SEED+N);

    Bead *beads=calloc((size_t)N,sizeof(Bead));
    Vec3 *f_old=calloc((size_t)N,sizeof(Vec3));
    Vec3 *f_new=calloc((size_t)N,sizeof(Vec3));
    Vec3 *beta=calloc((size_t)N,sizeof(Vec3));
    if (!beads || !f_old || !f_new || !beta) {
        printf("ERROR: memoria insuficiente para N=%d.\n",N);
        free(beads); free(f_old); free(f_new); free(beta);
        return 1;
    }

    inicializa_cadena(beads,N);

    char nombre_term[256], nombre_med[256], nombre_res[256];
    snprintf(nombre_term,sizeof(nombre_term),"results/O3/N%d/termalizacion_N%d.dat",N,N);
    snprintf(nombre_med,sizeof(nombre_med),"results/O3/N%d/medidas_N%d.dat",N,N);
    snprintf(nombre_res,sizeof(nombre_res),"results/O3/N%d/resumen_N%d.dat",N,N);

    FILE *f_term=fopen(nombre_term,"w");
    FILE *f_med=fopen(nombre_med,"w");
    if (!f_term || !f_med) {
        printf("ERROR: no se pudieron abrir ficheros de salida para N=%d.\n",N);
        if (f_term) fclose(f_term);
        if (f_med) fclose(f_med);
        free(beads); free(f_old); free(f_new); free(beta);
        return 1;
    }

    setvbuf(f_term,NULL,_IOFBF,1024*1024);
    setvbuf(f_med,NULL,_IOFBF,1024*1024);
    fprintf(f_term,"# t <Ek> <Ep> Ek_teo Ep_teo\n");
    fprintf(f_med,"# t Ek Ep Ree Rg longitud_media_enlace\n");

    const double ek_teo=1.5*N*KBT;
    const double ep_teo=0.5*(N-1)*KBT;

    printf("O3: N=%d, kBT=%g, ke=%g, b=%g, eta=%g, h=%g\n",N,KBT,KE,B0,ETA,H);
    printf("Termalizando...\n");

    double suma_ek_term=0.0, suma_ep_term=0.0;
    for (long i=0; i<TERM_STEPS; i++) {
        paso_verlet_gjf(beads,N,f_old,f_new,beta);
        double ek=energia_cinetica(beads,N), ep=energia_potencial(beads,N);
        suma_ek_term+=ek; suma_ep_term+=ep;

        if (((i+1)%SAMPLE_EVERY==0) || i==TERM_STEPS-1) {
            double t=(i+1)*H;
            fprintf(f_term,"%.10g %.10g %.10g %.10g %.10g\n",
                    t,suma_ek_term/(i+1),suma_ep_term/(i+1),ek_teo,ep_teo);
        }
    }

    printf("Midiendo...\n");
    long n_muestras=0;
    double sum_ek=0.0, sum_ep=0.0, sum_ree=0.0, sum_ree2=0.0;
    double sum_rg=0.0, sum_rg2=0.0, sum_bond=0.0;

    for (long i=0; i<MEASURE_STEPS; i++) {
        paso_verlet_gjf(beads,N,f_old,f_new,beta);

        if (((i+1)%SAMPLE_EVERY==0) || i==MEASURE_STEPS-1) {
            double t=(i+1)*H;
            double ek=energia_cinetica(beads,N), ep=energia_potencial(beads,N);
            double ree=distancia_extremo_extremo(beads,N), rg=radio_giro(beads,N);
            double bond=longitud_media_enlace(beads,N);

            fprintf(f_med,"%.10g %.10g %.10g %.10g %.10g %.10g\n",t,ek,ep,ree,rg,bond);
            sum_ek+=ek; sum_ep+=ep; sum_ree+=ree; sum_ree2+=ree*ree;
            sum_rg+=rg; sum_rg2+=rg*rg; sum_bond+=bond; n_muestras++;
        }
    }

    fclose(f_term); fclose(f_med);

    double ek_mean=sum_ek/n_muestras, ep_mean=sum_ep/n_muestras;
    double ree_mean=sum_ree/n_muestras, ree2_mean=sum_ree2/n_muestras;
    double rg_mean=sum_rg/n_muestras, rg2_mean=sum_rg2/n_muestras;
    double bond_mean=sum_bond/n_muestras;

    FILE *f_res=fopen(nombre_res,"w");
    if (f_res) {
        fprintf(f_res,"# N Ek_mean Ek_teo Ep_mean Ep_teo Ree_mean Ree2_mean Rg_mean Rg2_mean bond_mean muestras\n");
        fprintf(f_res,"%d %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %ld\n",
                N,ek_mean,ek_teo,ep_mean,ep_teo,ree_mean,ree2_mean,rg_mean,rg2_mean,bond_mean,n_muestras);
        fclose(f_res);
    }

    FILE *f_all=fopen("results/O3/resumen_tamanos.dat","a");
    if (f_all) {
        fprintf(f_all,"%d %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %ld\n",
                N,ek_mean,ek_teo,ep_mean,ep_teo,ree_mean,ree2_mean,rg_mean,rg2_mean,bond_mean,n_muestras);
        fclose(f_all);
    }

    guarda_snapshot(beads,N);

    printf("\n--- RESUMEN N=%d ---\n",N);
    printf("<Ek> = %.8g   teoria = %.8g   ratio = %.6f\n",ek_mean,ek_teo,ek_mean/ek_teo);
    printf("<Ep> = %.8g   referencia armonica = %.8g   ratio = %.6f\n",ep_mean,ep_teo,ep_mean/ep_teo);
    printf("<Ree> = %.8g\n<Rg>  = %.8g\n<l>   = %.8g (b=%g)\n",ree_mean,rg_mean,bond_mean,B0);

    free(beads); free(f_old); free(f_new); free(beta);
    return 0;
}
