import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show DateTimeRange;

import '../servicios/exportacion_reportes_servicio.dart';

class MetricaReporte {
  final num valor;
  final double? variacion;

  const MetricaReporte({required this.valor, this.variacion});
}

class ReporteVendedor {
  final String id;
  final String nombre;

  const ReporteVendedor({required this.id, required this.nombre});
}

class ReporteVentaReciente {
  final String id;
  final Map<String, dynamic> data;

  const ReporteVentaReciente({required this.id, required this.data});
}

class ReportesViewModel {
  ReportesViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool perteneceAlRango(
    Map<String, dynamic> data,
    DateTimeRange rango, {
    String campoFecha = 'fechaRegistro',
  }) {
    final valor = data[campoFecha];
    if (valor is! Timestamp) return false;
    final fecha = valor.toDate();
    final inicio = DateTime(
      rango.start.year,
      rango.start.month,
      rango.start.day,
    );
    final finExclusivo = DateTime(
      rango.end.year,
      rango.end.month,
      rango.end.day + 1,
    );
    return !fecha.isBefore(inicio) && fecha.isBefore(finExclusivo);
  }

  DateTimeRange rangoMesActual() {
    final ahora = DateTime.now();
    return DateTimeRange(
      start: DateTime(ahora.year, ahora.month),
      end: DateTime(ahora.year, ahora.month + 1, 0),
    );
  }

  DateTimeRange rangoAnterior(DateTimeRange rango) {
    final dias = rango.end.difference(rango.start).inDays + 1;
    final fin = rango.start.subtract(const Duration(days: 1));
    return DateTimeRange(
      start: fin.subtract(Duration(days: dias - 1)),
      end: fin,
    );
  }

  bool mostrarEnFiltro(Map<String, dynamic> data, DateTimeRange? rango) {
    return rango == null || perteneceAlRango(data, rango);
  }

  double? calcularVariacion(num actual, num anterior) {
    if (anterior == 0) return actual == 0 ? 0 : null;
    return ((actual - anterior) / anterior) * 100;
  }

