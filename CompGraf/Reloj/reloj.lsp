;Funcion para # dias del mes correspondiente con bisiestos
(defun diasMes (mes anno)
  (cond
    ((or (= mes 1)
         (= mes 3) 
         (= mes 5) 
         (= mes 7)
         (= mes 8) 
         (= mes 10) 
         (= mes 12)) 31)

    ((or (= mes 4) 
         (= mes 6) 
         (= mes 9) 
         (= mes 11)) 30)

    ((= mes 2)
     (if (or
           (and (= (rem anno 4) 0) 
                (/= (rem anno 100) 0))
           (= (rem anno 400) 0))
         29 ;true bisiesto
         28 ;false bisiesto
     )
    )
  )
)

;Funcion auxiliar para rotacion de entidades
(defun rotarPunto (pt centro ang)
  (setq a (- (car pt) (car centro)))
  (setq b (- (cadr pt) (cadr centro)))

  (setq ar (- (* a (cos ang)) (* b (sin ang))))
  (setq br (+ (* a (sin ang)) (* b (cos ang))))

  (list (+ ar (car centro)) (+ br (cadr centro)))
)

;Funcion principal para rotacion de entidades
(defun rotarEntidad (ent ang centro / data nueva)
  (setq data (entget ent))

  (setq nueva
    (mapcar
      (function
	(lambda (item)
	  (if (= (car item) 10)
	    (cons 10 (rotarPunto (cdr item) centro ang))
	    item
	  )
	)
      )
      data
    )
  )

  (entmod nueva)
  (entupd ent)
)

;Funcion para simplificar actualizacion de texto (falta modificacion de entidades)
(defun actualizarTextoEnt (ent valor)
  (setq data (entget ent))
  (setq nueva
    (mapcar
      (function
        (lambda (item)
          (if (= (car item) 1)
            (cons 1 (itoa valor))
            item
          )
        )
      )
      data
    )
  )
  (entmod nueva)
  (entupd ent)
)

