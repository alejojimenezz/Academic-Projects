(defun c:name ()
  (command "osnap" "off") ;Apaga el osnap
  (command "erase" "all" "") ;Borra lo que esta en pantalla en AutoCad
  

  ;T
  (command "line" "0,0" "0,20" "")
  (command "line" "0,20" "-10,20" "")
  (command "line" "-10,20" "-10,30" "")
  (command "line" "-10,30" "20,30" "")
  (command "line" "20,30" "20,20" "")
  (command "line" "20,20" "10,20" "")
  (command "line" "10,20" "10,0" "")
  (command "line" "10,0" "0,0" "")

  ;I
  (command "line" "20,0" "20,30" "")
  (command "line" "20,30" "30,30" "")
  (command "line" "30,30" "30,0" "")
  (command "line" "30,0" "20,0" "")

  ;T
  (command "line" "40,0" "40,20" "")
  (command "line" "40,20" "30,20" "")
  (command "line" "30,20" "30,30" "")
  (command "line" "30,30" "60,30" "")
  (command "line" "60,30" "60,20" "")
  (command "line" "60,20" "50,20" "")
  (command "line" "50,20" "50,0" "")
  (command "line" "50,0" "40,0" "")

  ;O
  (command "circle" "75,15" 15)
  (command "circle" "75,15" 5)
)