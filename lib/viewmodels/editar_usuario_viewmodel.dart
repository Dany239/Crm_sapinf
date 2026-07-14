import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

class EditarUsuarioViewModel extends ChangeNotifier {
  final UsuariosRepository _usuariosRepository;
  final String usuarioId;
  final UsuarioModel usuarioOriginal;

  EditarUsuarioViewModel({
    required this.usuarioId,
    required Map<String, dynamic> usuario,
    UsuariosRepository? usuariosRepository,
  }) : _usuariosRepository = usuariosRepository ?? UsuariosRepository(),
       usuarioOriginal = UsuarioModel.fromMap(usuario, id: usuarioId) {
    rolSeleccionado = usuarioOriginal.rol;
    accesoAdministrador = usuarioOriginal.accesoAdministrador;
  }

  String rolSeleccionado = 'vendedor';
  bool accesoAdministrador = false;
  bool cargando = false;
  bool eliminando = false;
  String? mensajeError;

  void seleccionarRol(String rol) {
    rolSeleccionado = rol;
    notifyListeners();
  }

  void cambiarAccesoAdministrador(bool valor) {
    accesoAdministrador = valor;
    notifyListeners();
  }

  Future<bool> actualizarUsuario({
    required String nombre,
    required String correo,
  }) async {
    mensajeError = null;

    if (nombre.trim().isEmpty || correo.trim().isEmpty) {
      mensajeError = 'Complete todos los campos';
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
        accesoAdministrador:
            rolSeleccionado == 'administrador' || accesoAdministrador,
      );

      await _usuariosRepository.actualizarUsuario(
        usuarioId: usuarioId,
        usuario: usuario,
      );

      return true;
    } on FirebaseException catch (e) {
      mensajeError = 'No se pudo actualizar: ${e.code}';
      return false;
    } catch (_) {
      mensajeError = 'No se pudo actualizar el usuario';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarUsuario() async {
    mensajeError = null;
    eliminando = true;
    notifyListeners();

    try {
      await _usuariosRepository.eliminarUsuario(usuarioId);
      return true;
    } catch (_) {
      mensajeError = 'No se pudo eliminar el usuario';
      return false;
    } finally {
      eliminando = false;
      notifyListeners();
    }
  }
}
