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

1. Nombre
2. Marca
3. Color
4. Material
5. Cantidad
6. Precio

### Organización

| Elemento   | Atributos               |
| ---------- | ----------------------- |
| BASE       | Nombre                  |
| ESCRITORIO | Nombre, Material, Color |
| MESA       | Nombre, Material, Color |
| SILLA      | Nombre, Material, Color |

## Construcción

### Nombre de bloques

1. BASE: salon

## Archivos .CSV y .TXT

## Programación Visual LISP