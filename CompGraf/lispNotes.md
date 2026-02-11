# Notas de LISP

> [!NOTE] Recordar
> Variable `LISPSYS` debe estar configurada en `0` para ejecutar el editor Visual LISP

> [!TIP]
> Presionando F2 muestra el historial de la linea de comandos de AutoCAD

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

- [ ] Buscar programa de hacer mapas mentales
- [ ] Hacer reloj análogo/digital propio
- [ ] Documentar el proceso de realización del reloj
- [ ] Como tomar hora del sistema