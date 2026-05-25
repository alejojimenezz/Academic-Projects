(defun c:EditarDatos (/ ent dialogID data xdataList id pot xdata dcl-path)

  ;; Registrar la aplicacion (OBLIGATORIO para XData)
  (if (not (tblsearch "APPID" "GESTION_ACTIVOS"))
    (regapp "GESTION_ACTIVOS")
  )

  ;; Seleccionar objeto
  (setq ent (car (entsel "\nSelecciona un bloque: ")))

  (if (null ent)
    (princ "\nNo se selecciono ningun objeto.")

    (progn
      ;; Buscar el DCL: primero con findfile, luego junto al DWG
      (setq dcl-path (findfile "GestionDatos.dcl"))
      (if (null dcl-path)
        (progn
          (setq dcl-path
            (strcat (getvar "DWGPREFIX") "GestionDatos.dcl")
          )
          (princ (strcat "\nBuscando DCL en: " dcl-path))
        )
      )

      ;; Cargar el DCL
      (setq dialogID (load_dialog dcl-path))

      (if (< dialogID 0)
        (princ (strcat "\nError: No se encontro el DCL en: " dcl-path))

        (progn
          (if (not (new_dialog "gestion_datos" dialogID))
            (princ "\nError: No se pudo abrir el dialogo.")

            (progn
              ;; Leer XData existente
              (setq xdataList (cddr (assoc -3 (entget ent '("GESTION_ACTIVOS")))))

              (if xdataList
                (progn
                  (setq xdataList (car xdataList))
                  (set_tile "id_equipo" (cdr (nth 1 xdataList)))
                  (set_tile "potencia"  (cdr (nth 2 xdataList)))
                )
              )

              (action_tile "accept"
                "(setq id (get_tile \"id_equipo\"))
                 (setq pot (get_tile \"potencia\"))
                 (done_dialog 1)"
              )

              (if (= (start_dialog) 1)
                (progn
                  (if (or (= id "") (= pot ""))
                    (princ "\nError: Los campos no pueden estar vacios.")
                    (progn
                      (setq xdata
                        (list -3
                          (list "GESTION_ACTIVOS"
                            (cons 1000 "ACTIVO")
                            (cons 1000 id)
                            (cons 1000 pot)
                          )
                        )
                      )
                      (entmod (append (entget ent) (list xdata)))
                      (entupd ent)
                      (princ (strcat "\nDatos guardados -> ID: " id "  Potencia: " pot " W"))
                    )
                  )
                )
                (princ "\nOperacion cancelada.")
              )
            )
          )
          (unload_dialog dialogID)
        )
      )
    )
  )
  (princ)
)

(defun c:CalcularConsumo (/ ss i ent xdata xlist vatios total-w horas tarifa costo)

  ;; --- Parametros de calculo (ajusta estos valores) ---
  (setq horas   730.0)   ; horas al mes (24h x 30 dias aprox)
  (setq tarifa  0.12)    ; costo por kWh en tu moneda

  ;; --- Recorrer todos los objetos del dibujo ---
  (setq ss (ssget "X"))  ; selecciona TODO en el dibujo
  (setq total-w 0.0)
  (setq i 0)

  (if (null ss)
    (princ "\nNo hay objetos en el dibujo.")

    (progn
      (repeat (sslength ss)
        (setq ent (ssname ss i))
        (setq i (1+ i))

        ;; Leer XData de la app ELECTRICAL
        (setq xdata (cddr (assoc -3 (entget ent '("ELECTRICAL")))))

        (if xdata
          (progn
            ;; xdata es algo como: (( (1002 . "{") (1000 . "500 W") (1002 . "}") ))
            (setq xlist (car xdata))

            ;; Buscar el par con codigo 1000 (el string de potencia)
            (foreach par xlist
              (if (= (car par) 1000)
                (progn
                  ;; Extraer numero del string "500 W" -> 500.0
                  (setq vatios (atof (car (str-split (cdr par) " "))))
                  (setq total-w (+ total-w vatios))
                )
              )
            )
          )
        )
      )

      ;; --- Calcular costo ---
      (setq kwh    (/ (* total-w horas) 1000.0))
      (setq costo  (* kwh tarifa))

      ;; --- Mostrar resultado ---
      (princ "\n========================================")
      (princ (strcat "\n  RESUMEN DE CONSUMO ELECTRICO"))
      (princ "\n========================================")
      (princ (strcat "\n  Potencia total    : " (rtos total-w 2 1) " W"))
      (princ (strcat "\n  Energia mensual   : " (rtos kwh 2 2) " kWh"))
      (princ (strcat "\n  Tarifa aplicada   : $" (rtos tarifa 2 4) " / kWh"))
      (princ (strcat "\n  Horas calculadas  : " (rtos horas 2 0) " h/mes"))
      (princ "\n----------------------------------------")
      (princ (strcat "\n  COSTO ESTIMADO    : $" (rtos costo 2 2)))
      (princ "\n========================================\n")
    )
  )
  (princ)
)

;; --- Funcion auxiliar: dividir string por separador ---
(defun str-split (str sep / pos result)
  (setq result '())
  (while (setq pos (vl-string-search sep str))
    (setq result (append result (list (substr str 1 pos))))
    (setq str (substr str (+ pos 1 (strlen sep))))
  )
  (append result (list str))
)