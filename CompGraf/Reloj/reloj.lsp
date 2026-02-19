(defun c:reloj ()
  (command "_osnap" "_off") ;Apaga el osnap
  (command "_erase" "_all" "") ;Borra lo que esta en pantalla en AutoCad

  (setq n (getint "Ingrese segundos de funcionamiento: "))

  ;Cuerpo analogo
  (command "_circle" "50,50" 50)
  (command "_circle" "50,50" 48)
  (command "_circle" "50,50" 5)

  (command "_line" "50,50" "50,65" "") ;Horario
  (setq horario (entlast))
  (command "_line" "50,50" "50,80" "") ;Minutero
  (setq minutero (entlast))
  (command "_line" "50,50" "50,90" "") ;Segundero
  (setq segundero (entlast))

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

  (command "_zoom" "E")

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

  (print SS)

  ;Variables para operar ángulos
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
  
  ;Ajuste a hora actual
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

  (repeat n 
    ;Actualización digital
    (setq SS (+ 1 SS))
    (if (= SS 60) (setq SS 0))
    (if (= SS 0) (setq MM (+ 1 MM)))

    (command "_erase" numSS numMM "")
    (command "_text" "56,62" "5" "0" SS "")
    (setq numSS (entlast))
    (command "_text" "46,62" "5" "0" MM "")
    (setq numMM (entlast))


    ;Movimiento análogo
    (command "_rotate" segundero "" "50,50" (* -1 segunderoXs))
    (command "_rotate" minutero "" "50,50" (* -1 minuteroXs))
    (command "_rotate" horario "" "50,50" (* -1 horarioXs))
    (redraw segundero 1)
    (redraw minutero 1)
    (redraw horario 1)

    (command "_delay" 1000)
  )
)