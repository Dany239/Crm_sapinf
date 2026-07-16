import 'package:cloud_firestore/cloud_firestore.dart';

class ServicioModel {
  final String id;
  final String nombre;
  final String descripcion;
  final String precio;
  final String logoBase64;
  final dynamic fechaRegistro;
  final dynamic fechaActualizacion;

  const ServicioModel({
    this.id = '',
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.logoBase64,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  factory ServicioModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return ServicioModel(
      id: id,
      nombre: data['nombre']?.toString() ?? 'Sin nombre',
      descripcion: data['descripcion']?.toString() ?? '',
      precio: data['precio']?.toString() ?? '',
      logoBase64: data['logoBase64']?.toString() ?? '',
      fechaRegistro: data['fechaRegistro'],
      fechaActualizacion: data['fechaActualizacion'],
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'logoBase64': logoBase64,
      'fechaRegistro': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'logoBase64': logoBase64,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toPlainMap() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'logoBase64': logoBase64,
      'fechaRegistro': fechaRegistro,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  Map<String, String> toSelectionMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'logoBase64': logoBase64,
    };
  }
}
