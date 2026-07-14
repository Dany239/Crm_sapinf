import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

class AgregarUsuarioViewModel extends ChangeNotifier {
  final UsuariosRepository _usuariosRepository;

  AgregarUsuarioViewModel({UsuariosRepository? usuariosRepository})
    : _usuariosRepository = usuariosRepository ?? UsuariosRepository();

  String rolSeleccionado = 'vendedor';
  bool cargando = false;
  String? mensajeError;

  void seleccionarRol(String rol) {
    rolSeleccionado = rol;
    notifyListeners();
  }

  Future<bool> guardarUsuario({
    required String nombre,
    required String correo,
    required String password,
  }) async {
    mensajeError = null;

    if (nombre.trim().isEmpty ||
        correo.trim().isEmpty ||
        password.trim().isEmpty) {
      mensajeError = 'Complete todos los campos';
      notifyListeners();
      return false;
    }

    if (password.trim().length < 6) {
      mensajeError = 'La contraseña debe tener mínimo 6 caracteres';
      notifyListeners();
      return false;
    }

    cargando = true;
    notifyListeners();

    try {
      final usuario = UsuarioModel(
        nombre: nombre.trim(),
        correo: correo.trim(),
        rol: rolSeleccionado,
      );

      await _usuariosRepository.crearUsuario(
        usuario: usuario,
        password: password.trim(),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        mensajeError = 'Este correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        mensajeError = 'Correo electrónico inválido';
      } else if (e.code == 'weak-password') {
        mensajeError = 'La contraseña es muy débil';
      } else {
        mensajeError = 'Error al crear usuario';
      }
      return false;
    } catch (_) {
      mensajeError = 'Error al crear usuario';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