  Stream<MetricaReporte> contarDocumentos(
    String coleccion, {
    String? estado,
    DateTimeRange? rango,
  }) {
    return _firestore.collection(coleccion).snapshots().map((snapshot) {
      final rangoActual = rango ?? rangoMesActual();
      final anteriorRango = rangoAnterior(rangoActual);
      var totalMostrado = 0;
      var actual = 0;
      var anterior = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (estado != null && data['estado'] != estado) continue;

        if (mostrarEnFiltro(data, rango)) totalMostrado++;
        if (perteneceAlRango(data, rangoActual)) actual++;
        if (perteneceAlRango(data, anteriorRango)) anterior++;
      }

      return MetricaReporte(
        valor: totalMostrado,
        variacion: calcularVariacion(actual, anterior),
      );
    });
  }

  Stream<MetricaReporte> calcularMontoTotal(DateTimeRange? rango) {
    return _firestore.collection('ventas').snapshots().map((snapshot) {
      final rangoActual = rango ?? rangoMesActual();
      final anteriorRango = rangoAnterior(rangoActual);
      var totalMostrado = 0.0;
      var actual = 0.0;
      var anterior = 0.0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final monto = double.tryParse(data['monto'].toString()) ?? 0;

        if (mostrarEnFiltro(data, rango)) totalMostrado += monto;
        if (perteneceAlRango(data, rangoActual)) actual += monto;
        if (perteneceAlRango(data, anteriorRango)) anterior += monto;
      }

      return MetricaReporte(
        valor: totalMostrado,
        variacion: calcularVariacion(actual, anterior),
      );
    });
  }

  Stream<List<ReporteVendedor>> vendedoresExportacion() {
    return _firestore.collection('usuarios').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.data()['rol'] == 'vendedor')
          .map(
            (doc) => ReporteVendedor(
              id: doc.id,
              nombre: doc.data()['nombre']?.toString() ?? 'Sin nombre',
            ),
          )
          .toList();
    });
  }

  Future<DatosReporteExportacion> datosParaExportar({
    required DateTimeRange? rango,
    required String? vendedorId,
    required String vendedorNombre,
    required String periodo,
  }) async {
    final resultados = await Future.wait([
      _firestore.collection('ventas').get(),
      _firestore.collection('seguimientos').get(),
      _firestore.collection('clientes').get(),
    ]);

    List<Map<String, dynamic>> filtrar(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs.map((doc) => doc.data()).where((data) {
        if (rango != null && !perteneceAlRango(data, rango)) return false;
        if (vendedorId != null && data['vendedorId'] != vendedorId) {
          return false;
        }
        return true;
      }).toList();
    }

    return DatosReporteExportacion(
      ventas: filtrar(resultados[0]),
      seguimientos: filtrar(resultados[1]),
      clientes: filtrar(resultados[2]),
      periodo: periodo,
      vendedor: vendedorNombre,
    );
  }

  Stream<List<ReporteVentaReciente>> ultimasVentas(DateTimeRange? rango) {
    return _firestore.collection('ventas').snapshots().map((snapshot) {
      final ventas = snapshot.docs.where((doc) {
        return mostrarEnFiltro(doc.data(), rango);
      }).toList();

      ventas.sort((a, b) {
        final fechaA = a.data()['fechaRegistro'] as Timestamp?;
        final fechaB = b.data()['fechaRegistro'] as Timestamp?;
        return (fechaB?.millisecondsSinceEpoch ?? 0).compareTo(
          fechaA?.millisecondsSinceEpoch ?? 0,
        );
      });

      return ventas.take(3).map((doc) {
        return ReporteVentaReciente(id: doc.id, data: doc.data());
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> rendimientoVendedores(
    DateTimeRange? rango,
  ) {
    return _firestore.collection('ventas').snapshots().asyncMap((
      ventasSnapshot,
    ) async {
      final resultados = await Future.wait([
        _firestore.collection('seguimientos').get(),
        _firestore.collection('clientes').get(),
      ]);

      final seguimientosSnapshot = resultados[0];
      final clientesSnapshot = resultados[1];
      final vendedores = <String, Map<String, dynamic>>{};

      Map<String, dynamic> vendedorDe(Map<String, dynamic> data) {
        final id = data['vendedorId']?.toString() ?? 'sin-asignar';
        return vendedores.putIfAbsent(id, () {
          return {
            'nombre':
                data['vendedorNombre']?.toString() ?? 'Sin vendedor asignado',
            'ventas': 0,
            'cerradas': 0,
            'seguimientos': 0,
            'realizados': 0,
            'prospectos': 0,
          };
        });
      }

      for (final doc in ventasSnapshot.docs) {
        final data = doc.data();
        if (!mostrarEnFiltro(data, rango)) continue;
        final vendedor = vendedorDe(data);
        vendedor['ventas'] = (vendedor['ventas'] as int) + 1;
        if (data['estado'] == 'Cerrada') {
          vendedor['cerradas'] = (vendedor['cerradas'] as int) + 1;
        }
      }

      for (final doc in seguimientosSnapshot.docs) {
        final data = doc.data();
        if (!mostrarEnFiltro(data, rango)) continue;
        final vendedor = vendedorDe(data);
        vendedor['seguimientos'] = (vendedor['seguimientos'] as int) + 1;
        if (data['estado'] == 'Realizado' &&
            data['fechaRealizacion'] is Timestamp) {
          vendedor['realizados'] = (vendedor['realizados'] as int) + 1;
        }
      }

      for (final doc in clientesSnapshot.docs) {
        final data = doc.data();
        if (!mostrarEnFiltro(data, rango)) continue;
        if (data['estadoCliente'] == 'Cliente') continue;
        final vendedor = vendedorDe(data);
        vendedor['prospectos'] = (vendedor['prospectos'] as int) + 1;
      }

      final lista = vendedores.values.toList()
        ..sort((a, b) => (b['ventas'] as int).compareTo(a['ventas'] as int));

      return lista;
    });
  }
}
