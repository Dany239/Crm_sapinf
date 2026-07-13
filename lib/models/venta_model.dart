import 'package:cloud_firestore/cloud_firestore.dart';

import '../servicios/sesion_usuario.dart';

class VentaModel {
  final String? id;
  final String? clienteId;
  final String? cliente;
  final String servicio;
  final String descripcion;
  final String monto;
  final String estado;
  final String? vendedorId;
  final String? vendedorNombre;
  final String? vendedorCorreo;
  final dynamic fechaRegistro;
  final dynamic fechaActualizacion;

  const VentaModel({
    this.id,
    required this.clienteId,
    required this.cliente,
    required this.servicio,
    required this.descripcion,
    required this.monto,
    required this.estado,
    this.vendedorId,
    this.vendedorNombre,
    this.vendedorCorreo,
    this.fechaRegistro,
    this.fechaActualizacion,
  });

  factory VentaModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return VentaModel(
      id: id,
      clienteId: data['clienteId']?.toString(),
      cliente: data['cliente']?.toString(),
      servicio: data['servicio']?.toString() ?? 'Desarrollo de software',
      descripcion: data['descripcion']?.toString() ?? '',
      monto: data['monto']?.toString() ?? '',
      estado: data['estado']?.toString() ?? 'Pendiente',
      vendedorId: data['vendedorId']?.toString(),
      vendedorNombre: data['vendedorNombre']?.toString(),
      vendedorCorreo: data['vendedorCorreo']?.toString(),
      fechaRegistro: data['fechaRegistro'],
      fechaActualizacion: data['fechaActualizacion'],
    );
  }

  Map<String, dynamic> toCreateMap(SesionUsuario sesion) {
    return {
      'clienteId': clienteId,
      'cliente': cliente,
      'servicio': servicio,
      'descripcion': descripcion,
      'monto': monto,
      'estado': estado,
      ...datosPropietario(sesion),
      'fechaRegistro': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'clienteId': clienteId,
      'cliente': cliente,
      'servicio': servicio,
      'descripcion': descripcion,
      'monto': monto,
      'estado': estado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
  }
}
