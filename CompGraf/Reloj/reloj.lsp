(defun c:reloj ()
  (command "_osnap" "_off") ;Apaga el osnap
  (command "_erase" "_all" "") ;Borra lo que esta en pantalla en AutoCad

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
  (setq horarioXs (/ 360 (* 12 (* 60 60))))
  (setq minuteroXs (/ 360 (* 60 12)))
  (setq segunderoXs (/ 360 60))

  ;(print horarioXs)
  ;(print minuteroXs)
  ;(print segunderoXs)
  
  ;Ajuste a hora actual
  (command "_rotate" segundero "" "50,50" (- 90 (* 6 SS)))
)