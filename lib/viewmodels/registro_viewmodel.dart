import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

class RegistroViewModel extends ChangeNotifier {
  RegistroViewModel({UsuariosRepository? repository})
    : _repository = repository ?? UsuariosRepository();

  final UsuariosRepository _repository;

  bool cargando = false;
  bool verPassword = false;

  void alternarVerPassword() {
    verPassword = !verPassword;
    notifyListeners();
  }

  String? validar({
    required String nombre,
    required String correo,
    required String password,
  }) {
    if (nombre.trim().isEmpty ||
        correo.trim().isEmpty ||
        password.trim().isEmpty) {
      return 'Completa todos los campos';
    }

    if (password.trim().length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres';
    }

    return null;
  }

  Future<String?> registrarVendedor({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    cargando = true;
    notifyListeners();

    try {
      await _repository.crearUsuario(
        usuario: UsuarioModel(
          nombre: nombre.trim(),
          correo: correo.trim(),
          rol: 'vendedor',
        ),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Este correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        return 'Correo electrónico inválido';
      } else if (e.code == 'weak-password') {
        return 'La contraseña es muy débil';
      } else if (e.code == 'network-request-failed') {
        return 'Error de conexión a internet';
      }

      return 'No se pudo crear la cuenta';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
