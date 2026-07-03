import 'package:cloud_firestore/cloud_firestore.dart';

import 'sesion_usuario.dart';

class NotificacionesServicio {
  static final CollectionReference<Map<String, dynamic>> _coleccion =
      FirebaseFirestore.instance.collection('notificaciones');

  static Future<void> crear({
    required String titulo,
    required String descripcion,
    required String tipo,
    required String icono,
    required String color,
    required SesionUsuario autor,
    List<String> usuariosDestinatarios = const [],
    List<String> rolesDestinatarios = const ['administrador'],
    String? referenciaId,
    String? referenciaColeccion,
  }) async {
    final usuarios =
        usuariosDestinatarios.where((uid) => uid.isNotEmpty).toSet().toList();

    try {
      await _coleccion.add({
        'titulo': titulo,
        'descripcion': descripcion,
        'tipo': tipo,
        'icono': icono,
        'color': color,
        'autorId': autor.uid,
        'autorNombre': autor.nombre,
        'usuariosDestinatarios': usuarios,
        'rolesDestinatarios': rolesDestinatarios,
        'leidaPor': <String>[],
        'fecha': FieldValue.serverTimestamp(),
        if (referenciaId != null) 'referenciaId': referenciaId,
        if (referenciaColeccion != null)
          'referenciaColeccion': referenciaColeccion,
      });
    } on FirebaseException {
      // La operacion principal no debe fallar si el aviso no puede crearse.
    }
  }

  static bool esVisiblePara(
    Map<String, dynamic> data,
    SesionUsuario sesion,
  ) {
    final usuarios =
        List<String>.from(data['usuariosDestinatarios'] as List? ?? const []);
    final roles =
        List<String>.from(data['rolesDestinatarios'] as List? ?? const []);

    if (usuarios.isEmpty && roles.isEmpty) return true;
    if (usuarios.contains(sesion.uid)) return true;
    if (sesion.esAdministrador && roles.contains('administrador')) return true;
    return roles.contains(sesion.rol);
  }

  static bool estaLeidaPor(
    Map<String, dynamic> data,
    String uid,
  ) {
    final leidaPor = List<String>.from(data['leidaPor'] as List? ?? const []);
    return data['leida'] == true || leidaPor.contains(uid);
  }

  static Future<void> marcarLeida(
    DocumentReference referencia,
    String uid,
  ) {
    return referencia.update({
      'leidaPor': FieldValue.arrayUnion([uid]),
    });
  }

  static Future<void> generarRecordatoriosPendientes(
    SesionUsuario sesion,
  ) async {
    if (sesion.uid.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('seguimientos')
          .where('vendedorId', isEqualTo: sesion.uid)
          .get();
      final ahora = DateTime.now();
      final finDeHoy = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        23,
        59,
        59,
      );
      final claveDia =
          '${ahora.year}${ahora.month.toString().padLeft(2, '0')}${ahora.day.toString().padLeft(2, '0')}';

      for (final seguimiento in snapshot.docs) {
        final data = seguimiento.data();
        if (data['estado'] != 'Pendiente') continue;
        final fecha = data['fechaProxima'];
        if (fecha is! Timestamp || fecha.toDate().isAfter(finDeHoy)) continue;

        final referencia =
            _coleccion.doc('recordatorio_${seguimiento.id}_$claveDia');
        if ((await referencia.get()).exists) continue;

        await referencia.set({
          'titulo': fecha.toDate().isBefore(
                    DateTime(ahora.year, ahora.month, ahora.day),
                  )
              ? 'Seguimiento atrasado'
              : 'Seguimiento para hoy',
          'descripcion':
              '${data['tipo'] ?? 'Seguimiento'} pendiente con ${data['cliente'] ?? 'el cliente'}.',
          'tipo': 'recordatorio_seguimiento',
          'icono': 'phone',
          'color': 'orange',
          'autorId': sesion.uid,
          'autorNombre': sesion.nombre,
          'usuariosDestinatarios': [sesion.uid],
          'rolesDestinatarios': ['administrador'],
          'leidaPor': <String>[],
          'fecha': FieldValue.serverTimestamp(),
          'referenciaId': seguimiento.id,
          'referenciaColeccion': 'seguimientos',
        });
      }
    } on FirebaseException {
      // Los recordatorios se volveran a intentar al abrir el dashboard.
    }
  }
}
