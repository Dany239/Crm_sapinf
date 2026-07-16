import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class CentroControlDocumento {
  final String id;
  final Map<String, dynamic> data;

  const CentroControlDocumento({required this.id, required this.data});
}

class RankingVendedor {
  final String id;
  final String nombre;
  final double monto;
  final int ventas;

  const RankingVendedor({
    required this.id,
    required this.nombre,
    required this.monto,
    required this.ventas,
  });
}

class CentroControlComercialViewModel extends ChangeNotifier {
  final List<StreamSubscription> _suscripciones = [];

  List<CentroControlDocumento> usuarios = [];
  List<CentroControlDocumento> seguimientos = [];
  List<CentroControlDocumento> ventas = [];
  List<CentroControlDocumento> clientes = [];
  List<CentroControlDocumento> notificaciones = [];

  SesionUsuario? sesion;
  bool cargando = true;
  bool accesoPermitido = false;

  Future<void> inicializar() async {
    try {
      final sesionActual = await obtenerSesionUsuario();
      sesion = sesionActual;

      if (!sesionActual.esAdministrador) {
        cargando = false;
        notifyListeners();
        return;
      }

      accesoPermitido = true;
      _escucharColecciones();
    } catch (_) {
      cargando = false;
      notifyListeners();
    }
  }

  void _escucharColecciones() {
    _agregarEscucha('usuarios', (docs) => usuarios = docs);
    _agregarEscucha('seguimientos', (docs) => seguimientos = docs);
    _agregarEscucha('ventas', (docs) => ventas = docs);
    _agregarEscucha('clientes', (docs) => clientes = docs);
    _agregarEscucha('notificaciones', (docs) => notificaciones = docs);

    cargando = false;
    notifyListeners();
  }

  void _agregarEscucha(
    String coleccion,
    void Function(List<CentroControlDocumento>) actualizar,
  ) {
    _suscripciones.add(
      FirebaseFirestore.instance.collection(coleccion).snapshots().listen((
        snapshot,
      ) {
        actualizar(
          snapshot.docs
              .map(
                (doc) => CentroControlDocumento(id: doc.id, data: doc.data()),
              )
              .toList(),
        );
        notifyListeners();
      }),
    );
  }

  bool esHoy(dynamic valor) {
    if (valor is! Timestamp) return false;
    final fecha = valor.toDate();
    final ahora = DateTime.now();
    return fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day;
  }

  bool esDelMes(dynamic valor) {
    if (valor is! Timestamp) return false;
    final fecha = valor.toDate();
    final ahora = DateTime.now();
    return fecha.year == ahora.year && fecha.month == ahora.month;
  }

  String formatoLempiras(num monto) {
    return NumberFormat.currency(
      locale: 'es_HN',
      symbol: 'L. ',
      decimalDigits: 2,
    ).format(monto);
  }

  List<CentroControlDocumento> get vendedoresConectados {
    final ahora = DateTime.now();
    return usuarios.where((doc) {
      final data = doc.data;
      final actividad = data['ultimaActividad'];
      return data['rol'] == 'vendedor' &&
          actividad is Timestamp &&
          ahora.difference(actividad.toDate()).inMinutes <= 15;
    }).toList();
  }

  List<CentroControlDocumento> get seguimientosDeHoy {
    return seguimientos.where((doc) {
      final data = doc.data;
      return data['estado'] == 'Realizado' && esHoy(data['fechaRealizacion']);
    }).toList();
  }

  List<CentroControlDocumento> get ventasDeHoy {
    return ventas.where((doc) => esHoy(doc.data['fechaRegistro'])).toList();
  }

  double get totalVentasHoy {
    return ventasDeHoy.fold<double>(
      0,
      (total, doc) =>
          total + (double.tryParse(doc.data['monto']?.toString() ?? '') ?? 0),
    );
  }

  List<CentroControlDocumento> get clientesSinSeguimiento {
    final clientesConSeguimiento = seguimientos
        .map((doc) => doc.data['clienteId']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    return clientes
        .where((doc) => !clientesConSeguimiento.contains(doc.id))
        .toList();
  }

  List<CentroControlDocumento> get alertasPendientes {
    final sesionActual = sesion;
    if (sesionActual == null) return [];

    final resultado = notificaciones.where((doc) {
      final data = doc.data;
      return NotificacionesServicio.esVisiblePara(data, sesionActual) &&
          !NotificacionesServicio.estaLeidaPor(data, sesionActual.uid);
    }).toList();

    resultado.sort((a, b) {
      final fechaA = a.data['fecha'];
      final fechaB = b.data['fecha'];
      if (fechaA is! Timestamp) return 1;
      if (fechaB is! Timestamp) return -1;
      return fechaB.compareTo(fechaA);
    });

    return resultado;
  }

  List<RankingVendedor> get rankingMensual {
    final ranking = <String, Map<String, dynamic>>{};

    for (final doc in ventas) {
      final data = doc.data;
      if (!esDelMes(data['fechaRegistro'])) continue;

      final id = data['vendedorId']?.toString() ?? 'sin-asignar';
      final registro = ranking.putIfAbsent(
        id,
        () => {
          'nombre':
              data['vendedorNombre']?.toString() ?? 'Sin vendedor asignado',
          'monto': 0.0,
          'ventas': 0,
        },
      );
      registro['monto'] =
          (registro['monto'] as double) +
          (double.tryParse(data['monto']?.toString() ?? '') ?? 0);
      registro['ventas'] = (registro['ventas'] as int) + 1;
    }

    final resultado =
        ranking.entries
            .map(
              (entry) => RankingVendedor(
                id: entry.key,
                nombre: entry.value['nombre'] as String,
                monto: entry.value['monto'] as double,
                ventas: entry.value['ventas'] as int,
              ),
            )
            .toList()
          ..sort((a, b) => b.monto.compareTo(a.monto));

    return resultado;
  }

  Future<void> recargar() async {
    await Future.wait([
      FirebaseFirestore.instance.collection('usuarios').get(),
      FirebaseFirestore.instance.collection('seguimientos').get(),
      FirebaseFirestore.instance.collection('ventas').get(),
      FirebaseFirestore.instance.collection('clientes').get(),
    ]);
  }

  @override
  void dispose() {
    for (final suscripcion in _suscripciones) {
      suscripcion.cancel();
    }
    super.dispose();
  }
}
