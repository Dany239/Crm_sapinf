import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

enum PerfilFotoOrigen { galeria, camara }

class PerfilFotoResultado {
  const PerfilFotoResultado._({required this.actualizada, this.error});

  const PerfilFotoResultado.actualizada() : this._(actualizada: true);

  const PerfilFotoResultado.cancelada() : this._(actualizada: false);

  const PerfilFotoResultado.error(String mensaje)
    : this._(actualizada: false, error: mensaje);

  final bool actualizada;
  final String? error;
}

class PerfilViewModel extends ChangeNotifier {
  PerfilViewModel({UsuariosRepository? repository})
    : _repository = repository ?? UsuariosRepository();

  final UsuariosRepository _repository;

  bool get hayUsuarioActivo => _repository.usuarioActualId != null;
  String get correoActual => _repository.usuarioActualCorreo ?? 'Sin correo';

  Stream<UsuarioModel?> get usuarioStream {
    return _repository.escucharUsuarioActual();
  }

  Future<void> cerrarSesion() {
    return _repository.cerrarSesion();
  }

  String? validarCambioPassword({
    required String passwordActual,
    required String passwordNueva,
    required String passwordConfirmar,
  }) {
    if (passwordActual.isEmpty ||
        passwordNueva.isEmpty ||
        passwordConfirmar.isEmpty) {
      return 'Completa todos los campos';
    }

    if (passwordNueva.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    if (passwordNueva != passwordConfirmar) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  Future<String?> cambiarPasswordValidado({
    required String passwordActual,
    required String passwordNueva,
    required String passwordConfirmar,
  }) async {
    final error = validarCambioPassword(
      passwordActual: passwordActual,
      passwordNueva: passwordNueva,
      passwordConfirmar: passwordConfirmar,
    );

    if (error != null) return error;

    return cambiarPassword(
      passwordActual: passwordActual,
      passwordNueva: passwordNueva,
    );
  }

  Future<String?> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    try {
      await _repository.cambiarPassword(
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'La contraseña actual no es correcta';
      } else if (e.code == 'weak-password') {
        return 'La nueva contraseña es muy débil';
      } else if (e.code == 'requires-recent-login') {
        return 'Vuelve a iniciar sesión e intenta de nuevo';
      }

      return 'No se pudo cambiar la contraseña';
    }
  }

  Future<void> actualizarFotoDesdeBytes(Uint8List bytes) {
    return _repository.actualizarFotoActual(base64Encode(bytes));
  }

  Future<PerfilFotoResultado> seleccionarYActualizarFoto(
    PerfilFotoOrigen origen,
  ) async {
    try {
      final picker = ImagePicker();
      final imagen = await picker.pickImage(
        source: _imageSource(origen),
        imageQuality: 55,
        maxWidth: 500,
      );

      if (imagen == null) {
        return const PerfilFotoResultado.cancelada();
      }

      final bytes = await imagen.readAsBytes();
      await actualizarFotoDesdeBytes(bytes);

      return const PerfilFotoResultado.actualizada();
    } catch (e) {
      return PerfilFotoResultado.error('No se pudo actualizar la foto: $e');
    }
  }

  ImageSource _imageSource(PerfilFotoOrigen origen) {
    switch (origen) {
      case PerfilFotoOrigen.galeria:
        return ImageSource.gallery;
      case PerfilFotoOrigen.camara:
        return ImageSource.camera;
    }
  }

  ImageProvider? obtenerFotoPerfil(UsuarioModel? usuario) {
    final fotoBase64 = usuario?.fotoBase64;

    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      return MemoryImage(base64Decode(fotoBase64));
    }

    final fotoUrl = usuario?.foto;

    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return NetworkImage(fotoUrl);
    }

    return null;
  }

  String rolFormateado(UsuarioModel? usuario) {
    final rol = usuario?.rol ?? 'Sin rol';
    if (rol.isEmpty) return 'Sin rol';
    return rol[0].toUpperCase() + rol.substring(1);
  }
}
