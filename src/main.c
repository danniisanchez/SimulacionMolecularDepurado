#include "head.h"

int main(void) {

    /************** VARIABLES GENERALES **************/
    char nombre_metodo[20];
    double x = 0.0;
    double p = 0.0;
    double ek, ep;
    double sum_ek = 0.0;
    double sum_ep = 0.0;
    long pasos_energia = 0;

    // Calcular el tamaño máximo necesario para los arrays
    long max_datos_energia = (termSteps / guardar_cada) + 2;
    long max_datos_medida = (numberSteps / guardar_cada) + 2;

    // Reserva de memoria dinámica (malloc)
    double *t_energia = (double *)malloc(max_datos_energia * sizeof(double));
    double *ek_array = (double *)malloc(max_datos_energia * sizeof(double));
    double *ep_array = (double *)malloc(max_datos_energia * sizeof(double));

    double *t_medida = (double *)malloc(max_datos_medida * sizeof(double));
    double *x_array = (double *)malloc(max_datos_medida * sizeof(double));
    double *v_array = (double *)malloc(max_datos_medida * sizeof(double));

    if (!t_energia || !ek_array || !ep_array || !t_medida || !x_array || !v_array) {
        printf("ERROR: No hay memoria RAM suficiente para los arrays.\n");
        return 1;
    }

    long idx_energia = 0;
    long idx_medida = 0;

    /************** INICIALIZACIÓN ****************/
    ini_ran(seed);
    guardaAleatorios();

    switch(flag) {
        case 0: strcpy(nombre_metodo, "Euler"); break;
        case 1: strcpy(nombre_metodo, "RK2"); break;
        case 2: strcpy(nombre_metodo, "Verlet"); break;
        default: printf("ERROR: flag de integrador no valido.\n"); return 1;
    }

    /************************************************/
    /************** 1. TERMALIZACIÓN ****************/
    /************************************************/
    printf("Termalizando: metodo=%s  h=%g  eta=%g  Objetivo=O%d\n", nombre_metodo, paso_h, eta, flag_Objetivo);

    for (long i = 0; i < termSteps; i++) {
        
        /******** Integración ********/
        switch(flag) {
            case 0: paso_euler_maruyama(&x, &p); break;
            case 1: paso_rk2_estocastico(&x, &p); break;
            case 2: paso_verlet(&x, &p); break;
        }

        /******** Energías ********/
        ek = energia_cinetica(p);
        ep = energia_potencial(x);
        sum_ek += ek;
        sum_ep += ep;
        pasos_energia++;

        if (((i + 1) % guardar_cada == 0) || (i == termSteps - 1)) {
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

    long pasos_derecha = 0;
    long pasos_estancia = 0;
    int estado_actual = (x > 0.0) ? 1 : -1;
    FILE *f_tiempos = fopen("../../results/O2/tiempos_estancia.txt", "w");

    for (long i = 0; i < numberSteps; i++) {
        
        switch(flag) {
            case 0: paso_euler_maruyama(&x, &p); break;
            case 1: paso_rk2_estocastico(&x, &p); break;
            case 2: paso_verlet(&x, &p); break;
        }

        // --- CÁLCULO DE OCUPACIÓN Y TIEMPOS ---
        if (x > 0.0) pasos_derecha++;

        int nuevo_estado = (x > 0.0) ? 1 : -1;
        pasos_estancia++;

        if (nuevo_estado != estado_actual) {
            fprintf(f_tiempos, "%g\n", pasos_estancia * paso_h);
            pasos_estancia = 0;
            estado_actual = nuevo_estado;
        }
        // --------------------------------------

        if (((i + 1) % guardar_cada == 0) || (i == numberSteps - 1)) {
            t_medida[idx_medida] = (double)(i + 1) * paso_h;
            x_array[idx_medida] = x;
            v_array[idx_medida] = p / M;
            idx_medida++;
        }
    }
    
    fclose(f_tiempos);
    printf("Ocupacion x > 0: %.2f%%\n", 100.0 * pasos_derecha / numberSteps);
    printf("Ocupacion x < 0: %.2f%%\n", 100.0 * (numberSteps - pasos_derecha) / numberSteps);

    /************************************************/
    /************** CREAR FICHEROS *****************/
    /************************************************/

    printf("Guardando datos y creando histogramas en O%d...\n", flag_Objetivo);

    guardaEnergiasArray(nombre_metodo, paso_h, eta, t_energia, ek_array, ep_array, idx_energia);
    guardaTrayectoriaArray(nombre_metodo, paso_h, eta, t_medida, x_array, v_array, idx_medida);
    creaHistogramasArray(nombre_metodo, paso_h, eta, x_array, v_array, idx_medida);

    // Liberar la RAM (Inicializar arrays)
    free(t_energia); 
    free(ek_array); 
    free(ep_array);
    free(t_medida); 
    free(x_array); 
    free(v_array);

    /************************************************/
    /************** INFORMACIÓN FINAL ***************/
    /************************************************/
    
    printf("\n");
    printf("=====================================\n");
    printf("SIMULACION TERMINADA\n");
    printf("=====================================\n");
    printf("Objetivo          : O%d\n", flag_Objetivo);
    printf("Metodo            : %s\n", nombre_metodo);
    printf("h                 : %g\n", paso_h);
    printf("eta               : %g\n", eta);
    printf("Pasos termalizacion: %ld\n", (long)termSteps);
    printf("Pasos medida       : %ld\n", (long)numberSteps);
    printf("Energia guardada cada %ld pasos\n", guardar_cada);
    printf("x/v guardados cada %ld pasos\n", guardar_cada);
    printf("Resolucion salida energia : %g\n", guardar_cada * paso_h);
    printf("Resolucion salida x/v: %g\n", guardar_cada * paso_h);
    printf("=====================================\n");

    return 0;
}