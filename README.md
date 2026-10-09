
Para utilizar el programa hay que cambiar los valores de paso_h y eta en el head. Asi como 
el numero de steps que queramos tanto para termlalizar como para medir. En head tambien se elegira el metodo que se quiera emplear, que se usara tantas veces como tiempo de simulacion hayamos
elegido (primero para termalizar y despues para medir). Una vez ejecutado se crearan los ficheros
en results (uno guarda las energias, otro posiciones, otro velocidades y dos mas para poder
representar los histogramas que han sido calculados a partir de los ficheros de posiciones y velocidades con el metodo crearHisto). Con los archivos ya se puede representar pero  hay que acordarse de cambiar en los scripts de gnuplot el metodo, eta y h que se ha utilizado. Aopareceran los plots en la carpeta plots en el directorio correspondiente.
El generador de numeros aleatorios de random.c es Parisi-Rapuano.

Con todo esto y con las simulaciones hechas en todos los casos vemos que la opcion mas eficiente es: