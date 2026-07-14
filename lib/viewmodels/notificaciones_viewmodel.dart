import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notificacion_model.dart';
import '../repositories/notificaciones_repository.dart';
import '../servicios/sesion_usuario.dart';

class NotificacionesViewModel extends ChangeNotifier {
  NotificacionesViewModel({NotificacionesRepository? repository})
    : _repository = repository ?? NotificacionesRepository();

  final NotificacionesRepository _repository;

  Stream<List<NotificacionModel>> get notificacionesStream {
    return _repository.escucharNotificaciones();
  }

  List<NotificacionModel> filtrarVisibles(
    List<NotificacionModel> notificaciones,
    SesionUsuario sesion,
  ) {
    return notificaciones.where((notificacion) {
      final usuarios = notificacion.usuariosDestinatarios;
      final roles = notificacion.rolesDestinatarios;

      if (usuarios.isEmpty && roles.isEmpty) return true;
      if (usuarios.contains(sesion.uid)) return true;
      if (sesion.esAdministrador && roles.contains('administrador')) {
        return true;
      }
      return roles.contains(sesion.rol);
    }).toList();
  }

  int contarPendientes(List<NotificacionModel> notificaciones, String uid) {
    return notificaciones
        .where((notificacion) => !notificacion.estaLeidaPor(uid))
        .length;
  }

  Future<void> marcarLeida(NotificacionModel notificacion, String uid) {
    return _repository.marcarLeida(notificacion.id, uid);
  }

  Future<void> marcarTodasComoLeidas(
    List<NotificacionModel> notificaciones,
    String uid,
  ) {
    return _repository.marcarTodasComoLeidas(notificaciones, uid);
  }

  String tiempoRelativo(Timestamp? fecha) {
    if (fecha == null) return 'Ahora';

    final diferencia = DateTime.now().difference(fecha.toDate());
    if (diferencia.inMinutes < 1) return 'Hace unos segundos';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    return 'Hace ${diferencia.inDays} días';
  }
}
