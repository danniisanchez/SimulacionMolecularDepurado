#include "head.h"

int main(void) {
    /************** VARIABLES GENERALES **************/
    char nombre_metodo[20];
    double x = 0.0, p = 0.0, ek, ep;
    double sum_ek = 0.0, sum_ep = 0.0;
    long pasos_energia = 0;

    /* Umbral usado SOLO para confirmar transiciones entre pozos.
       No modifica el potencial. */
    const double xc = 0.2;

    long guardar_cada_local = guardar_cada;
    if (guardar_cada_local < 1) guardar_cada_local = 1;

    /* Calcular el tamaño máximo necesario para los arrays */
    long max_datos_energia = (termSteps / guardar_cada_local) + 2;
    long max_datos_medida = (numberSteps / guardar_cada_local) + 2;

    /* Reserva de memoria dinámica */
    double *t_energia = malloc(max_datos_energia * sizeof(double));
    double *ek_array = malloc(max_datos_energia * sizeof(double));
    double *ep_array = malloc(max_datos_energia * sizeof(double));
    double *t_medida = malloc(max_datos_medida * sizeof(double));
    double *x_array = malloc(max_datos_medida * sizeof(double));
    double *v_array = malloc(max_datos_medida * sizeof(double));

    if (!t_energia || !ek_array || !ep_array || !t_medida || !x_array || !v_array) {
        printf("ERROR: No hay memoria RAM suficiente para los arrays.\n");
        free(t_energia); free(ek_array); free(ep_array);
        free(t_medida); free(x_array); free(v_array);
        return 1;
    }

    long idx_energia = 0, idx_medida = 0;

    /************** INICIALIZACIÓN ****************/
    ini_ran(seed);
    guardaAleatorios();

    switch(flag) {
        case 0: strcpy(nombre_metodo, "Euler"); break;
        case 1: strcpy(nombre_metodo, "RK2"); break;
        case 2: strcpy(nombre_metodo, "Verlet"); break;
        default:
            printf("ERROR: flag de integrador no valido.\n");
            free(t_energia); free(ek_array); free(ep_array);
            free(t_medida); free(x_array); free(v_array);
            return 1;
    }

    /************************************************/
    /************** 1. TERMALIZACIÓN ****************/
    /************************************************/
    printf("Termalizando: metodo=%s  h=%g  eta=%g  A=%g  Objetivo=O%d\n",
           nombre_metodo, paso_h, eta, A, flag_Objetivo);

    for (long i = 0; i < termSteps; i++) {
        switch(flag) {
            case 0: paso_euler_maruyama(&x, &p); break;
            case 1: paso_rk2_estocastico(&x, &p); break;
            case 2: paso_verlet(&x, &p); break;
        }

        ek = energia_cinetica(p);
        ep = energia_potencial(x);
        sum_ek += ek;
        sum_ep += ep;
        pasos_energia++;

        if (((i + 1) % guardar_cada_local == 0) || (i == termSteps - 1)) {
            t_energia[idx_energia] = (double)(i + 1) * paso_h;
            ek_array[idx_energia] = sum_ek / (double)pasos_energia;
            ep_array[idx_energia] = sum_ep / (double)pasos_energia;
            idx_energia++;
        }
    }

    printf("Termalizacion terminada.\n");

    /************************************************/
    /************** 2. FASE DE MEDIDA ***************/
    /************************************************/
    printf("Iniciando fase de medida...\n");

    /* Ocupaciones: se cuentan según el criterio literal x<0 / x>0. */
    long pasos_derecha = 0, pasos_izquierda = 0;

    /* Estado metastable para medir tiempos de estancia.
       Una transición se confirma solo al alcanzar +xc o -xc. */
    int estado_actual = (x >= 0.0) ? 1 : -1;
    int primera_estancia_incompleta = 1;
    double tiempo_entrada = 0.0;

    double suma_tiempos_der = 0.0, suma_tiempos_izq = 0.0;
    long estancias_der = 0, estancias_izq = 0;
    long transiciones_confirmadas = 0;

    char nombre_der[300], nombre_izq[300], nombre_resumen[300];

    sprintf(nombre_der,
            "results/O%d/%s/tiempos_derecha_h%g_A%g_eta%g_XC%g.txt",
            flag_Objetivo, nombre_metodo, paso_h, A, eta, xc);

    sprintf(nombre_izq,
            "results/O%d/%s/tiempos_izquierda_h%g_A%g_eta%g_XC%g.txt",
            flag_Objetivo, nombre_metodo, paso_h, A, eta, xc);

    sprintf(nombre_resumen,
            "results/O%d/%s/resumen_h%g_A%g_eta%g_XC%g.txt",
            flag_Objetivo, nombre_metodo, paso_h, A, eta, xc);

    FILE *f_tiempos_der = fopen(nombre_der, "w");
    FILE *f_tiempos_izq = fopen(nombre_izq, "w");

    if (!f_tiempos_der || !f_tiempos_izq) {
        printf("ERROR: No se pudieron crear los archivos de tiempos en results/O%d/%s/.\n",
               flag_Objetivo, nombre_metodo);
        if (f_tiempos_der) fclose(f_tiempos_der);
        if (f_tiempos_izq) fclose(f_tiempos_izq);
        free(t_energia); free(ek_array); free(ep_array);
        free(t_medida); free(x_array); free(v_array);
        return 1;
    }

    setvbuf(f_tiempos_der, NULL, _IOFBF, 1024 * 1024);
    setvbuf(f_tiempos_izq, NULL, _IOFBF, 1024 * 1024);

    for (long i = 0; i < numberSteps; i++) {
        switch(flag) {
            case 0: paso_euler_maruyama(&x, &p); break;
            case 1: paso_rk2_estocastico(&x, &p); break;
            case 2: paso_verlet(&x, &p); break;
        }

        double t_actual = (double)(i + 1) * paso_h;

        /* Ocupación según el signo de x. */
        if (x > 0.0) pasos_derecha++;
        else if (x < 0.0) pasos_izquierda++;

        /* Histéresis para evitar recrossings artificiales cerca de x=0. */
        int nuevo_estado = estado_actual;
        if (estado_actual == -1 && x >= xc) nuevo_estado = 1;
        else if (estado_actual == 1 && x <= -xc) nuevo_estado = -1;

        if (nuevo_estado != estado_actual) {
            transiciones_confirmadas++;

            /* La primera estancia empezó durante la termalización:
               no conocemos su duración completa y no se usa. */
            if (!primera_estancia_incompleta) {
                double tiempo_estancia = t_actual - tiempo_entrada;

                if (estado_actual == 1) {
                    fprintf(f_tiempos_der, "%.12g\n", tiempo_estancia);
                    suma_tiempos_der += tiempo_estancia;
                    estancias_der++;
                } else {
                    fprintf(f_tiempos_izq, "%.12g\n", tiempo_estancia);
                    suma_tiempos_izq += tiempo_estancia;
                    estancias_izq++;
                }
            } else {
                primera_estancia_incompleta = 0;
            }

            estado_actual = nuevo_estado;
            tiempo_entrada = t_actual;
        }

        if (((i + 1) % guardar_cada_local == 0) || (i == numberSteps - 1)) {
            t_medida[idx_medida] = t_actual;
            x_array[idx_medida] = x;
            v_array[idx_medida] = p / M;
            idx_medida++;
        }
    }

    /* La última estancia tampoco se guarda: está censurada por el final de la simulación. */
    fclose(f_tiempos_der);
    fclose(f_tiempos_izq);

    /************************************************/
    /************** RESULTADOS O2 *******************/
    /************************************************/
    long pasos_ocupacion = pasos_derecha + pasos_izquierda;
    double ocupacion_derecha = NAN, ocupacion_izquierda = NAN;

    if (pasos_ocupacion > 0) {
        ocupacion_derecha = (double)pasos_derecha / (double)pasos_ocupacion;
        ocupacion_izquierda = (double)pasos_izquierda / (double)pasos_ocupacion;
    }

    double tau_der = (estancias_der > 0) ? suma_tiempos_der / (double)estancias_der : NAN;
    double tau_izq = (estancias_izq > 0) ? suma_tiempos_izq / (double)estancias_izq : NAN;

    long estancias_totales = estancias_der + estancias_izq;
    double tau_global = NAN, k_sim = NAN;

    if (estancias_totales > 0) {
        tau_global = (suma_tiempos_der + suma_tiempos_izq) / (double)estancias_totales;
        if (tau_global > 0.0) k_sim = 1.0 / tau_global;
    }

    printf("\n--- RESULTADOS OBJETIVO 2 ---\n");
    printf("P(izquierda):              %.8g\n", ocupacion_izquierda);
    printf("P(derecha):                %.8g\n", ocupacion_derecha);
    printf("Transiciones confirmadas:  %ld\n", transiciones_confirmadas);
    printf("Estancias completas izq:   %ld\n", estancias_izq);
    printf("Estancias completas der:   %ld\n", estancias_der);

    if (estancias_izq > 0) printf("Tiempo medio izquierda:    %.8g\n", tau_izq);
    else printf("Tiempo medio izquierda:    sin datos completos\n");

    if (estancias_der > 0) printf("Tiempo medio derecha:      %.8g\n", tau_der);
    else printf("Tiempo medio derecha:      sin datos completos\n");

    if (estancias_totales > 0) {
        printf("Tiempo medio global:       %.8g\n", tau_global);
        printf("k_sim = 1/tau_global:      %.8g\n", k_sim);
    } else {
        printf("Tiempo medio global:       sin datos completos\n");
    }

    if (estancias_totales < 30) {
        printf("[AVISO] Solo hay %ld estancias completas; la distribucion puede tener poca estadistica.\n",
               estancias_totales);
    }

    /* Fichero resumen para comparar A y eta posteriormente. */
    FILE *f_resumen = fopen(nombre_resumen, "w");

    if (f_resumen) {
        fprintf(f_resumen,
                "# h A eta XC P_izq P_der transiciones estancias_izq estancias_der tau_izq tau_der tau_global k_sim\n");
        fprintf(f_resumen,
                "%.12g %.12g %.12g %.12g %.12g %.12g %ld %ld %ld %.12g %.12g %.12g %.12g\n",
                paso_h, A, eta, xc, ocupacion_izquierda, ocupacion_derecha,
                transiciones_confirmadas, estancias_izq, estancias_der,
                tau_izq, tau_der, tau_global, k_sim);
        fclose(f_resumen);
    } else {
        printf("AVISO: No se pudo crear %s\n", nombre_resumen);
    }

    /************************************************/
    /************** CREAR FICHEROS ******************/
    /************************************************/
    printf("Guardando datos y creando histogramas en O%d...\n", flag_Objetivo);

    guardaEnergiasArray(nombre_metodo, paso_h, eta, t_energia, ek_array, ep_array, idx_energia);
    guardaTrayectoriaArray(nombre_metodo, paso_h, eta, t_medida, x_array, v_array, idx_medida);
    creaHistogramasArray(nombre_metodo, paso_h, eta, x_array, v_array, idx_medida);

    /************** LIBERAR RAM **********************/
    free(t_energia); free(ek_array); free(ep_array);
    free(t_medida); free(x_array); free(v_array);

    /************** INFORMACIÓN FINAL ***************/
    printf("\n=====================================\n");
    printf("SIMULACION TERMINADA\n");
    printf("=====================================\n");
    printf("Objetivo            : O%d\n", flag_Objetivo);
    printf("Metodo              : %s\n", nombre_metodo);
    printf("h                   : %g\n", paso_h);
    printf("A                   : %g\n", A);
    printf("eta                 : %g\n", eta);
    printf("XC analisis         : %g\n", xc);
    printf("Pasos termalizacion : %ld\n", (long)termSteps);
    printf("Pasos medida        : %ld\n", (long)numberSteps);
    printf("Guardado cada       : %ld pasos\n", guardar_cada_local);
    printf("Resolucion salida   : %g\n", guardar_cada_local * paso_h);
    printf("=====================================\n");

    return 0;
}
