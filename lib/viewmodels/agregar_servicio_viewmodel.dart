import 'package:flutter/foundation.dart';

import '../models/servicio_model.dart';
import '../repositories/servicios_repository.dart';

class AgregarServicioViewModel extends ChangeNotifier {
  AgregarServicioViewModel({ServiciosRepository? repository})
    : _repository = repository ?? ServiciosRepository();

  final ServiciosRepository _repository;

  bool cargando = false;
  String logoBase64 = '';

  void cambiarLogo(String valor) {
    logoBase64 = valor;
    notifyListeners();
  }

  String? validar({required String nombre, required String descripcion}) {
    if (nombre.trim().isEmpty) {
      return 'El nombre del servicio es obligatorio';
    }
    if (descripcion.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (logoBase64.isEmpty) {
      return 'Selecciona el logo del servicio';
    }
    return null;
  }

  Future<void> guardarServicio({
    required String nombre,
    required String descripcion,
    required String precio,
  }) async {
    cargando = true;
    notifyListeners();

    try {
      await _repository.crearServicio(
        ServicioModel(
          nombre: nombre.trim(),
          descripcion: descripcion.trim(),
          precio: precio.trim(),
          logoBase64: logoBase64,
        ),
      );
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
