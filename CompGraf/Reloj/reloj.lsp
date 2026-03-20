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

(defun rotarPunto (pt centro ang)
  (setq a (- (car pt) (car centro)))
  (setq b (- (cadr pt) (cadr centro)))

  (setq ar (- (* a (cos ang)) (* b (sin ang))))
  (setq br (+ (* a (sin ang)) (* b (cos ang))))

  (list (+ ar (car centro)) (+ br (cadr centro)))
)

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

(defun actualizarTexto (ent valor punto / nuevo)
  (if ent
    (progn
      (entdel ent)
      (command "_text" punto "5" "0" valor "")
      (setq nuevo (entlast))
    )
  )
)

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

  (command "_pline" "48.5,50" "48.5,70" "51.5,70" "51.5,50" "")
  (setq horario (entlast))
  (command "_pline" "49,50" "49,85" "51,85" "51,50" "")
  (setq minutero (entlast))
  (command "_pline" "49.5,50" "49.5,90" "50.5,90" "50.5,50" "")
  (setq segundero (entlast))

  ;(command "_extm" centro "50,50")

  ;Para divisiones internas
  ;Array -> last ent -> polar -> centro -> # divisiones -> 360 -> Confirmacion
  (command "_line" "92,50" "98,50" "")
  (command "_array" "_l" "" "_po" "50,50" 12 360 "_y" "")
  (command "_line" "96,50" "98,50" "")
  (command "_array" "_l" "" "_po" "50,50" 60 360 "_y" "")


  ;Cuerpo digital

  ;HHMMSS
  (command "_line" "35,60" "35,70" "")
  (command "_line" "45,60" "45,70" "")
  (command "_line" "55,60" "55,70" "")
  (command "_line" "65,60" "65,70" "")

  (command "_line" "35,60" "65,60" "")
  (command "_line" "35,70" "65,70" "")

  ;DDMMAAAA
  (command "_line" "30,30" "30,40" "")
  (command "_line" "40,30" "40,40" "")
  (command "_line" "50,30" "50,40" "")
  (command "_line" "70,30" "70,40" "")

  (command "_line" "30,30" "70,30" "")
  (command "_line" "30,40" "70,40" "")


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
  ; Bloque de código para depuración digital
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

  ;(print horarioXs)
  ;(print minuteroXs)
  ;(print segunderoXs)

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
    ;Actualizaci�n digital
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
    	(entdel numSS)
    	(command "_text" "56,62" "5" "0" SS "")
    	(setq numSS (entlast))
    	(setq prevSS SS)
      )
    )

    (if (/= MM prevMM)
      (progn
    	(entdel numMM)
    	(command "_text" "46,62" "5" "0" MM "")
    	(setq numMM (entlast))
    	(setq prevMM MM)
      )
    )

    (if (/= HH prevHH)
      (progn
    	(entdel numHH)
    	(command "_text" "36,62" "5" "0" HH "")
    	(setq numHH (entlast))
    	(setq prevHH HH)
      )
    )

    (if (/= D prevD)
      (progn
    	(entdel numD)
    	(command "_text" "31,32" "5" "0" D "")
    	(setq numD (entlast))
    	(setq prevD D)
      )
    )

    (if (/= M prevM)
      (progn
    	(entdel numM)
    	(command "_text" "41,32" "5" "0" M "")
    	(setq numM (entlast))
    	(setq prevM M)
      )
    )

    (if (/= Y prevY)
      (progn
    	(entdel numY)
    	(command "_text" "52,32" "5" "0" Y "")
    	(setq numY (entlast))
    	(setq prevY Y)
      )
    )

    ; Movimiento an�logo configurando entidad
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