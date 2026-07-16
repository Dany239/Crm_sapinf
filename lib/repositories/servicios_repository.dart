import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/servicio_model.dart';

class ServiciosRepository {
  final CollectionReference<Map<String, dynamic>> _servicios = FirebaseFirestore
      .instance
      .collection('servicios');

  Stream<List<ServicioModel>> escucharServicios() {
    return _servicios.snapshots().map((snapshot) {
      final servicios = snapshot.docs
          .map((doc) => ServicioModel.fromMap(doc.data(), id: doc.id))
          .toList();

      servicios.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      return servicios;
    });
  }

  Future<void> crearServicio(ServicioModel servicio) {
    return _servicios.add(servicio.toCreateMap());
  }

  Future<void> actualizarServicio({
    required String servicioId,
    required ServicioModel servicio,
  }) {
    return _servicios.doc(servicioId).update(servicio.toUpdateMap());
  }

  Future<void> eliminarServicio(String servicioId) {
    return _servicios.doc(servicioId).delete();
  }
}