;Funcion / Comando RELOJ
(defun c:reloj ()
  (command "_osnap" "_off") ;Apaga el osnap
  (command "_erase" "_all" "") ;Borra lo que esta en pantalla en AutoCad

  (setq n (getint "Ingrese segundos de funcionamiento: "))

  ;Cuerpo analogo

  (command "_circle" "50,50" 50)
  (command "_circle" "50,50" 48)
  (command "_circle" "50,50" 5)
  (setq centro (entlast)) 
  (command "_zoom" "_E")

  ;; (command "_line" "50,50" "50,70" "") ;Horario
  ;; (setq horario (entlast))
  ;; (command "_line" "50,50" "50,85" "") ;Minutero
  ;; (setq minutero (entlast))
  ;; (command "_line" "50,50" "50,90" "") ;Segundero
  ;; (setq segundero (entlast))

  ;Manecillas definidas como bloques
  (command "_circle" "50,50" 1.5)
  (command "_pline" "48.5,50" "48.5,70" "50,72" "51.5,70" "51.5,50" "")
  (setq horario (entlast))
  (command "_circle" "50,50" 1)
  (command "_pline" "49,50" "49,85" "50,86" "51,85" "51,50" "")
  (setq minutero (entlast))
  (command "_circle" "50,50" 0.5)
  (command "_pline" "49.5,50" "49.5,90" "50,91" "50.5,90" "50.5,50" "")
  (setq segundero (entlast))

  ;(command "_extm" centro "50,50")

  ;Para divisiones internas
  ;Array -> last ent -> polar -> centro -> # divisiones -> 360 -> Confirmacion
  (command "_line" "92,50" "98,50" "")
  (command "_array" "_l" "" "_po" "50,50" 12 360 "_y" "")
  (command "_line" "96,50" "98,50" "")
  (command "_array" "_l" "" "_po" "50,50" 60 360 "_y" "")

  ;Números del 1 al 12
  (setq radio 38)

  (setq i 1)
  (repeat 12
    (setq ang (- (/ pi 2) (* i (/ (* 2 pi) 12))))
    
    (setq tx (+ 50 (* radio (cos ang))))
    (setq ty (+ 50 (* radio (sin ang))))
    
    (command "_text" "_j" "_mc" (list tx ty) "3" "0" (itoa i) "")
    
    (setq i (+ i 1))
  )


  ;Cuerpo digital

  ;HHMMSS
  (command "_line" "35,60" "35,70" "")
  (command "_line" "45,60" "45,70" "")
  (command "_line" "55,60" "55,70" "")
  (command "_line" "65,60" "65,70" "")

  (command "_line" "35,60" "65,60" "")
  (command "_line" "35,70" "65,70" "")

  (command "_rectang" "34,71" "66,59")

  ;DDMMAAAA
  (command "_line" "30,30" "30,40" "")
  (command "_line" "40,30" "40,40" "")
  (command "_line" "50,30" "50,40" "")
  (command "_line" "70,30" "70,40" "")

  (command "_line" "30,30" "70,30" "")
  (command "_line" "30,40" "70,40" "")

  (command "_rectang" "29,41" "71,29")

  ;Obtener fecha/hora
  (setq dateNow (getvar "cdate")) ;AAAAMMDD.HHMMSScseg
  ;(print dateNow)

  ;A string
  (setq dateNow_t (rtos dateNow 2 6))
  (setq Y_t (substr dateNow_t 1 4))
  (setq M_t (substr dateNow_t 5 2))
  (setq D_t (substr dateNow_t 7 2))
  (setq HH_t (substr dateNow_t 10 2))
  (setq MM_t (substr dateNow_t 12 2))
  (setq SS_t (substr dateNow_t 14 2))

  ;A numero
  (setq Y (atoi Y_t))
  (setq M (atoi M_t))
  (setq D (atoi D_t))
  (setq HH (atoi HH_t))
  (setq MM (atoi MM_t))
  (setq SS (atoi SS_t))

  ;(print SS)
  ;_____________________________________________________
  ; Bloque de codigo para depuracion digital
;;;  (setq Y 2028)
;;;  (setq M 2)
;;;  (setq D 28)
;;;  (setq HH 23)
;;;  (setq MM 59)
;;;  (setq SS 55)
  ;_____________________________________________________

  ;Variables para operar �ngulos
  (setq horarioXh (/ 360 12.0)
        horarioXm (/ horarioXh 60.0)
        horarioXs (/ horarioXm 60.0)
        minuteroXm (/ 360 60.0)
        minuteroXs (/ minuteroXm 60.0)
        segunderoXs (/ 360 60.0)
  )

  ;Ángulos iniciales
  (setq HAngIni (+ (* HH horarioXh) (* MM horarioXm) (* SS horarioXs)))
  (setq MAngIni (+ (* MM minuteroXm) (* SS minuteroXs)))
  (setq SAngIni (* SS segunderoXs))
  
  ;Ajuste a hora actual con comando rotate
  (command "_rotate" horario "" "50,50" (* -1 HAngIni))
  (command "_rotate" minutero "" "50,50" (* -1 MAngIni))
  (command "_rotate" segundero "" "50,50" (* -1 SAngIni))

  ;(command "_text" "puntoInicio" "altura" "rotacion")
  (command "_text" "36,62" "5" "0" HH "")
  (setq numHH (entlast))
  (command "_text" "46,62" "5" "0" MM "")
  (setq numMM (entlast))
  (command "_text" "56,62" "5" "0" SS "")
  (setq numSS (entlast))
  (command "_text" "31,32" "5" "0" D "")
  (setq numD (entlast))
  (command "_text" "41,32" "5" "0" M "")
  (setq numM (entlast))
  (command "_text" "52,32" "5" "0" Y "")
  (setq numY (entlast))

  (setq prevSS SS)
  (setq prevMM MM)
  (setq prevHH HH)
  (setq prevD D)
  (setq prevM M)
  (setq prevY Y)

  (repeat n 
    ;Actualizacion digital
    (setq SS (+ SS 1))

	(if (= SS 60)
	  (progn
	    (setq SS 0)
	    (setq MM (+ MM 1))

	    (if (= MM 60)
	      (progn
	        (setq MM 0)
	        (setq HH (+ HH 1))

	        (if (= HH 24)
	          (progn
	            (setq HH 0)
	            (setq D (+ D 1))

	            (if (> D (diasMes M Y))
	              (progn
	                (setq D 1)
	                (setq M (+ M 1))

	                (if (> M 12)
	                  (progn
	                    (setq M 1)
	                    (setq Y (+ Y 1))
	                  )
	                )
	              )
	            )
	          )
	        )
	      )
	    )
	  )
	)

    (if (/= SS prevSS)
      (progn
        (actualizarTextoEnt numSS SS)
        (setq prevSS SS)
      )
    )

    (if (/= MM prevMM)
      (progn
        (actualizarTextoEnt numMM MM)
        (setq prevMM MM)
      )
    )

    (if (/= HH prevHH)
      (progn
        (actualizarTextoEnt numHH HH)
        (setq prevHH HH)
      )
    )

    (if (/= D prevD)
      (progn
        (actualizarTextoEnt numD D)
        (setq prevD D)
      )
    )

    (if (/= M prevM)
      (progn
        (actualizarTextoEnt numM M)
        (setq prevM M)
      )
    )

    (if (/= Y prevY)
      (progn
        (actualizarTextoEnt numY Y)
        (setq prevY Y)
      )
    )

    ; Movimiento analogo configurando entidad
    (setq angS (* -1 segunderoXs (/ pi 180)))
    (setq angM (* -1 minuteroXs (/ pi 180)))
    (setq angH (* -1 horarioXs (/ pi 180)))

    (rotarEntidad segundero angS '(50 50))
    (rotarEntidad minutero angM '(50 50))
    (rotarEntidad horario angH '(50 50))

    (redraw segundero 1)
    (redraw minutero 1)
    (redraw horario 1)

    (command "_delay" 1000)
  )
)