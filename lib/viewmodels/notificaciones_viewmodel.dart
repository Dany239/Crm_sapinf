import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/notificacion_model.dart';
import '../repositories/notificaciones_repository.dart';
import '../servicios/sesion_usuario.dart';

class NotificacionesSesionViewData {
  const NotificacionesSesionViewData({
    required this.uid,
    required this.rol,
    required this.esAdministrador,
  });

  factory NotificacionesSesionViewData.fromSesion(SesionUsuario sesion) {
    return NotificacionesSesionViewData(
      uid: sesion.uid,
      rol: sesion.rol,
      esAdministrador: sesion.esAdministrador,
    );
  }

  final String uid;
  final String rol;
  final bool esAdministrador;

  String get subtitulo {
    return esAdministrador ? 'Actividad comercial' : 'Mis actividades';
  }
}

class NotificacionDestinoViewData {
  const NotificacionDestinoViewData({
    required this.coleccion,
    required this.id,
    required this.data,
  });

  final String coleccion;
  final String id;
  final Map<String, dynamic> data;
}

class NotificacionesViewModel extends ChangeNotifier {
  NotificacionesViewModel({NotificacionesRepository? repository})
    : _repository = repository ?? NotificacionesRepository() {
    sesionFuture = obtenerSesionUsuario().then(
      NotificacionesSesionViewData.fromSesion,
    );
  }

  final NotificacionesRepository _repository;
  late final Future<NotificacionesSesionViewData> sesionFuture;

  Stream<List<NotificacionModel>> get notificacionesStream {
    return _repository.escucharNotificaciones();
  }

  List<NotificacionModel> filtrarVisibles(
    List<NotificacionModel> notificaciones,
    NotificacionesSesionViewData sesion,
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

  Future<NotificacionDestinoViewData?> obtenerDestino(
    NotificacionModel notificacion,
  ) async {
    final coleccion = notificacion.referenciaColeccion;
    final id = notificacion.referenciaId;

    if (coleccion == null || coleccion.isEmpty || id == null || id.isEmpty) {
      return null;
    }

    final data = await _repository.obtenerDocumentoReferencia(
      coleccion: coleccion,
      id: id,
    );

    if (data == null) return null;

    return NotificacionDestinoViewData(
      coleccion: coleccion,
      id: id,
      data: data,
    );
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
