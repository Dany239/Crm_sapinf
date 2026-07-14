import 'package:cloud_firestore/cloud_firestore.dart';

import '../servicios/sesion_usuario.dart';

class SeguimientoModel {
  final String? id;
  final String? clienteId;
  final String? cliente;
  final String tipo;
  final String comentario;
  final String proximaGestion;
  final DateTime? fechaProxima;
  final String estado;
  final String evidenciaTipo;
  final String? vendedorId;
  final String? vendedorNombre;
  final String? vendedorCorreo;
  final dynamic fechaRegistro;
  final dynamic fechaRealizacion;
  final dynamic fechaActualizacion;

  const SeguimientoModel({
    this.id,
    required this.clienteId,
    required this.cliente,
    required this.tipo,
    required this.comentario,
    required this.proximaGestion,
    required this.fechaProxima,
    required this.estado,
    this.evidenciaTipo = 'Registro manual',
    this.vendedorId,
    this.vendedorNombre,
    this.vendedorCorreo,
    this.fechaRegistro,
    this.fechaRealizacion,
    this.fechaActualizacion,
  });

  factory SeguimientoModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return SeguimientoModel(
      id: id,
      clienteId: data['clienteId']?.toString(),
      cliente: data['cliente']?.toString(),
      tipo: data['tipo']?.toString() ?? 'Llamada',
      comentario: (data['comentario'] ?? data['resultado'] ?? '').toString(),
      proximaGestion: data['proximaGestion']?.toString() ?? '',
      fechaProxima: fechaDesdeDato(data['fechaProxima']),
      estado: data['estado']?.toString() ?? 'Realizado',
      evidenciaTipo: data['evidenciaTipo']?.toString() ?? 'Registro manual',
      vendedorId: data['vendedorId']?.toString(),
      vendedorNombre: data['vendedorNombre']?.toString(),
      vendedorCorreo: data['vendedorCorreo']?.toString(),
      fechaRegistro: data['fechaRegistro'],
      fechaRealizacion: data['fechaRealizacion'],
      fechaActualizacion: data['fechaActualizacion'],
    );
  }

  static DateTime? fechaDesdeDato(dynamic valor) {
    if (valor is Timestamp) return valor.toDate();
    if (valor is DateTime) return valor;
    return null;
  }

  Map<String, dynamic> toCreateMap(SesionUsuario sesion) {
    return {
      'clienteId': clienteId,
      'cliente': cliente,
      'tipo': tipo,
      'comentario': comentario,
      'resultado': comentario,
      'proximaGestion': proximaGestion,
      'fechaProxima': fechaProxima == null
          ? null
          : Timestamp.fromDate(fechaProxima!),
      'estado': estado,
      ...datosPropietario(sesion),
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fechaRealizacion': estado == 'Realizado'
          ? FieldValue.serverTimestamp()
          : null,
      'evidenciaTipo': evidenciaTipo,
    };
  }

  Map<String, dynamic> toUpdateMap({
    required SesionUsuario sesion,
    required dynamic fechaRealizacionAnterior,
  }) {
    return {
      'clienteId': clienteId,
      'cliente': cliente,
      'tipo': tipo,
      'comentario': comentario,
      'resultado': comentario,
      'proximaGestion': proximaGestion,
      'fechaProxima': fechaProxima == null
          ? null
          : Timestamp.fromDate(fechaProxima!),
      'estado': estado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'fechaRealizacion':
          estado == 'Realizado' && fechaRealizacionAnterior is! Timestamp
          ? FieldValue.serverTimestamp()
          : fechaRealizacionAnterior,
      'actualizadoPorId': sesion.uid,
      'actualizadoPorNombre': sesion.nombre,
      'evidenciaTipo': evidenciaTipo,
    };
  }

  Map<String, dynamic> toPlainMap() {
    return {
      'clienteId': clienteId,
      'cliente': cliente,
      'tipo': tipo,
      'comentario': comentario,
      'resultado': comentario,
      'proximaGestion': proximaGestion,
      'fechaProxima': fechaProxima == null
          ? null
          : Timestamp.fromDate(fechaProxima!),
      'estado': estado,
      'evidenciaTipo': evidenciaTipo,
      'vendedorId': vendedorId,
      'vendedorNombre': vendedorNombre,
      'vendedorCorreo': vendedorCorreo,
      'fechaRegistro': fechaRegistro,
      'fechaRealizacion': fechaRealizacion,
      'fechaActualizacion': fechaActualizacion,
    };
  }
}
