(defun c:IngresoDatos (/ dcl_id running nombre activo)
  (setq dcl_id (load_dialog "C:/Users/ThinkPad/Documents/VSCode/Academic-Projects/CompGraf/Dialog/dialog.dcl"))

  (if (not (new_dialog "mi_dialogo" dcl_id))
    (progn
      (princ "\nError: No se pudo cargar el archivo DCL.")
      (exit)
    )
  )

  (action_tile "accept"
    (strcat
      "(setq nombre (get_tile \"txtNombre\"))"
      "(setq activo (get_tile \"chkActivo\"))"
      "(setq radio (get_tile \"radiotxt\"))"
      "(done_dialog 1)"
    )
  )

;;;  (set_tile "radiotxt" (itoa (* 25 5)))

  (action_tile "cancel" "(done_dialog 0)")

  (setq running (start_dialog))
  (unload_dialog dcl_id)

  (if (= running 1)
    (progn
      (princ (strcat "\nNombre ingresado: " nombre))
      (if (= activo "1")
        (princ "\nEl estado es: Activo")
        (princ "\nEl estado es: Inactivo")
      )
    )
    (princ "\nDiálogo cancelado")
  )
  (princ)
)