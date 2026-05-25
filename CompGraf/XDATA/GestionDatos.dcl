gestion_datos : dialog {
  label = "Control de Activos - Datos Extendidos";

  : boxed_column {
    label = "Informacion del Objeto";

    : edit_box {
      label = "ID Equipo:";
      key = "id_equipo";
      edit_width = 20;
    }

    : edit_box {
      label = "Potencia (W):";
      key = "potencia";
      edit_width = 20;
    }
  }

  : row {
    alignment = centered;
    : button {
      label = "Guardar";
      key = "accept";
      is_default = true;
    }
    : button {
      label = "Cancelar";
      key = "cancel";
      is_cancel = true;
    }
  }
}