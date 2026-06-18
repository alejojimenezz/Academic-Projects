# Reconstrucción sala CAD

- [Reconstrucción sala CAD](#reconstrucción-sala-cad)
  - [Bloques](#bloques)
    - [Elementos](#elementos)
    - [Atributos](#atributos)
    - [Organización](#organización)
  - [Construcción](#construcción)
    - [Nombre de bloques](#nombre-de-bloques)
  - [Archivos .CSV y .TXT](#archivos-csv-y-txt)
  - [Programación Visual LISP](#programación-visual-lisp)

## Bloques

### Elementos

1. Límites del salón: `BASE.dwg`
2. Mesa: `MESA.dwg`
3. Escritorio: `ESCRITORIO.dwg`
4. Silla: `SILLA.dwg`
5. Monitor

### Atributos

1. Nombre: Atributo constante
2. Material
3. Color
4. Capacidad
5. Marca (sin usar)

### Organización

| Elemento   | Atributos                          | Cantidad |
| ---------- | ---------------------------------- | -------- |
| BASE       | Nombre                             | 1        |
| ESCRITORIO | Nombre, Material, Color            | 1        |
| MESA       | Nombre, Material, Color, Capacidad | 8        |
| SILLA      | Nombre, Color                      | 33       |

## Construcción

### Nombre de bloques

1. BASE: salon
2. ESCRITORIO: escritorioProfesor
3. MESA: mesaEstudiantes
4. SILLA: silla

## Archivos .CSV y .TXT

## Programación Visual LISP