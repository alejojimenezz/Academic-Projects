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

;; ---------------------------------------------------------------------------
;; COMANDO PRINCIPAL: ARMARSALON
;; ---------------------------------------------------------------------------
(defun c:ARMARSALON (/ ESC PTO-BASE PTO-ESCRITORIO DATOS-MESAS OFFSETS-SILLAS
                       contadorSilla mesa pto rotM nom mat col cap ptoSilla off)

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

  ;; --------------------- 1. BASE (contorno / piso del salon) --------------
  (InsertaBloque *RUTA-BASE* PTO-BASE ESC 0.0
    (list (cons "NOMBRE" "Salon_101")))

  ;; --------------------- 2. ESCRITORIO DEL PROFESOR ------------------------
  (setq PTO-ESCRITORIO (P 30.0 40.0))
  (InsertaBloque *RUTA-ESCRITORIO* PTO-ESCRITORIO ESC 0.0
    (list (cons "NOMBRE"   "Escritorio_Profesor")
          (cons "MATERIAL" "Madera")
          (cons "COLOR"    "Cafe")))

  ;; Silla del profesor (frente al escritorio, mirando hacia las mesas)
  (InsertaBloque *RUTA-SILLA* (P 30.0 10.0) ESC (* pi 0.5)
    (list (cons "NOMBRE" "Silla_Profesor")
          (cons "COLOR"  "Cafe")))

  ;; --------------------- 3. DATOS DE LAS 8 MESAS DE ESTUDIANTES ------------
  ;; Cada elemento: (Punto rotacion(rad) Nombre Material Color Capacidad)
  ;; Coordenadas en CENTIMETROS -> se escalan automaticamente via (P x y)
  (setq DATOS-MESAS
    (list
      (list (P 150.0 300.0) 0.0 "Mesa_1" "Madera" "Cafe" "4")
      (list (P 300.0 300.0) 0.0 "Mesa_2" "Madera" "Cafe" "4")
      (list (P 450.0 300.0) 0.0 "Mesa_3" "Madera" "Cafe" "4")
      (list (P 600.0 300.0) 0.0 "Mesa_4" "Madera" "Cafe" "4")
      (list (P 150.0 480.0) 0.0 "Mesa_5" "Madera" "Cafe" "4")
      (list (P 300.0 480.0) 0.0 "Mesa_6" "Madera" "Cafe" "4")
      (list (P 450.0 480.0) 0.0 "Mesa_7" "Madera" "Cafe" "4")
      (list (P 600.0 480.0) 0.0 "Mesa_8" "Madera" "Cafe" "4")
    )
  )

  ;; --------------------- 4. OFFSETS DE LAS 4 SILLAS POR MESA ---------------
  ;; Tambien en centimetros -> se escalan con FACTOR-COORD
  (setq OFFSETS-SILLAS
    (list
      (list (* -30.0 FACTOR-COORD) (*  30.0 FACTOR-COORD) pi)   ; arriba-izquierda
      (list (*  30.0 FACTOR-COORD) (*  30.0 FACTOR-COORD) pi)   ; arriba-derecha
      (list (* -30.0 FACTOR-COORD) (* -30.0 FACTOR-COORD) 0.0)  ; abajo-izquierda
      (list (*  30.0 FACTOR-COORD) (* -30.0 FACTOR-COORD) 0.0)  ; abajo-derecha
    )
  )

  ;; --------------------- 5. INSERTAR CADA MESA + SUS 4 SILLAS --------------
  (setq contadorSilla 1)
  (foreach mesa DATOS-MESAS
    (setq pto  (nth 0 mesa)
          rotM (nth 1 mesa)
          nom  (nth 2 mesa)
          mat  (nth 3 mesa)
          col  (nth 4 mesa)
          cap  (nth 5 mesa))

    (InsertaBloque *RUTA-MESA* pto ESC rotM
      (list (cons "NOMBRE"     nom)
            (cons "MATERIAL"   mat)
            (cons "COLOR"      col)
            (cons "CAPACIDAD"  cap)))

    (foreach off OFFSETS-SILLAS
      (setq ptoSilla (list (+ (car pto) (nth 0 off))
                           (+ (cadr pto) (nth 1 off))
                           0.0))
      (InsertaBloque *RUTA-SILLA* ptoSilla ESC (nth 2 off)
        (list (cons "NOMBRE" (strcat "Silla_" (itoa contadorSilla)))
              (cons "COLOR"  "Azul")))
      (setq contadorSilla (1+ contadorSilla))
    )
  )

  (princ (strcat "\nSalon armado -> 1 BASE, 1 ESCRITORIO, "
                 (itoa (length DATOS-MESAS)) " MESAS, "
                 (itoa contadorSilla) " SILLAS."))
  (princ)
)

(princ "\nComandos cargados: CONFIGURARBLOQUES, REVISARBLOQUES, ARMARSALON.")
(princ)