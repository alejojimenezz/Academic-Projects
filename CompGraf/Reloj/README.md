# Reloj análogo-digital

> [!NOTE] Elaborado por:
> ***Alejandro Jiménez Zabala***

> [!TIP] Recordar:
> - [X] Finalizar el programa con `Zoom - Extends`, para visualizar todo lo dibujado
> - [ ] Incorporar entrada de usuario para poner en funcionamiento el reloj
> - [X] Nombrar elementos como variable para facilitar manipulación
> - [X] Agregar "_" a comandos para ejecución desde cualquier equipo configurado con cualquier idioma
> - [X] Mejorar cálculos de los ángulos para ajuste inicial de la hora
> - [ ] Agregar visualización final del reloj al README

- [Reloj análogo-digital](#reloj-análogo-digital)
  - [Introducción](#introducción)
  - [Mapa mental](#mapa-mental)
  - [Desarrollo](#desarrollo)
    - [Cuerpo base del reloj](#cuerpo-base-del-reloj)
    - [Obtener hora](#obtener-hora)
    - [Ajuste a hora obtenida](#ajuste-a-hora-obtenida)
  - [Ejecución](#ejecución)
    - [Método 1](#método-1)
    - [Método 2](#método-2)

## Introducción

Haciendo uso del programa de AutoDesk, AutoCAD, se puede usar el lenguaje LISP para programación y visualización de un reloj análogo-digital, que muestre la misma hora del sistema, y se actualice debidamente cada segundo.

## Mapa mental

```mermaid
mindmap
  Root [**Reloj análogo-digital**]
    Cuerpo principal
      Límites exteriores
      Punto central
      Manecillas del reloj
      Recuadros de digital
      Líneas de division
    Hora del sistema
      Tomar hora del equipo
        Actualizar posición de las manijas con la hora actual
        Actualizar texto de reloj digital
    Movimiento grados x segundo
      Segundero
        360/60 = 6
      Minutero
        360/60/60 = 0.1
      Horario
        360/12/60/60 = 0.0083
```

## Desarrollo

Se define el programa como una función para ser ejecutado cuando sea llamado como un comando, es decir, evitando que se ejecute automáticamente solo al cargar el programa, dicha función se deja definida con el nombre `reloj`.
Además, como configuración previa, se apaga el `osnap` para que no hayan inconsistencias entre lo definido en el programa y en el dibujo, y se borra todo lo que haya sido previamente dibujado en AutoCAD previo a la ejecución del programa del reloj.

### Cuerpo base del reloj

![Cuerpo base del reloj](/CompGraf/Reloj/base.png)

### Obtener hora

`(getvar "cdate")` retorna la hora actual de la forma `AAAAMMDD.HHMMSScseg`.

### Ajuste a hora obtenida

Los recuadros "digitales" se actualizan con la hora y la fecha actual del sistema, y las manecillas análogas se ajustan al ángulo según dicha hora; teniendo en cuenta que el horario y el minutero se les suma un ángulo más pequeño, según los segundos que ya hayan transcurrido de la hora y del minuto correspondientes.

## Ejecución

### Método 1

En la pestaña `Manage` de la ventana de AutoCAD, se encuentra una opción `Visual LISP Editor`.
Dentro del editor se puede abrir el [programa del reloj](/CompGraf/Reloj/reloj.lsp), y ejecutar dentro de esta misma ventana con la opción de `Load Current Window`.

### Método 2

En la ventana activa de AutoCAD se puede ejecutar el comando `APPLOAD`, el cuál abre una nueva ventana para cargar aplicaciones personalizadas.
En la ventana emergente, se puede buscar la ubicación de la [aplicación](/CompGraf/Reloj/reloj.lsp) dentro del sistema, se selecciona, y se presiona `LOAD`; posteriormente se puede cerrar ésta ventana.
Si el procedimiento se hizo correctamente, se puede ejecutar la aplicación de la misma manera que se hace cualquier otro comando, escribiendo el nombre de la aplicación `reloj`.