;;; ============================================================================
;;; ARMAR_SALON.LSP
;;; Rutina para armar un salon de clases usando 4 bloques que estan cada uno
;;; en su PROPIO archivo .dwg separado (ej. resultado de WBLOCK):
;;;   BASE.dwg       -> atributo NOMBRE                              (1)
;;;   ESCRITORIO.dwg -> atributos NOMBRE, MATERIAL, COLOR            (1)
;;;   MESA.dwg       -> atributos NOMBRE, MATERIAL, COLOR, CAPACIDAD (8)
;;;   SILLA.dwg      -> atributos NOMBRE, COLOR                      (33 = 8x4 + 1 profesor)
;;;
;;; COMANDOS DISPONIBLES:
;;;   CONFIGURARBLOQUES  -> (correr UNA vez por sesion) pide la ruta de cada
;;;                         uno de los 4 archivos .dwg
;;;   REVISARBLOQUES     -> confirma que las 4 rutas esten configuradas y
;;;                         que los archivos existan en disco
;;;   ARMARSALON         -> arma el salon completo
;;;
;;; NOTA SOBRE TAGS DE ATRIBUTO:
;;;   Este script asume que los tags son "NOMBRE","MATERIAL","COLOR",
;;;   "CAPACIDAD". Si tus atributos usan otros tags, cambia los strings
;;;   dentro de las listas (cons "TAG" "valor") mas abajo.
;;; ============================================================================

(vl-load-com)

