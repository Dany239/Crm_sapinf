import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String? id;
  final String nombre;
  final String correo;
  final String rol;
  final bool accesoAdministrador;
  final dynamic fechaRegistro;
  final dynamic fechaActualizacion;
  final dynamic ultimaActividad;
  final String? foto;
  final String? fotoBase64;

  const UsuarioModel({
    this.id,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.accesoAdministrador = false,
    this.fechaRegistro,
    this.fechaActualizacion,
    this.ultimaActividad,
    this.foto,
    this.fotoBase64,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> data, {String? id}) {
    final rol = data['rol']?.toString() ?? 'vendedor';

    return UsuarioModel(
      id: id,
      nombre: data['nombre']?.toString() ?? 'Sin nombre',
      correo: data['correo']?.toString() ?? 'Sin correo',
      rol: rol,
      accesoAdministrador:
          rol == 'administrador' || data['accesoAdministrador'] == true,
      fechaRegistro: data['fechaRegistro'],
      fechaActualizacion: data['fechaActualizacion'],
      ultimaActividad: data['ultimaActividad'],
      foto: data['foto']?.toString(),
      fotoBase64: data['fotoBase64']?.toString(),
    );
  }

  Map<String, dynamic> toCreateMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'accesoAdministrador': rol == 'administrador' || accesoAdministrador,
      'fechaRegistro': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'accesoAdministrador': rol == 'administrador' || accesoAdministrador,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toPlainMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'accesoAdministrador': accesoAdministrador,
      'fechaRegistro': fechaRegistro,
      'fechaActualizacion': fechaActualizacion,
      'ultimaActividad': ultimaActividad,
      'foto': foto,
      'fotoBase64': fotoBase64,
    };
  }
}
