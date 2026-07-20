(vl-load-com)

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
;; globales para la sesion
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
;;; ---------------------------------------------------------------------------
(defun c:ARMARSALON (/ ESC PTO-BASE FACTOR-COORD ANCHO-SILLA PROF-SILLA
                       ANCHO-MESA PROF-MESA ESPACIADO-SILLA Y-ORIGEN
                       ROT-DER ROT-IZQ contadorSilla contadorMesa
                       InsertaColumnaSillas InsertaZonaMesas)

  ;; Verificacion de configuracion de rutas
  (if (not (and *RUTA-BASE* *RUTA-ESCRITORIO* *RUTA-MESA* *RUTA-SILLA*))
    (progn
      (princ "\nFalta configurar las rutas de los bloques. Corriendo CONFIGURARBLOQUES...")
      (c:CONFIGURARBLOQUES)
    )
  )

  (setq ESC 1.0)                         ; factor de escala de insercion (tamano del bloque)
  (setq PTO-BASE (list 0.0 0.0 0.0))     ; esquina inf-izq del salon (ajustar)

  (setq FACTOR-COORD 10.0)

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
  (setq ESPACIADO-SILLA 66.0)


  (setq Y-ORIGEN 650.0)
  (setq Y-ORIGEN-2 695.0)

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
  ;; FUNCION: inserta una zona vertical de N mesas pegadas
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

  ;; 1. BASE (contorno / piso del salon)
  (InsertaBloque *RUTA-BASE* PTO-BASE ESC 0.0
    (list (cons "NOMBRE" "Salon_101")))

  ;; 2. ESCRITORIO DEL PROFESOR
  (InsertaBloque *RUTA-ESCRITORIO* (P 14.0 70.0) ESC 0.0
    (list (cons "NOMBRE"   "Escritorio_Profesor")
          (cons "MATERIAL" "Madera")
          (cons "COLOR"    "Cafe")))

  ;; Silla del profesor
  (InsertaBloque *RUTA-SILLA* (P 41.0 13.0) ESC 0.0
    (list (cons "NOMBRE" "Silla_Profesor")
          (cons "COLOR"  "Cafe")))

  ;; 3. COLUMNAS DE SILLAS + ZONAS DE MESAS

  ;; Columna 1
  (InsertaColumnaSillas-2 40.0 6 ROT-DER "Azul")

  ;; Zona 1
  (InsertaZonaMesas 95.0 3)

  ;; Columnas 2 y 3
  (InsertaColumnaSillas 272.0 6 ROT-IZQ "Azul")
  (InsertaColumnaSillas-2 285.0 6 ROT-DER "Azul")

  ;; Zona 2
  (InsertaZonaMesas 342.0 3)

  ;; Columnas 4 y 5
  (InsertaColumnaSillas 520.0 6 ROT-IZQ "Azul")
  (InsertaColumnaSillas-2 540.0 4 ROT-DER "Azul")

  ;; Zona 3
  (InsertaZonaMesas 602.0 2)

  ;; Columna 6
  (InsertaColumnaSillas 780.0 4 ROT-IZQ "Azul")

  (princ (strcat "\nSalon armado -> 1 BASE, 1 ESCRITORIO, "
                 (itoa (1- contadorMesa)) " MESAS, "
                 (itoa contadorSilla) " SILLAS (incluye la del profesor)."))
  (princ)
)


;;; ---------------------------------------------------------------------------
;;; FUNCIONES AUXILIARES PARA EXPORTAR DATOS
;;; ---------------------------------------------------------------------------

(defun StrJoin (lst sep / s primero)
  (setq s "")
  (setq primero t)
  (foreach item lst
    (if primero
      (progn (setq s item) (setq primero nil))
      (setq s (strcat s sep item))
    )
  )
  s
)

(defun QuitarEspacios (s / pos)
  (if (not s) (setq s ""))
  (while (setq pos (vl-string-search " " s))
    (setq s (strcat (substr s 1 pos) "_" (substr s (+ pos 2))))
  )
  s
)

;;; ---------------------------------------------------------------------------
;;; COMANDO: EXPORTARDATOS
;;; ---------------------------------------------------------------------------
(defun c:EXPORTARDATOS (/ ss n ent obj nombreBloque atributos att tag val
                         datosNombre datosMaterial datosColor datosCapacidad
                         pto x y rutaCsv rutaTxt fCsv fTxt fila i filaTxt)

  (setq ss (ssget "_X" '((0 . "INSERT"))))

  (if (not ss)
    (princ "\nNo se encontraron bloques insertados en el dibujo.")
    (progn
      (setq rutaCsv (getfiled "Guardar archivo CSV (separado por comas)" "" "csv" 1))
      (setq rutaTxt (getfiled "Guardar archivo TXT (separado por espacios)" "" "txt" 1))

      (if (and rutaCsv rutaTxt)
        (progn
          (setq fCsv (open rutaCsv "w"))
          (setq fTxt (open rutaTxt "w"))

          ;; Encabezados
          (write-line "BLOQUE,NOMBRE,MATERIAL,COLOR,CAPACIDAD,X,Y" fCsv)
          (write-line "BLOQUE NOMBRE MATERIAL COLOR CAPACIDAD X Y" fTxt)

          (setq i 0)
          (repeat (sslength ss)
            (setq ent (ssname ss i))
            (setq obj (vlax-ename->vla-object ent))
            (setq nombreBloque (vla-get-EffectiveName obj))

            (setq datosNombre    "")
            (setq datosMaterial  "")
            (setq datosColor     "")
            (setq datosCapacidad "")

            (if (= (vla-get-HasAttributes obj) :vlax-true)
              (progn
                (setq atributos (vlax-invoke obj 'GetAttributes))
                (foreach att atributos
                  (setq tag (strcase (vla-get-TagString att)))
                  (setq val (vla-get-TextString att))
                  (cond
                    ((= tag "NOMBRE")    (setq datosNombre val))
                    ((= tag "MATERIAL")  (setq datosMaterial val))
                    ((= tag "COLOR")     (setq datosColor val))
                    ((= tag "CAPACIDAD") (setq datosCapacidad val))
                  )
                )
              )
            )

            (setq pto (vlax-safearray->list
                        (vlax-variant-value (vla-get-InsertionPoint obj))))
            (setq x (rtos (car pto) 2 2))
            (setq y (rtos (cadr pto) 2 2))

            ;; Fila para el CSV (valores tal cual)
            (setq fila (list nombreBloque datosNombre datosMaterial
                              datosColor datosCapacidad x y))
            (write-line (StrJoin fila ",") fCsv)

            ;; Fila para el TXT (sin espacios internos en los valores)
            (setq filaTxt (list (QuitarEspacios nombreBloque)
                                 (QuitarEspacios datosNombre)
                                 (QuitarEspacios datosMaterial)
                                 (QuitarEspacios datosColor)
                                 (QuitarEspacios datosCapacidad)
                                 x y))
            (write-line (StrJoin filaTxt " ") fTxt)

            (setq i (1+ i))
          )

          (close fCsv)
          (close fTxt)

          (princ (strcat "\nExportados " (itoa (sslength ss)) " bloques a:\n  "
                          rutaCsv "\n  " rutaTxt))
        )
        (princ "\nExportacion cancelada (no se selecciono una de las rutas de guardado).")
      )
    )
  )
  (princ)
)

(princ "\nComandos cargados: CONFIGURARBLOQUES, REVISARBLOQUES, ARMARSALON, EXPORTARDATOS.")
(princ)