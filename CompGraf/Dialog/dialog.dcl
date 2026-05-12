mi_dialogo : dialog {
	label = "Ingreso de Datos";

	: column {
		: text {
			label = "Nombre: ";
		}

		: edit_box {
			key = "txtNombre";
			edit_width = 30;
		}

		: toggle {
			key = "chkActivo";
			label = "Activo";
		}

		: radio_row {
			: radio_button {
				key = "radio1";
				label = "Size 1";
			}
			: radio_button {
				key = "radio2";
				label = "Size 2";
			}
		}

		ok_cancel;
	}
}
