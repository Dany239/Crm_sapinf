import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/seguimiento_model.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class SeguimientosRepository {
  final CollectionReference<Map<String, dynamic>> _seguimientos =
      FirebaseFirestore.instance.collection('seguimientos');

  Stream<List<SeguimientoModel>> escucharSeguimientos() {
    return _seguimientos.snapshots().map((snapshot) {
      final seguimientos = snapshot.docs
          .map((doc) => SeguimientoModel.fromMap(doc.data(), id: doc.id))
          .toList();

      seguimientos.sort((a, b) {
        final fechaA = _fechaOrden(a);
        final fechaB = _fechaOrden(b);
        return fechaB.compareTo(fechaA);
      });

      return seguimientos;
    });
  }

  DateTime _fechaOrden(SeguimientoModel seguimiento) {
    final fecha = seguimiento.fechaRegistro;
    if (fecha is Timestamp) return fecha.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<DocumentReference<Map<String, dynamic>>> crearSeguimiento({
    required SeguimientoModel seguimiento,
    required SesionUsuario sesion,
  }) async {
    final referencia = await _seguimientos.add(seguimiento.toCreateMap(sesion));

    await NotificacionesServicio.crear(
      titulo: seguimiento.estado == 'Realizado'
          ? 'Seguimiento realizado'
          : 'Seguimiento programado',
      descripcion:
          '${sesion.nombre} registró ${seguimiento.tipo} con ${seguimiento.cliente} como ${seguimiento.estado}.',
      tipo: 'seguimiento',
      icono: seguimiento.tipo == 'Correo' ? 'notifications' : 'phone',
      color: 'orange',
      autor: sesion,
      usuariosDestinatarios: [sesion.uid],
      referenciaId: referencia.id,
      referenciaColeccion: 'seguimientos',
    );

    return referencia;
  }

  Future<void> actualizarSeguimiento({
    required String seguimientoId,
    required SeguimientoModel seguimiento,
    required SeguimientoModel seguimientoAnterior,
    required SesionUsuario sesion,
  }) async {
    await _seguimientos
        .doc(seguimientoId)
        .update(
          seguimiento.toUpdateMap(
            sesion: sesion,
            fechaRealizacionAnterior: seguimientoAnterior.fechaRealizacion,
          ),
        );

    if (seguimientoAnterior.estado == seguimiento.estado) return;

    await NotificacionesServicio.crear(
      titulo: 'Seguimiento ${seguimiento.estado}',
      descripcion:
          '${sesion.nombre} marcó ${seguimiento.tipo} con ${seguimiento.cliente} como ${seguimiento.estado}.',
      tipo: 'seguimiento_estado',
      icono: seguimiento.tipo == 'Correo' ? 'notifications' : 'phone',
      color: seguimiento.estado == 'Realizado'
          ? 'green'
          : seguimiento.estado == 'Cancelado'
          ? 'red'
          : 'orange',
      autor: sesion,
      usuariosDestinatarios: [seguimientoAnterior.vendedorId ?? '', sesion.uid],
      referenciaId: seguimientoId,
      referenciaColeccion: 'seguimientos',
    );
  }

  Future<void> eliminarSeguimiento(String seguimientoId) {
    return _seguimientos.doc(seguimientoId).delete();
  }
}
