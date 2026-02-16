(defun c:reloj ()
  (command "_osnap" "_off") ;Apaga el osnap
  (command "_erase" "_all" "") ;Borra lo que esta en pantalla en AutoCad

  ;Cuerpo analogo
  (command "_circle" "50,50" 50)
  (command "_circle" "50,50" 48)
  (command "_circle" "50,50" 5)

  (setq horario (command "_line" "50,50" "50,65" "")) ;Horario
  (setq minutero (command "_line" "50,50" "50,80" "")) ;Minutero
  (setq segundero (command "_line" "50,50" "50,90" "")) ;Segundero

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

  (command "_zoom" "_e")

  ;Obtener fecha/hora
  (setq dateNow (getvar "_cdate")) ;AAAAMMDD.HHMMSScseg
  (print dateNow)

)