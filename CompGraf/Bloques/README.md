# Reconstrucción sala CAD

- [Reconstrucción sala CAD](#reconstrucción-sala-cad)
  - [Bloques](#bloques)
    - [Elementos](#elementos)
    - [Atributos](#atributos)
    - [Organización](#organización)
  - [Construcción](#construcción)
    - [Nombre de bloques](#nombre-de-bloques)
  - [Programación Visual LISP](#programación-visual-lisp)
    - [Funciones](#funciones)

## Bloques

### Elementos

1. Límites del salón: `BASE.dwg`
2. Mesa: `MESA.dwg`
3. Escritorio: `ESCRITORIO.dwg`
4. Silla: `SILLA_v2.dwg`

### Atributos

1. Nombre: Atributo constante
2. Material
3. Color
4. Capacidad

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

## Programación Visual LISP

### Funciones

- CONFIGURARBLOQUES: Función para seleccionar bloques de AutoCAD desde el explorador de archivos, para guardarlos en memoria y poder ejecutar el armado del salon.
- REVISARBLOQUES: Función auxiliar para asegurar que las rutas de los bloques necesarios estan configurados correctamente.
- ARMARSALON: Función principal que toma los bloques en sus respectivas rutas y arma un boceto de la sala CAD del edificio de posgrados de materiales.

![BocetoSalaCAD](/CompGraf/Bloques/salaCAD.png)

- EXPORTARDATOS: Exporta la información de los bloques en el dibujo de AutoCAD a .CSV y .TXT.