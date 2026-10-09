#include "head.h"

// Fuerza dependiendo del objetivo
double fuerza(double x) {
    if (flag_Objetivo == 1) {
        return -K * x; // Fuerza del oscilador armónico (Objetivo 1)
    } else {
        return -4.0 * A * x * (x * x - 1.0); // Fuerza del doble pozo (Objetivo 2)
    }
}

// Integrador Euler-Maruyama
void paso_euler_maruyama(double *x, double *p){
    double f_p, g_xp, zeta, Z, x_actual, p_actual;
    
    // Parte determinista de las ecuaciones de Langevin
    f_p = (*p) / M;
    g_xp = -eta * (*p) + fuerza(*x);
    
    // Parte estocástica (baño térmico)
    zeta = random_gaussiano();
    Z = sqrt(2.0 * eta * M * KBT * paso_h) * zeta;
    
    x_actual = *x;
    p_actual = *p;
    
    // Actualización de estado
    *x = x_actual + f_p * paso_h;
    *p = p_actual + g_xp * paso_h + Z;
}

//RK estocástico 2º orden
void paso_rk2_estocastico(double *x, double *p){
    double x_n, p_n, zeta, Z, f_x1, g_p1, f_x2, g_p2;
    // Estado inicial 
    x_n = *x;
    p_n = *p;
    
    // Término estocástico Z una sola vez por paso
    zeta = random_gaussiano();
    Z = sqrt(2.0 * eta * M * KBT * paso_h) * zeta;
    
    // Evaluaciones iniciales desplazadas por el ruido
    f_x1 = (p_n + Z) / M;
    g_p1 = -eta * (p_n + Z) + fuerza(x_n);
    
    // Evaluaciones secundarias usando la primera estimación
    f_x2 = (p_n + paso_h * g_p1) / M;
    g_p2 = -eta * (p_n + paso_h * g_p1) + fuerza(x_n + paso_h * f_x1);
    
    // Actualización promediando ambas evaluaciones
    *x = x_n + 0.5 * paso_h * (f_x1 + f_x2);
    *p = p_n + 0.5 * paso_h * (g_p1 + g_p2) + Z;
}

//Verlet explícito estocástico (Groenbech-Jensen)
void paso_verlet(double *x, double *p){
    // Variables actuales
    double x_n = *x;
    double p_n = *p;
    double v_n = p_n / M; 
    
    // Fuerza conservativa inicial
    double f_n = fuerza(x_n);
    
    double alpha = eta * M;
    
    // Coeficientes a y b del algoritmo de Grønbech-Jensen
    double denominador = 1.0 + (alpha * paso_h) / (2.0 * M);
    double a = (1.0 - (alpha * paso_h) / (2.0 * M)) / denominador;
    double b = 1.0 / denominador;
    
    // El término de ruido
    double zeta = random_gaussiano();
    double beta = sqrt(2.0 * alpha * KBT * paso_h) * zeta;
    
    //Avanza la posición al paso n+1
    double x_n_plus_1 = x_n + b * paso_h * v_n + (b * paso_h * paso_h / (2.0 * M)) * f_n + (b * paso_h / (2.0 * M)) * beta;
    *x = x_n_plus_1;
    
    //Evaluo la fuerza en la NUEVA posición
    double f_n_plus_1 = fuerza(x_n_plus_1);
    
    //Avanza la velocidad al paso n+1
    double v_n_plus_1 = a * v_n + (paso_h / (2.0 * M)) * (a * f_n + f_n_plus_1) + (b / M) * beta;
    
    //Velocidad de nuevo a momento (p = m*v) para mantener nuestra estructura
    *p = v_n_plus_1 * M;
}

double random_gaussiano(void){        
    double x1, x2;
    do{
        x1 = randomIn(0, 1);
    } while (x1 == 0);
    x2 = randomIn(0, 1);
    return -sqrt(-2.0 * log(x1)) * cos(2.0*PI*x2);
}

double energia_cinetica(double p){
    return (p * p) / (2.0 * M); 
}

// Energía potencial dependiendo del objetivo
double energia_potencial(double x){
    if (flag_Objetivo == 1) {
        return 0.5 * K * x * x; // Potencial armónico (Objetivo 1)
    } else {
        return A * (x * x - 1.0) * (x * x - 1.0); // Potencial de doble pozo (Objetivo 2)
    }
}

