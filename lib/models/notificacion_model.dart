import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacionModel {
  final String id;
  final String titulo;
  final String descripcion;
  final String tipo;
  final String icono;
  final String color;
  final String? autorId;
  final String? autorNombre;
  final List<String> usuariosDestinatarios;
  final List<String> rolesDestinatarios;
  final List<String> leidaPor;
  final bool leida;
  final Timestamp? fecha;
  final String? referenciaId;
  final String? referenciaColeccion;

  const NotificacionModel({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.icono,
    required this.color,
    this.autorId,
    this.autorNombre,
    this.usuariosDestinatarios = const [],
    this.rolesDestinatarios = const [],
    this.leidaPor = const [],
    this.leida = false,
    this.fecha,
    this.referenciaId,
    this.referenciaColeccion,
  });

  factory NotificacionModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificacionModel(
      id: id,
      titulo: data['titulo']?.toString() ?? 'Notificación',
      descripcion: data['descripcion']?.toString() ?? '',
      tipo: data['tipo']?.toString() ?? '',
      icono: data['icono']?.toString() ?? '',
      color: data['color']?.toString() ?? '',
      autorId: data['autorId']?.toString(),
      autorNombre: data['autorNombre']?.toString(),
      usuariosDestinatarios: List<String>.from(
        data['usuariosDestinatarios'] as List? ?? const [],
      ),
      rolesDestinatarios: List<String>.from(
        data['rolesDestinatarios'] as List? ?? const [],
      ),
      leidaPor: List<String>.from(data['leidaPor'] as List? ?? const []),
      leida: data['leida'] == true,
      fecha: data['fecha'] is Timestamp ? data['fecha'] as Timestamp : null,
      referenciaId: data['referenciaId']?.toString(),
      referenciaColeccion: data['referenciaColeccion']?.toString(),
    );
  }

  bool estaLeidaPor(String uid) {
    return leida || leidaPor.contains(uid);
  }
}
