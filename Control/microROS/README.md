# Proyecto Control

> Yahboom microROS - Robot de auto-balance

> [!NOTE] Estudiantes
> - Alejandro Jiménez Zabala
> - Jose Luis Ocoro Banguera

- [Proyecto Control](#proyecto-control)
  - [Documentación](#documentación)
    - [**Página web** Yahboom](#página-web-yahboom)
      - [Secciones de interes](#secciones-de-interes)
    - [Software necesario](#software-necesario)
      - [**FlyMcu**](#flymcu)
      - [**Keil uVision 5**](#keil-uvision-5)
    - [Aplicación movil](#aplicación-movil)
  - [Controlador LQR](#controlador-lqr)
    - [Constantes K de fábrica](#constantes-k-de-fábrica)
    - [Constantes K diseñados](#constantes-k-diseñados)
  - [Controlador PID](#controlador-pid)
    - [Constantes K de fábrica](#constantes-k-de-fábrica-1)
    - [Constantes K diseñados](#constantes-k-diseñados-1)

## Documentación

### **Página web** [Yahboom](https://www.yahboom.net/study/SBR-microROS)

#### Secciones de interes

- 03-0: Inicio rápido
- 03-1: Cargar firmware — Instrucciones para instalación de [FlyMcu](#software-necesario)
- 12-01-01: Instalación de MDK-ARM — Instrucciones para instalación de [Keil uVision 5 y compilador](#software-necesario).

### Software necesario

#### **FlyMcu**
Software para subir los archivos compilados .hex a la tarjeta STM32 del robot. Para hacer modificaciones del controloador, solo es necesario modificar el firmware de la STM32.

![FlyMcuScreenhsot](/Control/microROS/FlyMcuSS_2.jpeg)

1. `EnumPort` para actualizar la lista de puertos USB dado el caso que no reconozca automáticamente la conexión por USB al STM32.
2. Seleccionar el puerto al que está conectado el robot (`USB-SERIAL CH340K`).
3. En `...` seleccionar el archivo .hex que se desea probar en la ruta que está guardado en el computador.
   > [!WARNING] Tener en cuenta:
   > Los archivos .hex son guardados en la carpeta "OBJ" de las carpetas de los proyectos **despues** de ser compilados.
4. Pasar a la pestaña de opciones `STM ISP`
5. En el menú desplegable seleccionar la opción `Reset@DTR Low(<-3V),ISP@RTS High`
6. Presionar el botón `Start ISP(P)`

#### **Keil uVision 5**
IDE para las ediciones de los controladores, y compilación de los proyectos.

![Keil Screenshot](/Control/microROS/KeilSS_2.jpeg)

1. En en el boton de la barra superior `Project` se encuentra la opción para abrir un proyecto trabajado como los descargados por el fabricante.
   > [!WARNING] Tener en cuenta:
   > El archivo que abre el proyecto en el software Keil uVision es de extensión `.uvprojx`, el cual se encuentra en la carpeta "USER" de los proyectos.
2. Ejecutar el comando `Options for target`, el cual abre la siguiente ventana:
![Keil Screenshot](/Control/microROS/KeilSS_3.jpeg)
En esta ventana se debe configurar el `ARM Compiler` que se haya descargado en la instalación del software (Si se siguieron los pasos correctamente, debería incluir dicho compilador, de lo contrario, se puede descargar por aparte en la página oficial del fabricante)
3. Despues de hacer las ediciones necesarias a los códigos, se podrá ejecutar el comando `Build`, para la reconstrucción del proyecto, y obtener el archivo .hex que requiere el software FlyMcu.

### Aplicación movil

- **BalanceBot** - Solo disponible en Android

![QR de descarga de la app](/Control/microROS/appQR.jpeg)

La aplicación oficial para descargar se encuentra en lenguaje chino, a continuación se ve un pantallazo de la pagina principal de la aplicación:

![appScreenshot](/Control/microROS/appSS.jpeg)

Nos apoyamos de herramientas de inteligencia artificial para traducir los pantallazos de la aplicación y facilitar la navegación a través de esta:

![appScreenshot](/Control/microROS/appSS_ES.jpeg)

Para poder hacer pruebas de Bluetooth del robot, se deben conceder los permisos de acceso que solicite la aplicación.

Ya dentro de la aplicación, se podrá presionar el botón `Buscar Bluetooth`, seguido del botón `Conectar`, al mostrar en el recuadro central de la barra superior el nombre del equipo (en el caso de la imágen "YahBoom_BL") significará que se pudo conectar satisfactoriamente, y se podrán controlar los movimientos del robot usando el celular.

> [!DANGER] Ojo:
> Si se encuentra en la cercanía de otro equipo robot MicroROS, con características de conexión bluetooth similares, se podrían generar interferencias de conexión complicando el manejo con el celular

Se tiene tambien otras dos vistas de interés entre la aplicación, para la sintonización PID, y para la visualización de forma de onda:

![appScreenshot2](/Control/microROS/appSS2_ES.jpeg)
![appScreenshot3](/Control/microROS/appSS3_ES.jpeg)

## Controlador LQR

### Constantes K de fábrica

```c
float K1= -62.0484, K2= -73.3232, K3=-361.4617, K4=-35.9024 , K5=15.8114, K6=15.8114;
float K5OLD=15.8114, K6OLD=15.8114;
```

### Constantes K diseñados

```c
float K1= -3.3991, K2= -14.5204, K3=-300.4103, K4=-15.3126, K5=0.06798, K6=0.26011;
float K5OLD=0.11775, K6OLD=0.343274;
```

## Controlador PID

Para el caso de este controlador, en el código proporcionado por el fabricante, se tienen 3 lazos:

- Balance / Angulo: Lazo PD
- Velocidad: Lazo PI
- Giro: Lazo PD

Para el caso del controlador de giro, a éste no se le aplican cambios, siguiendo la sugerencia del fabricante que éste puede ser dejado sin alterar, ya que solo variaría la velocidad en la que gira el robot, por lo que el enfoque está en el diseño de los dos primeros lazos (Balance y Velocidad).

### Constantes K de fábrica

```c
//PD
//Vertical loop PD control parameters
float Balance_Kp =10200;//0-288 Range 0-288
float Balance_Kd =78; //0-2 Range 0-2

//PI
//PI control parameters for speed loop
float Velocity_Kp=7000; //0-72 Range 0-72 6000
float Velocity_Ki=35;  //kp/200
```

### Constantes K diseñados

```c
//PD
//Vertical loop PD control parameters
float Balance_Kp =25.57;//0-288 Range 0-288
float Balance_Kd =0.864; //0-2 Range 0-2

//PI
//PI control parameters for speed loop
float Velocity_Kp=71.95; //0-72 Range 0-72 6000
float Velocity_Ki=44.97;  //kp/200
```