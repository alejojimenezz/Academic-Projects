# Reconocimiento de Lenguaje de Señas Colombiano (LSC)

Este proyecto tiene como objetivo implementar un sistema de reconocimiento de lenguaje de señas colombiano (LSC) en lenguaje de programación Python; usando la camara web del computador como sensor óptico, procesamiento de imágenes en tiempo real usando la librería OpenCV, y reconocimiento y ubicación de puntos de interés (keypoints) de la mano con la librería Mediapipe.

## Lenguaje

### [Python](https://www.python.org/downloads/)

Versión 3.11.

La versión utilizada de python para implementar el proyecto es la 3.11. Compatible con las librerias necesarias para ejecutar el programa.

## Librerias

### [Mediapipe](https://ai.google.dev/edge/mediapipe/solutions/guide?hl=es-419)

`pip install mediapipe`

Version 0.10.21

Paquete de bibliotecas y herramientas de python enfocada en tecnicas de inteligencia artificial y aprendizaje automático. Usada, en este proyecto para la detección de puntos de referencia de la mano.

![Puntos de la mano](/reconLSC/assets/keypoints.png)

### [OpenCV](https://docs.opencv.org/4.x/d6/d00/tutorial_py_root.html) (cv2)

`pip install opencv-python`

Version 4.13.0

Open Source Computer Vision. Libreria de python aprovechada para capturar el video de la camara web, generando la interfaz gráfica básica del programa.

## Archivos

### Alfabeto - [alphabet.py](/alphabet.py)

1. Modulo de definición del mapa de la mano siguiendo la documentación de [Mediapipe](#Mediapipe).
2. Funciones de identificación de cada gesto correspondiente al abecedario del lenguaje de señas colombiano ([LSC](https://educativo.insor.gov.co/catdiccionario/alfabeto/)).
3. Diccionario de letras para el llamado desde [main.py](/main.py)

### Limitador de cuadro - [limitFrame.py](/limitFrame.py)

Módulo con función auxiliar usando la librería OpenCV para limitar el cuadro a ser procesado por Mediapipe según el color hallado, para el caso de este proyecto, color de la piel; además de reducir el ruido del fondo que tome la cámara.

### Prueba de camara - [camTest.py](/camTest.py)

Primera prueba del funcionamiento del programa con llamado en un solo archivo.

### Prueba de libreria - [pipLibTest.py](/pipLibTest.py)

Archivo para pruebas de funcionamiento de requisitos de las librerias usadas.

### Prueba de nueva letra - [newLetterTest.py](/newLetterTest.py)

Archivo para pruebas de letras ya incluidas, o aun sin incluir, para mejorar su reconocimiento, sensibilidad, o definición del gesto para hacerlo más acertado.

### Principal - [main.py](/main.py)

Archivo ejecutable del proyecto donde se llama el [alfabeto](#Alfabeto) y se forma la ventana de funcionamiento del programa de reconocimiento de LSC.

## Ejecución

Para ejecutar los archivos, es necesario instalar el lenguaje Python, y las librerias previamente mencionadas, además de Numpy para las operaciones matemáticas.

El único archivo necesario para observar el funcionamiento del programa es `main.py`; dicho archivo hace el llamado a los módulos `alphabet.py` y `limitFrame.py`.