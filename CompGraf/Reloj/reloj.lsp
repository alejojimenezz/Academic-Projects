(defun c:reloj ()
  (command "osnap" "off") ;Apaga el osnap
  (command "erase" "all" "") ;Borra lo que esta en pantalla en AutoCad

  ;Cuerpo analogo
  (command "circle" "50,50" 50)
  (command "circle" "50,50" 48)
  (command "circle" "50,50" 5)

  (command "line" "50,50" "50,65" "") ;Horario
  (command "line" "50,50" "50,80" "") ;Minutero
  (command "line" "50,50" "50,90" "") ;Segundero

  ;Cuerpo digital

  ;HHMMSS
  (command "line" "35,60" "35,70" "")
  (command "line" "45,60" "45,70" "")
  (command "line" "55,60" "55,70" "")
  (command "line" "65,60" "65,70" "")

  (command "line" "35,60" "65,60" "")
  (command "line" "35,70" "65,70" "")

  ;DDMMAAAA
  (command "line" "30,30" "30,40" "")
  (command "line" "40,30" "40,40" "")
  (command "line" "50,30" "50,40" "")
  (command "line" "70,30" "70,40" "")

  (command "line" "30,30" "70,30" "")
  (command "line" "30,40" "70,40" "")

  (command "zoom" "e")

  ;Obtener hora
  (setq dateNow (getvar "cdate")) ;AAAAMMDD.HHMMSScseg
  (print dateNow)

)