;; ---------------------------------------------------------------------------
;; FUNCION AUXILIAR: inserta un bloque (por nombre YA definido, o por RUTA
;; completa a un .dwg externo -> AutoCAD lo importa e inserta en un solo paso)
;; y le asigna atributos por TAG.
;; ---------------------------------------------------------------------------
(defun InsertaBloque (nombreOrRuta pto escala rot listaAtrib
                       / doc esp blkRef atributos tagBuscado valorAsignar att)
  (setq doc (vla-get-ActiveDocument (vlax-get-acad-object)))
  (setq esp (vla-get-ModelSpace doc))
  (setq blkRef (vla-InsertBlock esp (vlax-3d-point pto) nombreOrRuta
                                 escala escala escala rot))
  (if (and listaAtrib (= (vla-get-HasAttributes blkRef) :vlax-true))
    (progn
      (setq atributos (vlax-invoke blkRef 'GetAttributes))
      (foreach par listaAtrib
        (setq tagBuscado   (strcase (car par)))
        (setq valorAsignar (cdr par))
        (foreach att atributos
          (if (= (strcase (vla-get-TagString att)) tagBuscado)
            (vla-put-TextString att valorAsignar)
          )
        )
      )
    )
  )
  blkRef
)

;; ---------------------------------------------------------------------------
;; COMANDO: CONFIGURARBLOQUES
;; Pide la ruta de cada uno de los 4 archivos .dwg y la guarda en variables
;; globales para toda la sesion (no hace falta repetirlo salvo que cierres
;; y vuelvas a abrir AutoCAD, o quieras cambiar de archivos).
;; ---------------------------------------------------------------------------
(defun c:CONFIGURARBLOQUES ()
  (setq *RUTA-BASE*
    (getfiled "Selecciona el archivo BASE.dwg" "" "dwg" 16))
  (setq *RUTA-ESCRITORIO*
    (getfiled "Selecciona el archivo ESCRITORIO.dwg" "" "dwg" 16))
  (setq *RUTA-MESA*
    (getfiled "Selecciona el archivo MESA.dwg" "" "dwg" 16))
  (setq *RUTA-SILLA*
    (getfiled "Selecciona el archivo SILLA.dwg" "" "dwg" 16))
  (princ "\nRutas configuradas. Corre REVISARBLOQUES para confirmar.")
  (princ)
)

;; ---------------------------------------------------------------------------
;; COMANDO: REVISARBLOQUES
;; Confirma que las 4 rutas esten configuradas y que los archivos existan.
;; ---------------------------------------------------------------------------
(defun c:REVISARBLOQUES (/ pares p)
  (setq pares
    (list (cons "BASE"       '*RUTA-BASE*)
          (cons "ESCRITORIO" '*RUTA-ESCRITORIO*)
          (cons "MESA"       '*RUTA-MESA*)
          (cons "SILLA"      '*RUTA-SILLA*))
  )
  (foreach p pares
    (setq val (eval (cdr p)))
    (cond
      ((not val)
       (princ (strcat "\n[FALTA]  " (car p) " -> no configurado. Corre CONFIGURARBLOQUES.")))
      ((not (findfile val))
       (princ (strcat "\n[ERROR]  " (car p) " -> la ruta guardada ya no existe: " val)))
      (t
       (princ (strcat "\n[OK]     " (car p) " -> " val)))
    )
  )
  (princ)
)


;;; ---------------------------------------------------------------------------
;;; COMANDO PRINCIPAL: ARMARSALON
;;;
;;; ESTRUCTURA DEL SALON (de izquierda a derecha, segun el boceto):
;;;   [Col1: 6 sillas] [Zona1: 3 mesas] [Col2+Col3: 6+6 sillas] [Zona2: 3 mesas]
;;;   [Col4+Col5: 4+4 sillas] [Zona3: 2 mesas] [Col6: 4 sillas]
;;;
;;;   Las sillas de cada columna se apilan verticalmente (una fila detras de
;;;   otra), separadas por ESPACIADO-SILLA cm.
;;;   Las mesas de cada zona se apilan verticalmente "pegadas" (una detras de
;;;   otra sin espacio), cada una ocupa PROF-MESA cm de profundidad.
;;;
;;;   Todas las coordenadas X y Y de esta seccion estan en CENTIMETROS y se
;;;   escalan automaticamente segun FACTOR-COORD (ver mas abajo) para que
;;;   calcen con las unidades reales de tu dibujo (mm, cm, m, etc).
;;; ---------------------------------------------------------------------------
(defun c:ARMARSALON (/ ESC PTO-BASE FACTOR-COORD ANCHO-SILLA PROF-SILLA
                       ANCHO-MESA PROF-MESA ESPACIADO-SILLA Y-ORIGEN
                       ROT-DER ROT-IZQ contadorSilla contadorMesa
                       InsertaColumnaSillas InsertaZonaMesas)

  ;; Limpiar definiciones de bloque SIN USAR antes de importar de nuevo.
  ;; Esto evita que se reutilice una version vieja/corrupta de un bloque
  ;; (ej. "silla" autorreferenciado) que haya quedado guardada en este
  ;; archivo .dwg de una corrida anterior fallida. OJO: solo purga bloques
  ;; que no tengan ninguna referencia insertada en el dibujo -> si ya
  ;; insertaste algo con el bloque corrupto antes y no lo borraste, esto
  ;; no lo va a limpiar (borra esas inserciones primero, o mejor arranca
  ;; en un dibujo nuevo en blanco).
  (command "_.-PURGE" "_A" "*" "_N")
  (command "_.-PURGE" "_A" "*" "_N")   ; segunda pasada por bloques anidados

  ;; Verificar que las rutas esten configuradas antes de seguir
  (if (not (and *RUTA-BASE* *RUTA-ESCRITORIO* *RUTA-MESA* *RUTA-SILLA*))
    (progn
      (princ "\nFalta configurar las rutas de los bloques. Corriendo CONFIGURARBLOQUES...")
      (c:CONFIGURARBLOQUES)
    )
  )

  (setq ESC 1.0)                         ; factor de escala de insercion (tamano del bloque)
  (setq PTO-BASE (list 0.0 0.0 0.0))     ; esquina inf-izq del salon (ajustar)

  ;; ---------------------------------------------------------------------
  ;; FACTOR-COORD: TODAS las coordenadas de este script (mesas, sillas,
  ;; escritorio) estan escritas en CENTIMETROS, tal como las medidas del
  ;; boceto original. Si tu dibujo esta en milimetros, pon 10.0 aqui.
  ;; Si tu dibujo esta en metros, pon 0.01. Si esta en centimetros, deja 1.0.
  ;; Revisa el valor real con el comando UNITS o INSUNITS en AutoCAD.
  ;; ---------------------------------------------------------------------
  (setq FACTOR-COORD 10.0)   ; dibujo en Milimetros (INSUNITS=4), coordenadas del script en cm

  (defun P (x y / )
    (list (* x FACTOR-COORD) (* y FACTOR-COORD) 0.0)
  )

  ;; ---------------------------------------------------------------------
  ;; PARAMETROS DE TAMANO Y ESPACIADO (todo en centimetros)
  ;; ---------------------------------------------------------------------
  (setq ANCHO-SILLA 45.0)
  (setq PROF-SILLA  50.0)
  (setq ANCHO-MESA  120.0)
  (setq PROF-MESA   140.0)
  (setq ESPACIADO-SILLA 66.0)   ; separacion entre sillas de una misma columna (50 + 10 gap)

  ;; Y-ORIGEN: altura (en cm) donde arranca la primera silla/mesa de cada
  ;; columna/zona, bajando desde ahi. AJUSTA este numero despues de ver el
  ;; primer resultado en pantalla, para que quede bien ubicado dentro del
  ;; contorno del bloque BASE.
  (setq Y-ORIGEN 650.0)
  (setq Y-ORIGEN-2 695.0)

  ;; Rotaciones (radianes) para que la silla "mire" hacia la mesa. Como no
  ;; se conoce la orientacion original de tu bloque SILLA, estos valores son
  ;; un punto de partida -> si en el resultado las sillas quedan mirando al
  ;; reves, cambia ROT-DER y ROT-IZQ (prueba con 0, (/ pi 2), pi, (* 1.5 pi)).
  (setq ROT-DER (* 1.5 pi))          ; silla mirando hacia la derecha (+X)
  (setq ROT-IZQ (/ pi 2))           ; silla mirando hacia la izquierda (-X)

  (setq contadorSilla 1)
  (setq contadorMesa 1)

  ;; ---------------------------------------------------------------------
  ;; FUNCION: inserta una columna vertical de N sillas
  ;;   xCM        : posicion X del centro de la columna (cm)
  ;;   n          : cantidad de sillas
  ;;   rot        : rotacion de cada silla (radianes)
  ;;   colorSilla : valor del atributo COLOR
  ;; ---------------------------------------------------------------------
  (defun InsertaColumnaSillas (xCM n rot colorSilla / i yCM)
    (setq i 0)
    (repeat n
      (setq yCM (- Y-ORIGEN (* i ESPACIADO-SILLA)))
      (InsertaBloque *RUTA-SILLA* (P xCM yCM) ESC rot
        (list (cons "NOMBRE" (strcat "Silla_" (itoa contadorSilla)))
              (cons "COLOR"  colorSilla)))
      (setq contadorSilla (1+ contadorSilla))
      (setq i (1+ i))
    )
  )
  (defun InsertaColumnaSillas-2 (xCM n rot colorSilla / i yCM)
    (setq i 0)
    (repeat n
      (setq yCM (- Y-ORIGEN-2 (* i ESPACIADO-SILLA)))
      (InsertaBloque *RUTA-SILLA* (P xCM yCM) ESC rot
        (list (cons "NOMBRE" (strcat "Silla_" (itoa contadorSilla)))
              (cons "COLOR"  colorSilla)))
      (setq contadorSilla (1+ contadorSilla))
      (setq i (1+ i))
    )
  )

  ;; ---------------------------------------------------------------------
  ;; FUNCION: inserta una zona vertical de N mesas "pegadas" (una detras
  ;; de otra en profundidad, sin espacio entre ellas)
  ;;   xCM : posicion X del centro de la zona (cm)
  ;;   n   : cantidad de mesas
  ;; ---------------------------------------------------------------------
  (defun InsertaZonaMesas (xCM n / i yCM)
    (setq i 0)
    (repeat n
      (setq yCM (- Y-ORIGEN (+ (* i PROF-MESA) (/ PROF-MESA 2.0))))
      (InsertaBloque *RUTA-MESA* (P xCM yCM) ESC 0.0
        (list (cons "NOMBRE"    (strcat "Mesa_" (itoa contadorMesa)))
              (cons "MATERIAL"  "Madera")
              (cons "COLOR"     "Cafe")
              (cons "CAPACIDAD" "4")))
      (setq contadorMesa (1+ contadorMesa))
      (setq i (1+ i))
    )
  )

  ;; --------------------- 1. BASE (contorno / piso del salon) --------------
  (InsertaBloque *RUTA-BASE* PTO-BASE ESC 0.0
    (list (cons "NOMBRE" "Salon_101")))

  ;; --------------------- 2. ESCRITORIO DEL PROFESOR ------------------------
  (InsertaBloque *RUTA-ESCRITORIO* (P 14.0 70.0) ESC 0.0
    (list (cons "NOMBRE"   "Escritorio_Profesor")
          (cons "MATERIAL" "Madera")
          (cons "COLOR"    "Cafe")))

  ;; Silla del profesor (frente al escritorio, mirando hacia las mesas)
  (InsertaBloque *RUTA-SILLA* (P 41.0 13.0) ESC 0.0
    (list (cons "NOMBRE" "Silla_Profesor")
          (cons "COLOR"  "Cafe")))

  ;; --------------------- 3. COLUMNAS DE SILLAS + ZONAS DE MESAS ------------
  ;; Posiciones X (cm) calculadas a partir de tus medidas: 120 / 127 / 140
  ;; para los grupos de sillas, y 120 (ancho de 1 mesa) para cada zona.
  ;;   Col1(120) Zona1(120) Col2+3(127) Zona2(120) Col4+5(140) Zona3(120) Col6(103)
  ;;   0-120     120-240    240-367     367-487    487-627     627-747    747-850

  ;; Columna 1 (sola, 6 sillas) - mira hacia la derecha (Zona1 esta a su derecha)
  (InsertaColumnaSillas-2 40.0 6 ROT-DER "Azul")

  ;; Zona 1 (3 mesas)
  (InsertaZonaMesas 95.0 3)

  ;; Columnas 2 y 3 (par, 6 sillas cada una)
  ;; Col2 mira hacia la izquierda (Zona1), Col3 mira hacia la derecha (Zona2)
  (InsertaColumnaSillas 272.0 6 ROT-IZQ "Azul")
  (InsertaColumnaSillas-2 285.0 6 ROT-DER "Azul")

  ;; Zona 2 (3 mesas)
  (InsertaZonaMesas 342.0 3)

  ;; Columnas 4 y 5 (par, 4 sillas cada una)
  (InsertaColumnaSillas 520.0 6 ROT-IZQ "Azul")
  (InsertaColumnaSillas-2 540.0 4 ROT-DER "Azul")

  ;; Zona 3 (2 mesas)
  (InsertaZonaMesas 602.0 2)

  ;; Columna 6 (sola, 4 sillas) - mira hacia la izquierda (Zona3 esta a su izquierda)
  (InsertaColumnaSillas 780.0 4 ROT-IZQ "Azul")

  (princ (strcat "\nSalon armado -> 1 BASE, 1 ESCRITORIO, "
                 (itoa (1- contadorMesa)) " MESAS, "
                 (itoa contadorSilla) " SILLAS (incluye la del profesor)."))
  (princ)
)

(princ "\nComandos cargados: CONFIGURARBLOQUES, REVISARBLOQUES, ARMARSALON.")
(princ)