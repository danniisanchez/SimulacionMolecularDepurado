#include "head.h"

static int N_permitido(int N) {
    return N==4 || N==8 || N==16 || N==32 || N==64;
}

static double cambio_relativo(double a,double b,double escala_min) {
    double escala=fmax(fmax(fabs(a),fabs(b)),escala_min);
    return fabs(a-b)/escala;
}

/* Guia Rouse: el minimo de termalizacion crece aproximadamente como N^2. */
static long term_min_para_N(int N) {
    double q=(double)N/8.0;
    double factor=q*q;
    if (factor<1.0) factor=1.0;

    long minimo=(long)(TERM_MIN_N8*factor);
    if (minimo<TERM_MIN_N8) minimo=TERM_MIN_N8;
    if (minimo>TERM_MAX_STEPS) minimo=TERM_MAX_STEPS;
    return minimo;
}

/* Actualizacion de media/varianza online para medias por bloques. */
static void welford(double x,long n,double *mean,double *M2) {
    double delta=x-*mean;
    *mean+=delta/(double)n;
    *M2+=delta*(x-*mean);
}

static double relerr_media(double mean,double M2,long n,double escala_min) {
    if (n<2) return INFINITY;
    double var=M2/(double)(n-1);
    double se=sqrt(fmax(0.0,var)/(double)n);
    return se/fmax(fabs(mean),escala_min);
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

    /*
     * Las primeras seis columnas se conservan respecto a tu version actual.
     * Ree, Rg y bond se añaden al final para diagnosticar la termalizacion.
     */
    fprintf(f_term,"# t <Ek> <Ebond> <Ebend> <Eev> Ek_teo <Ree> <Rg> <bond>\n");
    fprintf(f_med,"# t Ek Ebond Ebend Eev Ree Rg bond Ree_parallel theta_mean cos_theta_mean dmin_nonbonded\n");

    const double ek_teo=1.5*(N-1)*KBT;
    const long term_min=term_min_para_N(N);

    printf("O3: N=%d, WCA=%d, eps=%g, sigma=%g, bending=%d, Kbend=%g, F=%g\n",
           N,USE_EXCLUDED_VOLUME,EPSILON_EV,SIGMA_EV,BENDING_MODEL,KBEND,F_ext);
    printf("Termalizacion adaptativa: min=%ld max=%ld bloque=%ld, %d bloques estables.\n",
           term_min,(long)TERM_MAX_STEPS,(long)TERM_BLOCK_STEPS,TERM_STABLE_BLOCKS);

    /************************************************/
    /************** TERMALIZACION ADAPTATIVA ********/
    /************************************************/
    long term_steps_used=0,term_samples=0;
    int term_converged=0,stable_blocks=0;

    double cum_ek=0.0,cum_ep=0.0,cum_eb=0.0,cum_ev=0.0;
    double cum_ree=0.0,cum_rg=0.0,cum_bond=0.0;

    double b_ek=0.0,b_rg=0.0,b_ree=0.0,b_bond=0.0;
    long b_samples=0;

    double prev_ek=NAN,prev_rg=NAN,prev_ree=NAN,prev_bond=NAN;
    double last_dEk=NAN,last_dRg=NAN,last_dRee=NAN,last_dBond=NAN;

    for (long i=0;i<TERM_MAX_STEPS;i++) {
        paso_verlet_gjf(beads,N,f_old,f_new,beta);
        term_steps_used=i+1;

        if ((term_steps_used%SAMPLE_EVERY)==0 || term_steps_used==TERM_MAX_STEPS) {
            double ek=energia_cinetica(beads,N);
            double ep=energia_potencial(beads,N);
            double eb=energia_bending(beads,N);
            double ev=energia_excluded(beads,N);
            double ree=distancia_extremo_extremo(beads,N);
            double rg=radio_giro(beads,N);
            double bond=longitud_media_enlace(beads,N);

            term_samples++;
            cum_ek+=ek; cum_ep+=ep; cum_eb+=eb; cum_ev+=ev;
            cum_ree+=ree; cum_rg+=rg; cum_bond+=bond;

            b_ek+=ek; b_rg+=rg; b_ree+=ree; b_bond+=bond; b_samples++;

            fprintf(f_term,"%.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g %.10g\n",
                    term_steps_used*H,
                    cum_ek/term_samples,cum_ep/term_samples,
                    cum_eb/term_samples,cum_ev/term_samples,ek_teo,
                    cum_ree/term_samples,cum_rg/term_samples,cum_bond/term_samples);
        }

        if ((term_steps_used%TERM_BLOCK_STEPS)==0 || term_steps_used==TERM_MAX_STEPS) {
            if (b_samples>0) {
                double mEk=b_ek/b_samples;
                double mRg=b_rg/b_samples;
                double mRee=b_ree/b_samples;
                double mBond=b_bond/b_samples;

                if (term_steps_used>=term_min && isfinite(prev_ek)) {
                    last_dEk=cambio_relativo(mEk,prev_ek,ek_teo);
                    last_dRg=cambio_relativo(mRg,prev_rg,B0);
                    last_dRee=cambio_relativo(mRee,prev_ree,B0);
                    last_dBond=cambio_relativo(mBond,prev_bond,B0);

                    double errEk=fabs(mEk-ek_teo)/ek_teo;

                    int estable=(last_dEk<TERM_TOL_EK &&
                                 last_dRg<TERM_TOL_RG &&
                                 last_dRee<TERM_TOL_REE &&
                                 last_dBond<TERM_TOL_BOND &&
                                 errEk<TERM_TOL_EK_THEORY);

                    stable_blocks=estable ? stable_blocks+1 : 0;

                    printf("TERM paso=%ld <Ek>=%.5g <Rg>=%.5g <Ree>=%.5g <l>=%.5g "
                           "d=(%.3g,%.3g,%.3g,%.3g) estable=%d/%d\n",
                           term_steps_used,mEk,mRg,mRee,mBond,
                           last_dEk,last_dRg,last_dRee,last_dBond,
                           stable_blocks,TERM_STABLE_BLOCKS);

                    if (stable_blocks>=TERM_STABLE_BLOCKS) {
                        term_converged=1;
                        break;
                    }
                }

                prev_ek=mEk; prev_rg=mRg; prev_ree=mRee; prev_bond=mBond;
            }

            b_ek=b_rg=b_ree=b_bond=0.0;
            b_samples=0;
        }
    }

    if (term_converged)
        printf("Termalizacion convergida en %ld pasos (t=%g).\n",
               term_steps_used,term_steps_used*H);
    else
        printf("[AVISO] TERM_MAX_STEPS=%ld alcanzado sin cumplir todos los criterios.\n",
               (long)TERM_MAX_STEPS);

    /************************************************/
    /************** MEDIDA ADAPTATIVA ***************/
    /************************************************/
    printf("Midiendo: min=%ld max=%ld bloque=%ld; objetivo err(Rg)<%.3g, err(Ree)<%.3g.\n",
           (long)MEASURE_MIN_STEPS,(long)MEASURE_MAX_STEPS,
           (long)MEASURE_BLOCK_STEPS,MEASURE_RELERR_RG,MEASURE_RELERR_REE);

    long n_muestras=0,measure_steps_used=0;
    int stats_converged=0;

    double sek=0.0,sep=0.0,seb=0.0,sev=0.0,sree=0.0,sree2=0.0;
    double srg=0.0,srg2=0.0,sbond=0.0,sree_dir=0.0,stheta=0.0,scos=0.0,sdmin=0.0;

    double block_rg=0.0,block_ree=0.0;
    long block_samples=0,n_measure_blocks=0;
    double mean_block_rg=0.0,M2_block_rg=0.0;
    double mean_block_ree=0.0,M2_block_ree=0.0;
    double relerr_rg=INFINITY,relerr_ree=INFINITY;

    for (long i=0;i<MEASURE_MAX_STEPS;i++) {
        paso_verlet_gjf(beads,N,f_old,f_new,beta);
        measure_steps_used=i+1;

        if ((measure_steps_used%SAMPLE_EVERY)==0 || measure_steps_used==MEASURE_MAX_STEPS) {
            double t=measure_steps_used*H;
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

            block_rg+=rg; block_ree+=ree; block_samples++;
        }

        if ((measure_steps_used%MEASURE_BLOCK_STEPS)==0 ||
            measure_steps_used==MEASURE_MAX_STEPS) {

            if (block_samples>0) {
                double mRg=block_rg/block_samples;
                double mRee=block_ree/block_samples;

                n_measure_blocks++;
                welford(mRg,n_measure_blocks,&mean_block_rg,&M2_block_rg);
                welford(mRee,n_measure_blocks,&mean_block_ree,&M2_block_ree);

                relerr_rg=relerr_media(mean_block_rg,M2_block_rg,n_measure_blocks,B0);
                relerr_ree=relerr_media(mean_block_ree,M2_block_ree,n_measure_blocks,B0);

                printf("MEASURE bloque=%ld paso=%ld <Rg>_b=%.5g <Ree>_b=%.5g "
                       "relerr=(%.3g,%.3g)\n",
                       n_measure_blocks,measure_steps_used,mRg,mRee,
                       relerr_rg,relerr_ree);

                if (measure_steps_used>=MEASURE_MIN_STEPS &&
                    n_measure_blocks>=MEASURE_MIN_BLOCKS &&
                    relerr_rg<MEASURE_RELERR_RG &&
                    relerr_ree<MEASURE_RELERR_REE) {
                    stats_converged=1;
                    break;
                }
            }

            block_rg=block_ree=0.0;
            block_samples=0;
        }
    }

    fclose(f_term); fclose(f_med);

    if (n_muestras==0) {
        printf("ERROR: no se ha guardado ninguna muestra.\n");
        free(beads); free(f_old); free(f_new); free(beta);
        return 1;
    }

    if (!stats_converged)
        printf("[AVISO] MEASURE_MAX_STEPS=%ld alcanzado sin cumplir el error objetivo.\n",
               (long)MEASURE_MAX_STEPS);

    double ek_mean=sek/n_muestras,ep_mean=sep/n_muestras,eb_mean=seb/n_muestras;
    double ev_mean=sev/n_muestras,ree_mean=sree/n_muestras,ree2_mean=sree2/n_muestras;
    double rg_mean=srg/n_muestras,rg2_mean=srg2/n_muestras,bond_mean=sbond/n_muestras;
    double ree_dir_mean=sree_dir/n_muestras,theta_mean=stheta/n_muestras;
    double cos_theta_mean=scos/n_muestras,dmin_mean=sdmin/n_muestras;

    FILE *f_res=fopen(nombre_res,"w");

    if (f_res) {
        /*
         * Las primeras 22 columnas se conservan exactamente para que sigan
         * funcionando los PS1 de bending/WLC/EV ya creados.
         */
        fprintf(f_res,
                "# N Ek_mean Ek_teo Ebond_mean Ebond_ref Ree_mean Ree2_mean "
                "Rg_mean Rg2_mean bond_mean muestras Ree_parallel_mean Ebend_mean "
                "theta_mean cos_theta_mean bending_model KBEND Eev_mean dmin_mean "
                "use_EV epsilon_EV sigma_EV "
                "term_steps measure_steps term_converged stats_converged "
                "measure_blocks relerr_Rg relerr_Ree "
                "dEk_term dRg_term dRee_term dBond_term\n");

        fprintf(f_res,
                "%d %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g "
                "%ld %.12g %.12g %.12g %.12g %d %.12g %.12g %.12g %d %.12g %.12g "
                "%ld %ld %d %d %ld %.12g %.12g %.12g %.12g %.12g %.12g\n",
                N,ek_mean,ek_teo,ep_mean,0.5*(N-1)*KBT,ree_mean,ree2_mean,
                rg_mean,rg2_mean,bond_mean,n_muestras,ree_dir_mean,eb_mean,
                theta_mean,cos_theta_mean,BENDING_MODEL,KBEND,ev_mean,dmin_mean,
                USE_EXCLUDED_VOLUME,EPSILON_EV,SIGMA_EV,
                term_steps_used,measure_steps_used,term_converged,stats_converged,
                n_measure_blocks,relerr_rg,relerr_ree,
                last_dEk,last_dRg,last_dRee,last_dBond);

        fclose(f_res);
    }

    guarda_snapshot(beads,N);

    printf("\n--- RESUMEN O3 N=%d ---\n",N);
    printf("<Ek>              = %.8g   teoria = %.8g\n",ek_mean,ek_teo);
    printf("<Ebond>           = %.8g\n",ep_mean);
    printf("<Ebend>           = %.8g\n",eb_mean);
    printf("<Eev>             = %.8g\n",ev_mean);
    printf("<Ree>             = %.8g\n",ree_mean);
    printf("<Rg>              = %.8g\n",rg_mean);
    printf("<dmin>            = %.8g\n",dmin_mean);
    printf("<l>               = %.8g\n",bond_mean);
    printf("TERM              = %ld/%ld  converged=%d\n",
           term_steps_used,(long)TERM_MAX_STEPS,term_converged);
    printf("MEASURE           = %ld/%ld  converged=%d\n",
           measure_steps_used,(long)MEASURE_MAX_STEPS,stats_converged);
    printf("Error bloques     = Rg %.4g   Ree %.4g\n",relerr_rg,relerr_ree);

    free(beads); free(f_old); free(f_new); free(beta);
    return 0;
}
