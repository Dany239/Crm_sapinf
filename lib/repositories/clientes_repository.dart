import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cliente_model.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class ClientesRepository {
  final CollectionReference<Map<String, dynamic>> _clientes = FirebaseFirestore
      .instance
      .collection('clientes');
  final CollectionReference<Map<String, dynamic>> _ventas = FirebaseFirestore
      .instance
      .collection('ventas');
  final CollectionReference<Map<String, dynamic>> _seguimientos =
      FirebaseFirestore.instance.collection('seguimientos');

  Stream<List<ClienteModel>> escucharClientes() {
    return _clientes.snapshots().map((snapshot) {
      final clientes = snapshot.docs
          .map((doc) => ClienteModel.fromMap(doc.data(), id: doc.id))
          .toList();

      clientes.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      return clientes;
    });
  }

  Stream<List<ClienteModel>> escucharClientesDisponibles(SesionUsuario sesion) {
    return _clientes.snapshots().map((snapshot) {
      final clientes = snapshot.docs
          .map((doc) => ClienteModel.fromMap(doc.data(), id: doc.id))
          .where((cliente) {
            final pertenece =
                sesion.esAdministrador || cliente.vendedorId == sesion.uid;
            return pertenece && cliente.estadoCliente == 'Cliente';
          })
          .toList();

      clientes.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      return clientes;
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> crearClientePotencial({
    required ClienteModel cliente,
    required SesionUsuario sesion,
  }) async {
    final referencia = await _clientes.add(cliente.toCreateMap(sesion));

    await NotificacionesServicio.crear(
      titulo: 'Nuevo cliente potencial',
      descripcion: '${sesion.nombre} ingresó a ${cliente.nombre}.',
      tipo: 'cliente',
      icono: 'person_add',
      color: 'blue',
      autor: sesion,
      usuariosDestinatarios: [sesion.uid],
      referenciaId: referencia.id,
      referenciaColeccion: 'clientes',
    );

    return referencia;
  }

  Future<void> actualizarCliente({
    required String clienteId,
    required ClienteModel cliente,
  }) {
    return _clientes.doc(clienteId).update(cliente.toUpdateMap());
  }

  Future<void> eliminarCliente(String clienteId) {
    return _clientes.doc(clienteId).delete();
  }

  Future<void> convertirEnCliente({
    required String clienteId,
    required ClienteModel cliente,
    required SesionUsuario sesion,
  }) async {
    await _clientes.doc(clienteId).update({
      'estadoCliente': 'Cliente',
      'fechaConversionCliente': FieldValue.serverTimestamp(),
    });

    await NotificacionesServicio.crear(
      titulo: 'Prospecto convertido en cliente',
      descripcion: '${sesion.nombre} convirtió a ${cliente.nombre} en cliente.',
      tipo: 'cliente_convertido',
      icono: 'person_add',
      color: 'green',
      autor: sesion,
      usuariosDestinatarios: [cliente.vendedorId ?? '', sesion.uid],
      referenciaId: clienteId,
      referenciaColeccion: 'clientes',
    );
  }

  Stream<List<Map<String, dynamic>>> escucharVentasPorCliente(String nombre) {
    return _ventas
        .where('cliente', isEqualTo: nombre)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> escucharSeguimientosPorCliente(
    String nombre,
  ) {
    return _seguimientos
        .where('cliente', isEqualTo: nombre)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
