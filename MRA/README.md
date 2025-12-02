# Proyecto - Métodos Numéricos

**Resolución de frecuencias naturales por métodos numéricos**

## [Función de análisis](systemFunc.py)

Determinamos la función para determinar la frecuencia natural de un sistema Masa-Resorte-Amortiguador, con su respectiva derivada para usar en los métodos donde corresponda usarla.

## Archivos de métodos numéricos

Los métodos implementados en el programa son los siguientes:

- [Bisección](biseccion.py)
- [Posición falsa](posFalsa.py)
- [Newton-Raphson](newtonRaphson.py)

## Ejecución del programa

Cada archivo tiene su respectivo "`if __name__ == "__main__:"`" para ejecución independiente facilitando la depuración.

El archivo principal, que ejecuta el programa completo con interfaz gráfica para facilitar el uso por cualquier usuario en [main.py](main.py); éste archivo al ejecutarse, llama a cada función, permitiendo obtener los resultados de cada método para obtener la frecuencia natural del sistema Masa-Resorte-Amortiguador, además de brindar información sobre el error que genera el método, junto con la cantidad de iteraciones que tomó para llegar a dicho error.

Los usuarios tendran la posibilidad de cambiar con facilidad los parámetros del sistema a analizar, número máximo de iteraciones a ejecutar, y error mínimo que se busca.