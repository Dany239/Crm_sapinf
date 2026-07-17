import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/servicio_model.dart';
import '../repositories/servicios_repository.dart';

class EditarServicioViewModel extends ChangeNotifier {
  EditarServicioViewModel({
    required ServicioModel servicioInicial,
    ServiciosRepository? repository,
  }) : _repository = repository ?? ServiciosRepository(),
       logoBase64 = servicioInicial.logoBase64;

  final ServiciosRepository _repository;

  bool cargando = false;
  String logoBase64;

  void cambiarLogo(String valor) {
    logoBase64 = valor;
    notifyListeners();
  }

  Future<String?> seleccionarLogo() async {
    final imagen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 600,
      maxHeight: 600,
    );

    if (imagen == null) return null;

    final bytes = await imagen.readAsBytes();
    if (bytes.lengthInBytes > 750000) {
      return 'Selecciona una imagen más liviana';
    }

    cambiarLogo(base64Encode(bytes));
    return null;
  }

  String? validar({required String nombre, required String descripcion}) {
    if (nombre.trim().isEmpty ||
        descripcion.trim().isEmpty ||
        logoBase64.isEmpty) {
      return 'Completa el nombre, la descripción y el logo';
    }
    return null;
  }

  Future<void> actualizarServicio({
    required String servicioId,
    required String nombre,
    required String descripcion,
    required String precio,
  }) async {
    cargando = true;
    notifyListeners();

    try {
      await _repository.actualizarServicio(
        servicioId: servicioId,
        servicio: ServicioModel(
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

  Future<void> eliminarServicio(String servicioId) {
    return _repository.eliminarServicio(servicioId);
  }
}
