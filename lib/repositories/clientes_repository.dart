import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cliente_model.dart';
import '../servicios/sesion_usuario.dart';

class ClientesRepository {
  final CollectionReference<Map<String, dynamic>> _clientes = FirebaseFirestore
      .instance
      .collection('clientes');

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
}
