import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cliente_model.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class ClientesRepository {
  final CollectionReference<Map<String, dynamic>> _clientes = FirebaseFirestore
      .instance
      .collection('clientes');

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
}
