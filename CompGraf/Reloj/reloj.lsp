(defun c:name ()
  (command "osnap" "off") ;Apaga el osnap
  (command "erase" "all" "") ;Borra lo que esta en pantalla en AutoCad

  ;Cuerpo
  (command "circle" "50,50" 50)
  (command "circle" "50,50" 48)

  (command "line" "50,50" "50,60" "")
  (command "line" "50,50" "50,80" "")
)