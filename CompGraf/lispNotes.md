# Notas de LISP

> [!NOTE] Recordar
> Variable `LISPSYS` debe estar configurada en `0` para ejecutar el editor Visual LISP

> [!TIP]
> Presionando F2 muestra el historial de la linea de comandos de AutoCAD

- [X] Buscar programa de hacer mapas mentales
- [ ] Hacer reloj análogo/digital propio
- [ ] Documentar el proceso de realización del reloj
- [X] Como tomar hora del sistema
- [ ] Agregar `_` a comandos

---

## Guardar una variable

```lisp
(setq a 10)
```

Usando la palabra reservada `setq`, seguido del nombre de la variable, terminando con el valor a guardar. Se pueden guardar varias variables en un solo comando.

```lisp
(setq a 10 b "Bogota" c 7)
```

## Imprimir variables guardadas

```lisp
(print a)
```

Usando `print` muestra los valores 2 veces, porque se imprime y se lee a la vez. Para solo mostrar la variable por consultar:

```lisp
!a
```

Si se usa la consola en el editor de LISP, se puede consultar solo ingresando el nombre de la variable.

Se pueden realizar operaciones anidadas en los comandos, por ejemplo:

```lisp
(setq radio (*10 20))
```

> [!IMPORTANT] Dato
> LISP no distingue entre mayúsculas y minúsculas

## Ejecutar comandos específicos de AutoCAD

```lisp
(command ...)
```

Agregando `_` se toman los comandos para ejecutar en ingles, sin importar la configuración de idioma del AutoCAD.

```lisp
(command "_circle" "100,300" 500)
```

## Ver propiedades

Para ver las propiedades de algun elemento dibujado, se usa el comando `list`

## Mostrar todos los elementos dibujados

```lisp
(zoom "E")
```

`"E"` de `Extends` es una opción predeterminada de `zoom` para mostrar todo lo dibujado.

## Tipos de lineas

### Line

`line` dibuja lineas independientes, al ver propiedades se veran las de una sola línea al seleccionar.

### Pline

`pline` de "Polyline" deja todas las líneas dibujadas con el comando como una sola entidad, es decir, las propiedades se ven de forma agrupada.

***

## Obtener fecha y hora

Con el comando `cdate` se puede obtener la fecha y hora actual del equipo en el formato `AAAAMMDD.HHMMSScseg`.

```lisp
(setq fecha_hora (getvar "cdate"))
```

### Número a caracter

Se puede convertir a cadena de caracteres con `rtos`, aunque corta los segundos por defecto, para mostrar segundos:

```lisp
(setq fecha_hora_t (rtos fecha_hora 2 6))
```

Para sacar partes de la cadena de caracteres se puede usar `substr`, de sub-string.

```lisp
(setq año_t (substr fecha_hora_t 1 4))
(setq mes_t (substr fecha_hora_t 5 2))
(setq dia_t (substr fecha_hora_t 7 2))
(setq hora_t (substr fecha_hora_t 10 2))
(setq min_t (substr fecha_hora_t 12 2))
(setq seg_t (substr fecha_hora_t 14 2))
```

### Caracter a número

Usando la función `atoi`, se interpreta como "ASCII to Integer":

```lisp
(setq año (atoi año_t))
(setq mes (atoi mes_t))
(setq dia (atoi dia_t))
(setq hora (atoi hora_t))
(setq min (atoi min_t))
(setq seg (atoi seg_t))
```

## Cuadrar fecha y hora en el reloj

Se puede hace definiendo el ángulo de la manecilla correspondiente, hay que tener en cuenta que todas las manecillas cuentan su ángulo desde el eje horizontal, es decir, que con ángulo cero (0), todas las manecillas apuntan hacia la derecha, o hacia el tres (3) del reloj análogo

## Listas

Con comando `list` para crea listas, y se podria crear por ejemplo una lista que contenga los dias por més del año.

---

## Funciones

Usando la palabra clave `defun`, de la siguiente manera:

```lisp
(defun c:nombreFuncion ()
    ;Contenido de la función
)
```

```lisp
(defun reloj ()
    (print "RELOJ")
    (setq radio (/ 100 4))
)
```

## Para definir ángulos

```lisp
(defun c:reloj ()
    (setq angsegXs (/ 360 60.0)
          angminXm (/ 360 60.0)
          anghorXh (/ 360 12.0)
          angminXs (/ angminXm 60)
          anghorXm (/ anghorXh 60)
          anghorXs (/ anghorXm 60)
          )
)
```
## Obtener entrada de usuario

Usando el comando `getint` de la siguiente forma:

```lisp
(getint "Mesaje de muestra: ")
```

El anterior ejemplo mostrará en consola el mensaje `Mesaje de muestra: ` para que el usuario ingrese un valor, se puede combinar con `setq` para guardar la entrada de usuario como una variable.

## Ciclo de repetición

Con el comando `repeat` para definir un ciclo que se repita determinado número de veces, por ejemplo, para el reloj:

```lisp
(repeat n
    (command "_rotate" segundero "" "50,50" angsegXs)
)
```

## Retardos

Usando el comando `delay` para que el programa espere determinada cantidad de milisegundos, antes de pasar a la siguiente instrucción.

```lisp
(command "_delay" 1000) ;Retardo de 1 segundo
```

Éstas demoras pueden variar según la velocidad del PC. Para mejorar exactitud, revisar comandos `regen` y `redraw`

## Arreglos

Con el comando `array` se pueden dibujar las líneas de los alrededor del cuerpo del reloj.

- [ ] Ver como sacar el día de la semana para colocar en el reloj
- [ ] Para entrega del documento
  - [ ] Portada
  - [ ] Descripción del trabajo
  - [ ] Descripción de la matemática utilizada
  - [ ] Copia del código en el documento
  - [ ] Cómo cargar y correr el programa
  - [ ] Imágen final del reloj
  - [ ] Conclusiones del programa
  - [ ] Bibliografía

---

## Versión 2 del reloj

Las manecillas del reloj serán bloques