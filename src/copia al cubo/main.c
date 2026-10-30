#include "head.h"

static void integra_un_paso(double *x, double *p) {
    switch(flag) {
        case 0: paso_euler_maruyama(x,p); break;
        case 1: paso_rk2_estocastico(x,p); break;
        case 2: paso_verlet(x,p); break;
    }
}

static double cambio_relativo(double a, double b, double escala_min) {
    double escala=fmax(fmax(fabs(a),fabs(b)),escala_min);
    return fabs(a-b)/escala;
}

static void ocupaciones_boltzmann(double *p_izq, double *p_der, double *Z_out) {
    const double xmin=-3.0, xmax=3.0, dx=0.0001;
    double Z=0.0, Zizq=0.0, Zder=0.0;

    for (double xi=xmin; xi<=xmax; xi+=dx) {
        double V=A*pow((xi*xi-1.0),2)-FEXT*xi;
        double w=exp(-V/KBT)*dx;
        Z+=w;
        if (xi<0.0) Zizq+=w;
        else Zder+=w;
    }

    if (Z>0.0) {
        *p_izq=Zizq/Z;
        *p_der=Zder/Z;
    } else {
        *p_izq=NAN;
        *p_der=NAN;
    }
    if (Z_out) *Z_out=Z;
}

static double error_relativo_media(long n, double suma, double suma2) {
    if (n<2 || !(suma>0.0)) return INFINITY;

    double media=suma/(double)n;
    double numerador=suma2-(suma*suma)/(double)n;
    if (numerador<0.0 && fabs(numerador)<1e-12*fmax(1.0,suma2))
        numerador=0.0;

    double var=(n>1)?numerador/(double)(n-1):NAN;
    if (!(var>=0.0) || !(media>0.0)) return INFINITY;

    double se=sqrt(var/(double)n);
    return se/media;
}

