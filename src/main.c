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


    /*
     * Resolución temporal que queremos GUARDAR.
     *
     * IMPORTANTE:
     * esto NO cambia el paso de integración.
     *
     * Ejemplo:
     *
     * h = 0.1    -> guardamos cada 1 paso
     * h = 0.01   -> guardamos cada 10 pasos
     * h = 0.001  -> guardamos cada 100 pasos
     * h = 0.0001 -> guardamos cada 1000 pasos
     */

    const double dt_salida_energia = 1.0;
    const double dt_salida_medidas = 1.0;

    long guardar_energia_cada =
        lround(dt_salida_energia / paso_h);

    long guardar_medidas_cada =
        lround(dt_salida_medidas / paso_h);


    /* Protección para h > dt_salida */

    if (guardar_energia_cada < 1)
        guardar_energia_cada = 1;

    if (guardar_medidas_cada < 1)
        guardar_medidas_cada = 1;


    /************** INICIALIZACIÓN ****************/

    ini_ran(seed);

    // Generamos la prueba de aleatoriedad
    guardaAleatorios();

    switch(flag) {

        case 0:
            strcpy(nombre_metodo, "Euler");
            break;

        case 1:
            strcpy(nombre_metodo, "RK2");
            break;

        case 2:
            strcpy(nombre_metodo, "Verlet");
            break;

        default:
            printf("ERROR: flag de integrador no valido.\n");
            return 1;
    }


    /************** NOMBRES DE ARCHIVOS **************/

    char nombreEnergia[250];
    char nombrePosiciones[250];
    char nombreVelocidades[250];
    char nombreTrayectoria[250];

    snprintf(nombreEnergia,sizeof(nombreEnergia),"results/O2/%s/datosEnergia_%g_%g_%s.txt",
        nombre_metodo,paso_h,eta,nombre_metodo);


    snprintf(nombrePosiciones,sizeof(nombrePosiciones),
    "results/O2/%s/datosPosiciones_%g_%g_%s.txt",nombre_metodo,paso_h,eta,nombre_metodo);

    snprintf(nombreVelocidades,sizeof(nombreVelocidades),
    "results/O2/%s/datosVelocidades_%g_%g_%s.txt",nombre_metodo,paso_h,eta,nombre_metodo);
    
    snprintf(nombreTrayectoria,sizeof(nombreTrayectoria),
    "results/O2/%s/datosTrayectoria_%g_%g_%s.txt",nombre_metodo,paso_h,eta,nombre_metodo);

    /************** ABRIR ARCHIVOS ****************/

    /*
     * "w" reemplaza solamente la simulación con
     * EXACTAMENTE el mismo método, h y eta.
     *
     * Los demás h permanecen porque tienen nombres
     * de archivo diferentes.
     */

    FILE *fEnergia =fopen(nombreEnergia, "w");

    FILE *fPosiciones =fopen(nombrePosiciones, "w");

    FILE *fVelocidades =fopen(nombreVelocidades, "w");

    FILE *fTrayectoria = fopen(nombreTrayectoria, "w");

    if (fEnergia == NULL || fPosiciones == NULL || fVelocidades == NULL || fTrayectoria == NULL) {

        printf("ERROR: no se pudieron abrir los archivos.\n");

        if (fEnergia != NULL)
            fclose(fEnergia);

        if (fPosiciones != NULL)
            fclose(fPosiciones);

        if (fVelocidades != NULL)
            fclose(fVelocidades);

        if (fTrayectoria != NULL)
            fclose(fTrayectoria);

        return 1;
    }


    /*
     * Buffer de 1 MB.
     *
     * fprintf escribe primero en memoria y el sistema
     * vuelca bloques grandes al disco.
     */

    setvbuf(fEnergia,NULL,_IOFBF,1024 * 1024);

    setvbuf(fPosiciones,NULL,_IOFBF,1024 * 1024);

    setvbuf(fVelocidades,NULL,_IOFBF,1024 * 1024);

    setvbuf(fTrayectoria,NULL,_IOFBF,1024 * 1024);

    /************************************************/
    /************** 1. TERMALIZACIÓN ****************/
    /************************************************/

    printf("Termalizando: metodo=%s  h=%g  eta=%g\n",nombre_metodo,paso_h,eta);


    for (long i = 0; i < termSteps; i++) {

        /******** Integración ********/

        switch(flag) {

            case 0:
                paso_euler_maruyama(&x, &p);
                break;

            case 1:
                paso_rk2_estocastico(&x, &p);
                break;

            case 2:
                paso_verlet(&x, &p);
                break;
        }


        /******** Energías ********/

        ek = energia_cinetica(p);
        ep = energia_potencial(x);

        sum_ek += ek;
        sum_ep += ep;

        pasos_energia++;


        /*
         * Como ya hemos realizado el paso i,
         * el estado corresponde a t=(i+1)h.
         */

        double t =(double)(i + 1) * paso_h;


        /*
         * IMPORTANTE:
         *
         * Las medias utilizan TODOS los pasos.
         *
         * Solo reducimos cuántas veces se escriben
         * en el archivo.
         */

        if (((i + 1) % guardar_energia_cada == 0)||(i == termSteps - 1)) {
            guardaEnergias(fEnergia,t,sum_ek / (double)pasos_energia,sum_ep / (double)pasos_energia);
        }
    }


    printf("Termalizacion terminada.\n");


    /************************************************/
    /************** 2. FASE DE MEDIDA ***************/
    /************************************************/

    printf("Iniciando fase de medida...\n");


    for (long i = 0; i < numberSteps; i++) {

        /******** Integración ********/

        switch(flag) {

            case 0:
                paso_euler_maruyama(&x, &p);
                break;

            case 1:
                paso_rk2_estocastico(&x, &p);
                break;

            case 2:
                paso_verlet(&x, &p);
                break;
        }


        /*
         * Seguimos integrando TODOS los pasos.
         *
         * Pero no necesitamos guardar x y v
         * en cada uno.
         */

        if (((i + 1) % guardar_medidas_cada == 0) ||(i == numberSteps - 1)) {
        double v = p / M;

    /*
     * Tiempo desde el inicio de la fase de medida.
     * t=0 corresponde aproximadamente al final
     * de la termalización.
     */
        double t_medida = (double)(i + 1) * paso_h;
        guardaPosiciones(fPosiciones, x);
        guardaVelocidades(fVelocidades, v);
        guardaTrayectoria(fTrayectoria,t_medida,x,v);
        }
    }


    /************************************************/
    /************** CERRAR ARCHIVOS *****************/
    /************************************************/

    fclose(fEnergia);
    fclose(fPosiciones);
    fclose(fVelocidades);
    fclose(fTrayectoria);

    /************************************************/
    /************** HISTOGRAMAS *********************/
    /************************************************/

    printf("Creando histogramas...\n");

    creaHistoPosiciones(nombre_metodo);

    creaHistoVelocidades(nombre_metodo);


    /************************************************/
    /************** INFORMACIÓN FINAL ***************/
    /************************************************/

    printf("\n");
    printf("=====================================\n");
    printf("SIMULACION TERMINADA\n");
    printf("=====================================\n");

    printf("Metodo            : %s\n",nombre_metodo);

    printf("h                 : %g\n",paso_h);

    printf("eta               : %g\n",eta);

    printf("Pasos termalizacion: %ld\n",(long)termSteps);

    printf("Pasos medida       : %ld\n",(long)numberSteps);

    printf("Energia guardada cada %ld pasos\n",guardar_energia_cada);

    printf("x/v guardados cada %ld pasos\n",guardar_medidas_cada);

    printf("Resolucion salida energia : %g\n",guardar_energia_cada * paso_h);

    printf("Resolucion salida x/v: %g\n",guardar_medidas_cada * paso_h);
    printf("=====================================\n");
    return 0;}