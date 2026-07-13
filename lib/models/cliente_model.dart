import 'package:cloud_firestore/cloud_firestore.dart';

import '../servicios/sesion_usuario.dart';

class ClienteModel {
  final String? id;
  final String nombre;
  final String empresa;
  final String telefono;
  final String correo;
  final String direccion;
  final String estadoCliente;
  final List<String> serviciosInteresIds;
  final List<String> serviciosInteresNombres;
  final String? vendedorId;
  final String? vendedorNombre;
  final dynamic fechaRegistro;

  const ClienteModel({
    this.id,
    required this.nombre,
    required this.empresa,
    required this.telefono,
    required this.correo,
    required this.direccion,
    required this.estadoCliente,
    this.serviciosInteresIds = const [],
    this.serviciosInteresNombres = const [],
    this.vendedorId,
    this.vendedorNombre,
    this.fechaRegistro,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ClienteModel(
      id: id,
      nombre: data['nombre']?.toString() ?? 'Sin nombre',
      empresa: data['empresa']?.toString() ?? 'Sin empresa',
      telefono: data['telefono']?.toString() ?? 'Sin teléfono',
      correo: data['correo']?.toString() ?? 'Sin correo',
      direccion: data['direccion']?.toString() ?? '',
      estadoCliente: data['estadoCliente']?.toString() ?? 'Cliente potencial',
      serviciosInteresIds: _listaString(data['serviciosInteresIds']),
      serviciosInteresNombres: _listaString(data['serviciosInteresNombres']),
      vendedorId: data['vendedorId']?.toString(),
      vendedorNombre: data['vendedorNombre']?.toString(),
      fechaRegistro: data['fechaRegistro'],
    );
  }

  static List<String> _listaString(dynamic valor) {
    if (valor is! List) return [];
    return valor.whereType<String>().toList();
  }

  Map<String, dynamic> toCreateMap(SesionUsuario sesion) {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'correo': correo,
      'empresa': empresa,
      'direccion': direccion,
      'serviciosInteresIds': serviciosInteresIds,
      'serviciosInteresNombres': serviciosInteresNombres,
      'estadoCliente': estadoCliente,
      ...datosPropietario(sesion),
      'fechaRegistro': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toPlainMap() {
    return {
      'nombre': nombre,
      'empresa': empresa,
      'telefono': telefono,
      'correo': correo,
      'direccion': direccion,
      'estadoCliente': estadoCliente,
      'serviciosInteresIds': serviciosInteresIds,
      'serviciosInteresNombres': serviciosInteresNombres,
      'vendedorId': vendedorId,
      'vendedorNombre': vendedorNombre,
      'fechaRegistro': fechaRegistro,
    };
  }
}
