import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

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
