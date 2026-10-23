#include "head.h"

static int N_permitido(int N) {
    return N==4 || N==8 || N==16 || N==32 || N==64;
}

int main(int argc,char **argv) {
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

    char nombre_term[256],nombre_med[256],nombre_res[256];
    snprintf(nombre_term,sizeof(nombre_term),"results/O3/N%d/termalizacion_N%d.dat",N,N);
    snprintf(nombre_med,sizeof(nombre_med),"results/O3/N%d/medidas_N%d.dat",N,N);
    snprintf(nombre_res,sizeof(nombre_res),"results/O3/N%d/resumen_N%d.dat",N,N);

    FILE *f_term=fopen(nombre_term,"w");
    FILE *f_med=fopen(nombre_med,"w");

    if (!f_term || !f_med) {
        printf("ERROR: no se pudieron abrir ficheros para N=%d.\n",N);
        if (f_term) fclose(f_term);
        if (f_med) fclose(f_med);
        free(beads); free(f_old); free(f_new); free(beta);
        return 1;
    }

    setvbuf(f_term,NULL,_IOFBF,1024*1024);
    setvbuf(f_med,NULL,_IOFBF,1024*1024);

    fprintf(f_term,"# t <Ek> <Ebond> <Ebend> <Eev> Ek_teo\n");
    fprintf(f_med,"# t Ek Ebond Ebend Eev Ree Rg bond Ree_parallel theta_mean cos_theta_mean dmin_nonbonded\n");

    const double ek_teo=1.5*(N-1)*KBT;

    printf("O3 EV: N=%d, WCA=%d, eps=%g, sigma=%g, bending=%d, Kbend=%g\n",
           N,USE_EXCLUDED_VOLUME,EPSILON_EV,SIGMA_EV,BENDING_MODEL,KBEND);

    printf("Termalizando...\n");

    double sek_t=0.0,sep_t=0.0,seb_t=0.0,sev_t=0.0;

    for (long i=0;i<TERM_STEPS;i++) {
        paso_verlet_gjf(beads,N,f_old,f_new,beta);

        double ek=energia_cinetica(beads,N);
        double ep=energia_potencial(beads,N);
        double eb=energia_bending(beads,N);
        double ev=energia_excluded(beads,N);

        sek_t+=ek; sep_t+=ep; seb_t+=eb; sev_t+=ev;

        if (((i+1)%SAMPLE_EVERY==0) || i==TERM_STEPS-1) {
            double t=(i+1)*H;
            fprintf(f_term,"%.10g %.10g %.10g %.10g %.10g %.10g\n",
                    t,sek_t/(i+1),sep_t/(i+1),seb_t/(i+1),sev_t/(i+1),ek_teo);
        }
    }

    printf("Midiendo...\n");

    long n_muestras=0;
    double sek=0.0,sep=0.0,seb=0.0,sev=0.0,sree=0.0,sree2=0.0;
    double srg=0.0,srg2=0.0,sbond=0.0,sree_dir=0.0,stheta=0.0,scos=0.0,sdmin=0.0;

    for (long i=0;i<MEASURE_STEPS;i++) {
        paso_verlet_gjf(beads,N,f_old,f_new,beta);

        if (((i+1)%SAMPLE_EVERY==0) || i==MEASURE_STEPS-1) {
            double t=(i+1)*H;
            double ek=energia_cinetica(beads,N),ep=energia_potencial(beads,N);
            double eb=energia_bending(beads,N),ev=energia_excluded(beads,N);
            double ree=distancia_extremo_extremo(beads,N),rg=radio_giro(beads,N);
            double bond=longitud_media_enlace(beads,N),ree_dir=ree_direccion_fuerza(beads,N);
            double theta=angulo_medio(beads,N),ctheta=cos_angulo_medio(beads,N);
            double dmin=distancia_minima_no_enlazada(beads,N);

            fprintf(f_med,"%.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g\n",
                    t,ek,ep,eb,ev,ree,rg,bond,ree_dir,theta,ctheta,dmin);

            sek+=ek; sep+=ep; seb+=eb; sev+=ev;
            sree+=ree; sree2+=ree*ree;
            srg+=rg; srg2+=rg*rg;
            sbond+=bond; sree_dir+=ree_dir;
            stheta+=theta; scos+=ctheta; sdmin+=dmin;
            n_muestras++;
        }
    }

    fclose(f_term); fclose(f_med);

    if (n_muestras==0) {
        printf("ERROR: no se ha guardado ninguna muestra.\n");
        free(beads); free(f_old); free(f_new); free(beta);
        return 1;
    }

    double ek_mean=sek/n_muestras,ep_mean=sep/n_muestras,eb_mean=seb/n_muestras;
    double ev_mean=sev/n_muestras,ree_mean=sree/n_muestras,ree2_mean=sree2/n_muestras;
    double rg_mean=srg/n_muestras,rg2_mean=srg2/n_muestras,bond_mean=sbond/n_muestras;
    double ree_dir_mean=sree_dir/n_muestras,theta_mean=stheta/n_muestras;
    double cos_theta_mean=scos/n_muestras,dmin_mean=sdmin/n_muestras;

    FILE *f_res=fopen(nombre_res,"w");

    if (f_res) {
        fprintf(f_res,"# N Ek_mean Ek_teo Ebond_mean Ebond_ref Ree_mean Ree2_mean Rg_mean Rg2_mean bond_mean muestras Ree_parallel_mean Ebend_mean theta_mean cos_theta_mean bending_model KBEND Eev_mean dmin_mean use_EV epsilon_EV sigma_EV\n");
        fprintf(f_res,"%d %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %ld %.12g %.12g %.12g %.12g %d %.12g %.12g %.12g %d %.12g %.12g\n",
                N,ek_mean,ek_teo,ep_mean,0.5*(N-1)*KBT,ree_mean,ree2_mean,
                rg_mean,rg2_mean,bond_mean,n_muestras,ree_dir_mean,eb_mean,
                theta_mean,cos_theta_mean,BENDING_MODEL,KBEND,ev_mean,dmin_mean,
                USE_EXCLUDED_VOLUME,EPSILON_EV,SIGMA_EV);
        fclose(f_res);
    }

    guarda_snapshot(beads,N);

    printf("\n--- RESUMEN EV N=%d ---\n",N);
    printf("USE_EV       = %d\n",USE_EXCLUDED_VOLUME);
    printf("epsilon      = %.8g\n",EPSILON_EV);
    printf("sigma        = %.8g\n",SIGMA_EV);
    printf("<Ek>         = %.8g   teoria = %.8g\n",ek_mean,ek_teo);
    printf("<Ebond>      = %.8g\n",ep_mean);
    printf("<Ebend>      = %.8g\n",eb_mean);
    printf("<Eev>        = %.8g\n",ev_mean);
    printf("<Ree>        = %.8g\n",ree_mean);
    printf("<Rg>         = %.8g\n",rg_mean);
    printf("<dmin>       = %.8g\n",dmin_mean);
    printf("<l>          = %.8g\n",bond_mean);

    free(beads); free(f_old); free(f_new); free(beta);
    return 0;
}
