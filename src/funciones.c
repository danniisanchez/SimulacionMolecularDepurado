#include "head.h"

// Nueva función para la fuerza del doble pozo
double fuerza(double x) {
    return -4.0 * A * x * (x * x - 1.0);
}

// Integrador Euler-Maruyama para el oscilador armónico
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

double energia_potencial(double x){
    // Potencial del doble pozo: V(x) = A*(x^2 - 1)^2
    return A * (x * x - 1.0) * (x * x - 1.0); 
}

void guardaEnergias(FILE *file,double t,double ek,double ep){
    fprintf(file,"%.8g %.8g %.8g %.8g\n",t,ek,ep,ek + ep);
}

void guardaPosiciones(FILE *file,double x) {
    fprintf(file,"%.8g\n",x);
}

void guardaVelocidades(FILE *file,double v) {
    fprintf(file,"%.8g\n",v);
}

void guardaTrayectoria(FILE *file, double t, double x, double v)
{
    fprintf(file, "%.8g %.8g %.8g\n", t, x, v);
}

void creaHistoPosiciones(char *nombre_metodo){
    char nombre_in[150];
    char nombre_out[150];
    
    sprintf(nombre_in, "results/O2/%s/datosPosiciones_%g_%g_%s.txt", nombre_metodo, paso_h, eta, nombre_metodo);
    sprintf(nombre_out, "results/O2/%s/HistogramaPosiciones_%g_%g_%s.txt", nombre_metodo, paso_h, eta, nombre_metodo);

    FILE *f_in = fopen(nombre_in, "r");
    if (f_in == NULL) {
        printf("Error: No se pudo abrir %s para leer.\n", nombre_in);
        return;
    }

    double x_val;
    double x_min = 0.0, x_max = 0.0;
    int num_datos = 0;

    while (fscanf(f_in, "%lf", &x_val) == 1) { //si devuelve 1 es que lee un numro
        if (x_val < x_min) x_min = x_val;
        if (x_val > x_max) x_max = x_val;
        num_datos++;
    }

    if (num_datos == 0) {
        fclose(f_in);
        return; 
    }

    // --- CONFIGURACIÓN DE INTERVALOS ---
    int cajas = 100;
    double dx = (x_max - x_min) / cajas;
    
    int hist[100] = {0}; // Inicializado a 0

    // --- SEGUNDA PASADA: Rebobinar y rellenar frecuencias ---
    fclose(f_in);
    f_in = fopen(nombre_in, "r");

    while (fscanf(f_in, "%lf", &x_val) == 1) {
        int cajai = (int)((x_val - x_min) / dx); 
        if (cajai == cajas) cajai--;               
        if (cajai >= 0 && cajai < cajas) {
            hist[cajai]++;
        }                          
    }
    fclose(f_in);

    // --- GUARDAR EL TXT DEL HISTOGRAMA ---
    FILE *f_out = fopen(nombre_out, "w");
    if (f_out != NULL) {
        for (int i = 0; i < cajas; i++) {
            double x_centro = x_min + i * dx + (dx / 2.0);
            double probabilidad = (double)hist[i] / (num_datos * dx); // Normalización
            fprintf(f_out, "%f %f\n", x_centro, probabilidad);
        }
        fclose(f_out);
    }
}

void creaHistoVelocidades(char *nombre_metodo){
    char nombre_in[150];
    char nombre_out[150];
    
    sprintf(nombre_in, "results/O2/%s/datosVelocidades_%g_%g_%s.txt", nombre_metodo, paso_h, eta, nombre_metodo);
    sprintf(nombre_out, "results/O2/%s/HistogramaVelocidades_%g_%g_%s.txt", nombre_metodo, paso_h, eta, nombre_metodo);

    FILE *f_in = fopen(nombre_in, "r");
    if (f_in == NULL) {
        printf("Error: No se pudo abrir %s para leer.\n", nombre_in);
        return;
    }

    double v_val;
    double v_min = 0.0, v_max = 0.0;
    int num_datos = 0;

    while (fscanf(f_in, "%lf", &v_val) == 1) { //si devuelve 1 es que lee un numro
        if (v_val < v_min) v_min = v_val;
        if (v_val > v_max) v_max = v_val;
        num_datos++;
    }

    if (num_datos == 0) {
        fclose(f_in);
        return; 
    }

    // --- CONFIGURACIÓN DE INTERVALOS ---
    int cajas = 100;
    double dv = (v_max - v_min) / cajas;
    
    int hist[100] = {0}; // Inicializado a 0

    // --- SEGUNDA PASADA: Rebobinar y rellenar frecuencias ---
    fclose(f_in);
    f_in = fopen(nombre_in, "r");

    while (fscanf(f_in, "%lf", &v_val) == 1) {
        int cajai = (int)((v_val - v_min) / dv); 
        if (cajai == cajas) cajai--;               
        if (cajai >= 0 && cajai < cajas) {
            hist[cajai]++;
        }                          
    }
    fclose(f_in);

    // --- GUARDAR EL TXT DEL HISTOGRAMA ---
    FILE *f_out = fopen(nombre_out, "w");
    if (f_out != NULL) {
        for (int i = 0; i < cajas; i++) {
            double v_centro = v_min + i * dv + (dv / 2.0);
            double probabilidad = (double)hist[i] / (num_datos * dv); // Normalización
            fprintf(f_out, "%f %f\n", v_centro, probabilidad);
        }
        fclose(f_out);
    }
}



void guardaAleatorios() {
    // Asegúrate de que la carpeta results existe
    FILE *file = fopen("results/O2/datos_aleatorios.txt", "w");
    if (file != NULL) {
        for(int i = 0; i < 50000; i++) {
            // Guardamos coordenadas (x, y) generando dos números seguidos
            fprintf(file, "%f %f\n", Random(), Random());
        }
        fclose(file);
        printf("Archivo de prueba de aleatoriedad generado con exito.\n");
    } else {
        printf("Error: No se pudo crear datos_aleatorios.txt\n");
    }
}