void guardaAleatorios() {
    char ruta[250];
    sprintf(ruta, "results/O%d/datos_aleatorios.txt", flag_Objetivo);
    FILE *file = fopen(ruta, "w");
    if (file != NULL) {
        for(int i = 0; i < 50000; i++) {
            fprintf(file, "%f %f\n", Random(), Random());
        }
        fclose(file);
        printf("Archivo de prueba de aleatoriedad generado con exito en O%d.\n", flag_Objetivo);
    } else {
        printf("Error: No se pudo crear %s\n", ruta);
    }
}

void guardaEnergiasArray(char *nombre_metodo, double h_val, double eta_val, double *t, double *ek, double *ep, long n) {
    char nombre_out[250];
    sprintf(nombre_out, "results/O%d/%s/datosEnergia_%g_%g_%s.txt", flag_Objetivo, nombre_metodo, h_val, eta_val, nombre_metodo);
    FILE *f = fopen(nombre_out, "w");
    if (f != NULL) {
        setvbuf(f, NULL, _IOFBF, 1024 * 1024); // Buffer grande para escritura rápida
        for (long i = 0; i < n; i++) {
            fprintf(f, "%.8g %.8g %.8g %.8g\n", t[i], ek[i], ep[i], ek[i] + ep[i]);
        }
        fclose(f);
    } else {
        printf("Error: No se pudo escribir %s\n", nombre_out);
    }
}

void guardaTrayectoriaArray(char *nombre_metodo, double h_val, double eta_val, double *t, double *x, double *v, long n) {
    char nombre_out[250];
    sprintf(nombre_out, "results/O%d/%s/datosTrayectoria_%g_%g_%s.txt", flag_Objetivo, nombre_metodo, h_val, eta_val, nombre_metodo);
    FILE *f = fopen(nombre_out, "w");
    if (f != NULL) {
        setvbuf(f, NULL, _IOFBF, 1024 * 1024);
        for (long i = 0; i < n; i++) {
            fprintf(f, "%.8g %.8g %.8g\n", t[i], x[i], v[i]);
        }
        fclose(f);
    } else {
        printf("Error: No se pudo escribir %s\n", nombre_out);
    }
}

void creaHistogramasArray(char *nombre_metodo, double h_val, double eta_val, double *x, double *v, long n) {
    if (n == 0) return;

    double x_min = x[0], x_max = x[0];
    double v_min = v[0], v_max = v[0];

    for (long i = 1; i < n; i++) {
        if (x[i] < x_min) x_min = x[i];
        if (x[i] > x_max) x_max = x[i];
        if (v[i] < v_min) v_min = v[i];
        if (v[i] > v_max) v_max = v[i];
    }

    int cajas = 100;
    double dx = (x_max - x_min) / cajas;
    double dv = (v_max - v_min) / cajas;

    int hist_x[100] = {0};
    int hist_v[100] = {0};

    for (long i = 0; i < n; i++) {
        int cajai_x = (int)((x[i] - x_min) / dx);
        if (cajai_x == cajas) cajai_x--;
        if (cajai_x >= 0 && cajai_x < cajas) hist_x[cajai_x]++;

        int cajai_v = (int)((v[i] - v_min) / dv);
        if (cajai_v == cajas) cajai_v--;
        if (cajai_v >= 0 && cajai_v < cajas) hist_v[cajai_v]++;
    }

    char nombre_out[250];
    sprintf(nombre_out, "results/O%d/%s/Histogramas_%g_%g_%s.txt", flag_Objetivo, nombre_metodo, h_val, eta_val, nombre_metodo);

    FILE *f_out = fopen(nombre_out, "w");
    if (f_out != NULL) {
        for (int i = 0; i < cajas; i++) {
            double x_centro = x_min + i * dx + (dx / 2.0);
            double prob_x = (double)hist_x[i] / (n * dx);

            double v_centro = v_min + i * dv + (dv / 2.0);
            double prob_v = (double)hist_v[i] / (n * dv);

            fprintf(f_out, "%f %f %f %f\n", x_centro, prob_x, v_centro, prob_v);
        }
        fclose(f_out);
    } else {
        printf("Error: No se pudo escribir %s\n", nombre_out);
    }
}