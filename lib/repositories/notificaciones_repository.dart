import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notificacion_model.dart';

class NotificacionesRepository {
  final CollectionReference<Map<String, dynamic>> _notificaciones =
      FirebaseFirestore.instance.collection('notificaciones');

  Stream<List<NotificacionModel>> escucharNotificaciones() {
    return _notificaciones
        .orderBy('fecha', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificacionModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> marcarLeida(String notificacionId, String uid) {
    return _notificaciones.doc(notificacionId).update({
      'leidaPor': FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> marcarTodasComoLeidas(
    List<NotificacionModel> notificaciones,
    String uid,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    var cambios = 0;

    for (final notificacion in notificaciones) {
      if (!notificacion.estaLeidaPor(uid)) {
        batch.update(_notificaciones.doc(notificacion.id), {
          'leidaPor': FieldValue.arrayUnion([uid]),
        });
        cambios++;
      }
    }

    if (cambios > 0) await batch.commit();
  }
}
