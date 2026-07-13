import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/venta_model.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class VentasRepository {
  final CollectionReference<Map<String, dynamic>> _ventas = FirebaseFirestore
      .instance
      .collection('ventas');

  Stream<List<VentaModel>> escucharVentas() {
    return _ventas
        .orderBy('fechaRegistro', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => VentaModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<DocumentReference<Map<String, dynamic>>> crearVenta({
    required VentaModel venta,
    required SesionUsuario sesion,
  }) async {
    final referencia = await _ventas.add(venta.toCreateMap(sesion));

    await NotificacionesServicio.crear(
      titulo: 'Nueva venta registrada',
      descripcion:
          '${sesion.nombre} registró una venta para ${venta.cliente} por L. ${venta.monto}.',
      tipo: 'venta',
      icono: 'attach_money',
      color: 'green',
      autor: sesion,
      usuariosDestinatarios: [sesion.uid],
      referenciaId: referencia.id,
      referenciaColeccion: 'ventas',
    );

    return referencia;
  }

  Future<void> actualizarVenta({
    required String ventaId,
    required VentaModel venta,
    required VentaModel ventaAnterior,
    required SesionUsuario sesion,
  }) async {
    await _ventas.doc(ventaId).update(venta.toUpdateMap());

    if (ventaAnterior.estado == venta.estado) return;

    await NotificacionesServicio.crear(
      titulo: 'Venta ${venta.estado}',
      descripcion:
          '${sesion.nombre} cambió la venta de ${venta.cliente} de ${ventaAnterior.estado} a ${venta.estado}.',
      tipo: 'venta_estado',
      icono: 'attach_money',
      color: venta.estado == 'Cerrada'
          ? 'green'
          : venta.estado == 'Cancelada'
          ? 'red'
          : 'orange',
      autor: sesion,
      usuariosDestinatarios: [ventaAnterior.vendedorId ?? '', sesion.uid],
      referenciaId: ventaId,
      referenciaColeccion: 'ventas',
    );
  }

  Future<void> eliminarVenta(String ventaId) {
    return _ventas.doc(ventaId).delete();
  }
}