int main(void) {
    /************** VARIABLES GENERALES **************/
    char nombre_metodo[20];
    double x=0.0,p=0.0,ek,ep;
    double sum_ek=0.0,sum_ep=0.0;
    long pasos_energia=0;

    const double xc=0.2;

    long guardar_cada_local=guardar_cada;
    if (guardar_cada_local<1) guardar_cada_local=1;

    /*
     * La reserva usa los LIMITES MAXIMOS, porque la parada real
     * de termalizacion y medida se decide durante la simulacion.
     */
    long max_datos_energia=(TERM_MAX_STEPS/guardar_cada_local)+3;
    long max_datos_medida=(MEASURE_MAX_STEPS/guardar_cada_local)+3;

    double *t_energia=malloc((size_t)max_datos_energia*sizeof(double));
    double *ek_array=malloc((size_t)max_datos_energia*sizeof(double));
    double *ep_array=malloc((size_t)max_datos_energia*sizeof(double));
    double *t_medida=malloc((size_t)max_datos_medida*sizeof(double));
    double *x_array=malloc((size_t)max_datos_medida*sizeof(double));
    double *v_array=malloc((size_t)max_datos_medida*sizeof(double));

    if (!t_energia || !ek_array || !ep_array || !t_medida || !x_array || !v_array) {
        printf("ERROR: No hay memoria RAM suficiente para los arrays.\n");
        free(t_energia); free(ek_array); free(ep_array);
        free(t_medida); free(x_array); free(v_array);
        return 1;
    }

    long idx_energia=0,idx_medida=0;

    /************** INICIALIZACION ****************/
    ini_ran(seed);
    guardaAleatorios();

    switch(flag) {
        case 0: strcpy(nombre_metodo,"Euler"); break;
        case 1: strcpy(nombre_metodo,"RK2"); break;
        case 2: strcpy(nombre_metodo,"Verlet"); break;
        default:
            printf("ERROR: flag de integrador no valido.\n");
            free(t_energia); free(ek_array); free(ep_array);
            free(t_medida); free(x_array); free(v_array);
            return 1;
    }

    double Fcrit=8.0*A/(3.0*sqrt(3.0));
    int doble_pozo_metastable=(fabs(FEXT)<Fcrit);

    if (flag_Objetivo==2 && !doble_pozo_metastable) {
        printf("AVISO: |FEXT|=%g >= Fcrit=%g; no existen dos pozos metastables.\n",
               fabs(FEXT),Fcrit);
    }

    double Pizq_teoria=NAN,Pder_teoria=NAN,Z_boltz=NAN;
    ocupaciones_boltzmann(&Pizq_teoria,&Pder_teoria,&Z_boltz);
    double C_teorica=(Z_boltz>0.0)?1.0/Z_boltz:NAN;

    printf("Boltzmann teorico: Pizq=%g Pder=%g C=%g\n",
           Pizq_teoria,Pder_teoria,C_teorica);

    /************************************************/
    /************** 1. TERMALIZACION ADAPTATIVA *****/
    /************************************************/
    printf("Termalizando: metodo=%s h=%g eta=%g A=%g FEXT=%g Objetivo=O%d\n",
           nombre_metodo,paso_h,eta,A,FEXT,flag_Objetivo);
    printf("Criterio: min=%ld max=%ld bloque=%ld estables=%d\n",
           (long)TERM_MIN_STEPS,(long)TERM_MAX_STEPS,
           (long)TERM_BLOCK_STEPS,TERM_STABLE_BLOCKS);

    long term_steps_used=0;
    int term_converged=0,stable_blocks=0,term_global_ok=0;
    long bloque_n=0;
    double bloque_ek=0.0,bloque_ep=0.0,bloque_x2=0.0;
    double prev_ek=NAN,prev_ep=NAN,prev_x2=NAN;
    double last_dEk=NAN,last_dEp=NAN,last_dX2=NAN;
    double last_occ_error_term=NAN;
    long ultimo_guardado_term=0;

    /* Diagnostico de mezcla global durante termalizacion. */
    long term_mix_izq=0,term_mix_der=0,term_mix_transiciones=0;
    int term_mix_estado=0;
    int term_mix_iniciado=0;

    char nombre_term_bloques[300];
    sprintf(nombre_term_bloques,
            "results/O%d/%s/termalizacion_bloques_h%g_A%g_eta%g_F%g_XC%g.txt",
            flag_Objetivo,nombre_metodo,paso_h,A,eta,FEXT,xc);

    FILE *f_term_bloques=fopen(nombre_term_bloques,"w");
    if (f_term_bloques) {
        fprintf(f_term_bloques,
                "# bloque step t mEk mEp mX2 dEk dEp dX2 errEkTeoria "
                "Pizq_mix Pizq_teoria errOcc mix_trans local_stable global_ok stable_blocks\n");
    } else {
        printf("[AVISO] No se pudo crear %s\n",nombre_term_bloques);
    }

    for (long i=0;i<TERM_MAX_STEPS;i++) {
        integra_un_paso(&x,&p);

        ek=energia_cinetica(p);
        ep=energia_potencial(x);

        sum_ek+=ek; sum_ep+=ep; pasos_energia++;
        bloque_ek+=ek; bloque_ep+=ep; bloque_x2+=x*x; bloque_n++;
        term_steps_used=i+1;

        if (term_steps_used>=TERM_MIX_START_STEPS) {
            if (!term_mix_iniciado) {
                term_mix_estado=(x>=0.0)?1:-1;
                term_mix_iniciado=1;
            }

            if (x>0.0) term_mix_der++;
            else if (x<0.0) term_mix_izq++;

            int nuevo_mix_estado=term_mix_estado;
            if (term_mix_estado==-1 && x>=xc) nuevo_mix_estado=1;
            else if (term_mix_estado==1 && x<=-xc) nuevo_mix_estado=-1;

            if (nuevo_mix_estado!=term_mix_estado) {
                term_mix_transiciones++;
                term_mix_estado=nuevo_mix_estado;
            }
        }

        if ((term_steps_used%guardar_cada_local)==0) {
            if (idx_energia<max_datos_energia) {
                t_energia[idx_energia]=(double)term_steps_used*paso_h;
                ek_array[idx_energia]=sum_ek/(double)pasos_energia;
                ep_array[idx_energia]=sum_ep/(double)pasos_energia;
                idx_energia++;
                ultimo_guardado_term=term_steps_used;
            }
        }

        if (bloque_n==TERM_BLOCK_STEPS || term_steps_used==TERM_MAX_STEPS) {
            double mEk=bloque_ek/(double)bloque_n;
            double mEp=bloque_ep/(double)bloque_n;
            double mX2=bloque_x2/(double)bloque_n;

            double err_ek_teoria=fabs(mEk-0.5*KBT)/(0.5*KBT);
            int local_stable=0;

            if (term_steps_used>=TERM_MIN_STEPS && isfinite(prev_ek)) {
                last_dEk=cambio_relativo(mEk,prev_ek,0.5*KBT);
                last_dEp=cambio_relativo(mEp,prev_ep,KBT);
                last_dX2=cambio_relativo(mX2,prev_x2,1.0);

                local_stable=(last_dEk<TERM_TOL_EK &&
                              last_dEp<TERM_TOL_EP &&
                              last_dX2<TERM_TOL_X2 &&
                              err_ek_teoria<TERM_TOL_EK_THEORY);

                stable_blocks=local_stable ? stable_blocks+1 : 0;
            }

            long n_mix=term_mix_izq+term_mix_der;
            double Pizq_mix=(n_mix>0)?(double)term_mix_izq/(double)n_mix:NAN;
            last_occ_error_term=(n_mix>0 && isfinite(Pizq_teoria))?
                                 fabs(Pizq_mix-Pizq_teoria):NAN;

            term_global_ok=(n_mix>0 &&
                            isfinite(last_occ_error_term) &&
                            last_occ_error_term<TERM_TOL_OCC &&
                            term_mix_transiciones>=TERM_MIN_TRANSITIONS);

            printf("TERM paso=%ld <Ek>=%g <Ep>=%g <x2>=%g "
                   "d=(%.3g,%.3g,%.3g) local=%d/%d "
                   "Pizq=%.4f(th=%.4f,err=%.4f) trans=%ld global=%s\n",
                   term_steps_used,mEk,mEp,mX2,last_dEk,last_dEp,last_dX2,
                   stable_blocks,TERM_STABLE_BLOCKS,
                   Pizq_mix,Pizq_teoria,last_occ_error_term,
                   term_mix_transiciones,term_global_ok?"SI":"NO");

            if (f_term_bloques) {
                long ibloque=(term_steps_used+TERM_BLOCK_STEPS-1)/TERM_BLOCK_STEPS;
                fprintf(f_term_bloques,
                        "%ld %ld %.12g %.12g %.12g %.12g %.12g %.12g %.12g %.12g "
                        "%.12g %.12g %.12g %ld %d %d %d\n",
                        ibloque,term_steps_used,term_steps_used*paso_h,
                        mEk,mEp,mX2,last_dEk,last_dEp,last_dX2,err_ek_teoria,
                        Pizq_mix,Pizq_teoria,last_occ_error_term,
                        term_mix_transiciones,local_stable,term_global_ok,stable_blocks);
                fflush(f_term_bloques);
            }

            if (stable_blocks>=TERM_STABLE_BLOCKS && term_global_ok) {
                term_converged=1;
                break;
            }

            prev_ek=mEk; prev_ep=mEp; prev_x2=mX2;
            bloque_ek=bloque_ep=bloque_x2=0.0;
            bloque_n=0;
        }
    }

    if (f_term_bloques) fclose(f_term_bloques);

    /* Guardar tambien el estado final si no coincidio con guardar_cada. */
    if (ultimo_guardado_term!=term_steps_used && idx_energia<max_datos_energia) {
        t_energia[idx_energia]=(double)term_steps_used*paso_h;
        ek_array[idx_energia]=sum_ek/(double)pasos_energia;
        ep_array[idx_energia]=sum_ep/(double)pasos_energia;
        idx_energia++;
    }

    if (term_converged)
        printf("Termalizacion convergida en %ld pasos (t=%g).\n",
               term_steps_used,term_steps_used*paso_h);
    else
        printf("[AVISO] Se alcanzo TERM_MAX_STEPS=%ld sin cumplir todos los criterios.\n",
               (long)TERM_MAX_STEPS);

    printf("Boltzmann usado en medida: Pizq=%g Pder=%g C=%g\n",
           Pizq_teoria,Pder_teoria,C_teorica);

    /************************************************/
    /************** 2. MEDIDA ADAPTATIVA ************/
    /************************************************/
    printf("Iniciando medida: min=%ld max=%ld; >=%ld estancias totales, "
           ">= %ld por pozo, errOcc<%g, relerrTau<%g.\n",
           (long)MEASURE_MIN_STEPS,(long)MEASURE_MAX_STEPS,
           (long)MIN_ESTANCIAS_TOTAL,(long)MIN_ESTANCIAS_POR_POZO,
           (double)MEASURE_TOL_OCC,(double)MEASURE_MAX_RELERR_TAU);

    long pasos_derecha=0,pasos_izquierda=0;

    int estado_actual=(x>=0.0)?1:-1;
    int primera_estancia_incompleta=1;
    double tiempo_entrada=0.0;

    double suma_tiempos_der=0.0,suma_tiempos_izq=0.0;
    double suma2_tiempos_der=0.0,suma2_tiempos_izq=0.0;
    long estancias_der=0,estancias_izq=0;
    long transiciones_confirmadas=0;

    char nombre_der[300],nombre_izq[300],nombre_resumen[300];

    sprintf(nombre_der,
            "results/O%d/%s/tiempos_derecha_h%g_A%g_eta%g_F%g_XC%g.txt",
            flag_Objetivo,nombre_metodo,paso_h,A,eta,FEXT,xc);

    sprintf(nombre_izq,
            "results/O%d/%s/tiempos_izquierda_h%g_A%g_eta%g_F%g_XC%g.txt",
            flag_Objetivo,nombre_metodo,paso_h,A,eta,FEXT,xc);

    sprintf(nombre_resumen,
            "results/O%d/%s/resumen_h%g_A%g_eta%g_F%g_XC%g.txt",
            flag_Objetivo,nombre_metodo,paso_h,A,eta,FEXT,xc);

    FILE *f_tiempos_der=fopen(nombre_der,"w");
    FILE *f_tiempos_izq=fopen(nombre_izq,"w");

    if (!f_tiempos_der || !f_tiempos_izq) {
        printf("ERROR: No se pudieron crear los archivos de tiempos.\n");
        if (f_tiempos_der) fclose(f_tiempos_der);
        if (f_tiempos_izq) fclose(f_tiempos_izq);
        free(t_energia); free(ek_array); free(ep_array);
        free(t_medida); free(x_array); free(v_array);
        return 1;
    }

    setvbuf(f_tiempos_der,NULL,_IOFBF,1024*1024);
    setvbuf(f_tiempos_izq,NULL,_IOFBF,1024*1024);

    long measure_steps_used=0,ultimo_guardado_medida=0;
    int stats_converged=0;

    for (long i=0;i<MEASURE_MAX_STEPS;i++) {
        integra_un_paso(&x,&p);

        measure_steps_used=i+1;
        double t_actual=(double)measure_steps_used*paso_h;

        if (x>0.0) pasos_derecha++;
        else if (x<0.0) pasos_izquierda++;

        int nuevo_estado=estado_actual;
        if (estado_actual==-1 && x>=xc) nuevo_estado=1;
        else if (estado_actual==1 && x<=-xc) nuevo_estado=-1;

        if (nuevo_estado!=estado_actual) {
            transiciones_confirmadas++;

            if (!primera_estancia_incompleta) {
                double tiempo_estancia=t_actual-tiempo_entrada;

                if (estado_actual==1) {
                    fprintf(f_tiempos_der,"%.12g\n",tiempo_estancia);
                    suma_tiempos_der+=tiempo_estancia;
                    suma2_tiempos_der+=tiempo_estancia*tiempo_estancia;
                    estancias_der++;
                } else {
                    fprintf(f_tiempos_izq,"%.12g\n",tiempo_estancia);
                    suma_tiempos_izq+=tiempo_estancia;
                    suma2_tiempos_izq+=tiempo_estancia*tiempo_estancia;
                    estancias_izq++;
                }
            } else {
                primera_estancia_incompleta=0;
            }

            estado_actual=nuevo_estado;
            tiempo_entrada=t_actual;
        }

        if ((measure_steps_used%guardar_cada_local)==0) {
            if (idx_medida<max_datos_medida) {
                t_medida[idx_medida]=t_actual;
                x_array[idx_medida]=x;
                v_array[idx_medida]=p/M;
                idx_medida++;
                ultimo_guardado_medida=measure_steps_used;
            }
        }

        if (measure_steps_used>=MEASURE_MIN_STEPS &&
            (measure_steps_used%MEASURE_CHECK_EVERY)==0) {

            long estancias_totales=estancias_der+estancias_izq;
            long n_occ=pasos_derecha+pasos_izquierda;
            double Pizq_actual=(n_occ>0)?(double)pasos_izquierda/(double)n_occ:NAN;
            double err_occ=(n_occ>0 && isfinite(Pizq_teoria))?
                            fabs(Pizq_actual-Pizq_teoria):INFINITY;

            double relerr_izq=error_relativo_media(estancias_izq,
                                                   suma_tiempos_izq,
                                                   suma2_tiempos_izq);
            double relerr_der=error_relativo_media(estancias_der,
                                                   suma_tiempos_der,
                                                   suma2_tiempos_der);

            if (doble_pozo_metastable) {
                int counts_ok=(estancias_totales>=MIN_ESTANCIAS_TOTAL &&
                               estancias_der>=MIN_ESTANCIAS_POR_POZO &&
                               estancias_izq>=MIN_ESTANCIAS_POR_POZO);

                int occ_ok=(isfinite(err_occ) && err_occ<MEASURE_TOL_OCC);
                int tau_ok=(isfinite(relerr_izq) && isfinite(relerr_der) &&
                            relerr_izq<MEASURE_MAX_RELERR_TAU &&
                            relerr_der<MEASURE_MAX_RELERR_TAU);

                printf("MED paso=%ld Pizq=%.4f(th=%.4f,err=%.4f) "
                       "N=(%ld,%ld) relerrTau=(%.3g,%.3g) "
                       "ok=(N:%d occ:%d tau:%d)\n",
                       measure_steps_used,Pizq_actual,Pizq_teoria,err_occ,
                       estancias_izq,estancias_der,relerr_izq,relerr_der,
                       counts_ok,occ_ok,tau_ok);

                if (counts_ok && occ_ok && tau_ok) {
                    stats_converged=1;
                    break;
                }
            } else {
                stats_converged=0;
                break;
            }
        }
    }

    /* Guardar punto final aunque la parada sea adaptativa. */
    if (ultimo_guardado_medida!=measure_steps_used && idx_medida<max_datos_medida) {
        t_medida[idx_medida]=(double)measure_steps_used*paso_h;
        x_array[idx_medida]=x;
        v_array[idx_medida]=p/M;
        idx_medida++;
    }

    fclose(f_tiempos_der);
    fclose(f_tiempos_izq);

    /************************************************/
    /************** RESULTADOS O2 *******************/
    /************************************************/
    long pasos_ocupacion=pasos_derecha+pasos_izquierda;
    double ocupacion_derecha=NAN,ocupacion_izquierda=NAN;

    if (pasos_ocupacion>0) {
        ocupacion_derecha=(double)pasos_derecha/(double)pasos_ocupacion;
        ocupacion_izquierda=(double)pasos_izquierda/(double)pasos_ocupacion;
    }

    double tau_der=(estancias_der>0)?suma_tiempos_der/(double)estancias_der:NAN;
    double tau_izq=(estancias_izq>0)?suma_tiempos_izq/(double)estancias_izq:NAN;

    long estancias_totales=estancias_der+estancias_izq;
    double tau_global=NAN,k_sim=NAN;

    if (estancias_totales>0) {
        tau_global=(suma_tiempos_der+suma_tiempos_izq)/(double)estancias_totales;
        if (tau_global>0.0) k_sim=1.0/tau_global;
    }

    double occ_error_measure=(isfinite(ocupacion_izquierda) && isfinite(Pizq_teoria))?
                             fabs(ocupacion_izquierda-Pizq_teoria):NAN;
    double relerr_tau_izq=error_relativo_media(estancias_izq,
                                               suma_tiempos_izq,
                                               suma2_tiempos_izq);
    double relerr_tau_der=error_relativo_media(estancias_der,
                                               suma_tiempos_der,
                                               suma2_tiempos_der);

    printf("\n--- RESULTADOS OBJETIVO 2 ---\n");
    printf("P(izquierda):              %.8g\n",ocupacion_izquierda);
    printf("P(derecha):                %.8g\n",ocupacion_derecha);
    printf("P(izquierda) Boltzmann:    %.8g\n",Pizq_teoria);
    printf("Error ocupacion |P-Pth|:   %.8g\n",occ_error_measure);
    printf("Transiciones confirmadas:  %ld\n",transiciones_confirmadas);
    printf("Estancias completas izq:   %ld\n",estancias_izq);
    printf("Estancias completas der:   %ld\n",estancias_der);

    if (estancias_izq>0) printf("Tiempo medio izquierda:    %.8g (relerr=%.4g)\n",tau_izq,relerr_tau_izq);
    else printf("Tiempo medio izquierda:    sin datos completos\n");

    if (estancias_der>0) printf("Tiempo medio derecha:      %.8g (relerr=%.4g)\n",tau_der,relerr_tau_der);
    else printf("Tiempo medio derecha:      sin datos completos\n");

    if (estancias_totales>0) {
        printf("Tiempo medio global:       %.8g\n",tau_global);
        printf("k_sim = 1/tau_global:      %.8g\n",k_sim);
    } else {
        printf("Tiempo medio global:       sin datos completos\n");
    }

    if (!stats_converged && doble_pozo_metastable) {
        printf("[AVISO] Se alcanzo el limite de medida con %ld estancias "
               "(izq=%ld, der=%ld); la estadistica puede ser insuficiente.\n",
               estancias_totales,estancias_izq,estancias_der);
    }

    FILE *f_resumen=fopen(nombre_resumen,"w");

    if (f_resumen) {
        /*
         * Se conservan intactas las 14 primeras columnas para no romper
         * scripts anteriores. Los diagnosticos adaptativos se añaden al final.
         */
        fprintf(f_resumen,
                "# h A eta XC P_izq P_der transiciones estancias_izq estancias_der "
                "tau_izq tau_der tau_global k_sim FEXT "
                "term_steps measure_steps term_converged stats_converged "
                "dEk_term dEp_term dX2_term "
                "Pizq_teoria occ_err_term term_mix_trans occ_err_measure "
                "relerr_tau_izq relerr_tau_der term_global_ok\n");

        fprintf(f_resumen,
                "%.12g %.12g %.12g %.12g %.12g %.12g %ld %ld %ld "
                "%.12g %.12g %.12g %.12g %.12g "
                "%ld %ld %d %d %.12g %.12g %.12g "
                "%.12g %.12g %ld %.12g %.12g %.12g %d\n",
                paso_h,A,eta,xc,ocupacion_izquierda,ocupacion_derecha,
                transiciones_confirmadas,estancias_izq,estancias_der,
                tau_izq,tau_der,tau_global,k_sim,FEXT,
                term_steps_used,measure_steps_used,term_converged,stats_converged,
                last_dEk,last_dEp,last_dX2,
                Pizq_teoria,last_occ_error_term,term_mix_transiciones,
                occ_error_measure,relerr_tau_izq,relerr_tau_der,term_global_ok);

        fclose(f_resumen);
    } else {
        printf("AVISO: No se pudo crear %s\n",nombre_resumen);
    }

    /************************************************/
    /************** CREAR FICHEROS ******************/
    /************************************************/
    printf("Guardando datos y creando histogramas en O%d...\n",flag_Objetivo);

    guardaEnergiasArray(nombre_metodo,paso_h,eta,
                        t_energia,ek_array,ep_array,idx_energia);
    guardaTrayectoriaArray(nombre_metodo,paso_h,eta,
                           t_medida,x_array,v_array,idx_medida);
    creaHistogramasArray(nombre_metodo,paso_h,eta,
                         x_array,v_array,idx_medida);

    free(t_energia); free(ek_array); free(ep_array);
    free(t_medida); free(x_array); free(v_array);

    /************** INFORMACION FINAL ***************/
    printf("\n=====================================\n");
    printf("SIMULACION TERMINADA\n");
    printf("=====================================\n");
    printf("Objetivo               : O%d\n",flag_Objetivo);
    printf("Metodo                 : %s\n",nombre_metodo);
    printf("h                      : %g\n",paso_h);
    printf("A                      : %g\n",A);
    printf("eta                    : %g\n",eta);
    printf("FEXT                   : %g\n",FEXT);
    printf("XC analisis            : %g\n",xc);
    printf("Termalizacion usada    : %ld / %ld pasos\n",
           term_steps_used,(long)TERM_MAX_STEPS);
    printf("Termalizacion convergio: %s\n",term_converged?"SI":"NO");
    printf("Medida usada           : %ld / %ld pasos\n",
           measure_steps_used,(long)MEASURE_MAX_STEPS);
    printf("Mezcla global termal.  : %s (errOcc=%.4g, trans=%ld)\n",
           term_global_ok?"SI":"NO",last_occ_error_term,term_mix_transiciones);
    printf("Estadistica objetivo   : %s (errOcc=%.4g, relerrTau=(%.4g,%.4g))\n",
           stats_converged?"SI":"NO",occ_error_measure,relerr_tau_izq,relerr_tau_der);
    printf("Guardado cada          : %ld pasos\n",guardar_cada_local);
    printf("Resolucion salida      : %g\n",guardar_cada_local*paso_h);
    printf("=====================================\n");

    return 0;
}
