import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

class UsuariosViewModel extends ChangeNotifier {
  final UsuariosRepository _usuariosRepository;

  UsuariosViewModel({UsuariosRepository? usuariosRepository})
    : _usuariosRepository = usuariosRepository ?? UsuariosRepository();

  bool get hayUsuarioActivo => _usuariosRepository.usuarioActualId != null;

  Stream<UsuarioModel?> get usuarioActualStream =>
      _usuariosRepository.escucharUsuarioActual();

  Stream<List<UsuarioModel>> get usuariosStream =>
      _usuariosRepository.escucharUsuarios();

  bool puedeGestionarUsuarios(UsuarioModel? usuario) {
    return usuario?.rol == 'administrador';
  }

  bool estaActivo(UsuarioModel usuario) {
    final ultimaActividad = usuario.ultimaActividad;
    return ultimaActividad is Timestamp &&
        DateTime.now().difference(ultimaActividad.toDate()).inMinutes <= 15;
  }

  String tiempoDesdeUltimaActividad(dynamic valor) {
    if (valor is! Timestamp) return 'Aún no registra actividad';

    final diferencia = DateTime.now().difference(valor.toDate());

    if (diferencia.inMinutes < 1) return 'Ahora mismo';
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minutos';
    }
    if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    }
    if (diferencia.inDays == 1) return 'Hace 1 día';
    return 'Hace ${diferencia.inDays} días';
  }
}
