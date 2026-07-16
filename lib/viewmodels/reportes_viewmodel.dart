import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange;
import 'package:intl/intl.dart';

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

class ReportesViewModel extends ChangeNotifier {
  ReportesViewModel({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  DateTimeRange? rangoSeleccionado;
  String? vendedorIdExportacion;
  String vendedorNombreExportacion = 'Todos los vendedores';
  bool exportando = false;

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

  void seleccionarRango(DateTimeRange? rango) {
    rangoSeleccionado = rango;
    notifyListeners();
  }

  void aplicarFiltro(String opcion, DateTime ahora) {
    if (opcion == 'todos') {
      seleccionarRango(null);
      return;
    }

    if (opcion == 'hoy') {
      seleccionarRango(DateTimeRange(start: ahora, end: ahora));
      return;
    }

    if (opcion == 'mes') {
      seleccionarRango(rangoMesActual());
      return;
    }

    if (opcion == 'anio') {
      seleccionarRango(
        DateTimeRange(
          start: DateTime(ahora.year),
          end: DateTime(ahora.year, 12, 31),
        ),
      );
    }
  }

  void seleccionarVendedorExportacion(
    String? vendedorId,
    List<ReporteVendedor> vendedores,
  ) {
    if (vendedorId == null || vendedorId == 'todos') {
      vendedorIdExportacion = null;
      vendedorNombreExportacion = 'Todos los vendedores';
      notifyListeners();
      return;
    }

    vendedorIdExportacion = vendedorId;
    final vendedor = vendedores.firstWhere((vendedor) {
      return vendedor.id == vendedorId;
    });
    vendedorNombreExportacion = vendedor.nombre;
    notifyListeners();
  }

  String textoFiltroActual() {
    final rango = rangoSeleccionado;
    if (rango == null) return 'Todos los datos';

    final formato = DateFormat('dd MMM yyyy', 'es');
    if (rango.start.year == rango.end.year &&
        rango.start.month == rango.end.month &&
        rango.start.day == rango.end.day) {
      return formato.format(rango.start);
    }

    return '${formato.format(rango.start)} - ${formato.format(rango.end)}';
  }

  String textoMesAnio(DateTime fecha) {
    return '${DateFormat.MMMM('es').format(fecha)} ${fecha.year}';
  }

  String formatoLempiras(dynamic valor) {
    final monto = num.tryParse(valor?.toString() ?? '0') ?? 0;
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 2,
    ).format(monto);
  }

  String fechaCorta(dynamic valor) {
    if (valor is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(valor.toDate());
  }

  String iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(' ')
        .where((parte) => parte.isNotEmpty)
        .toList();

    if (partes.isEmpty) return 'SV';
    if (partes.length == 1) {
      return partes.first
          .substring(0, partes.first.length.clamp(0, 2))
          .toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  bool mostrarEnFiltro(Map<String, dynamic> data, DateTimeRange? rango) {
    return rango == null || perteneceAlRango(data, rango);
  }

  double? calcularVariacion(num actual, num anterior) {
    if (anterior == 0) return actual == 0 ? 0 : null;
    return ((actual - anterior) / anterior) * 100;
  }

  Stream<MetricaReporte> contarDocumentos(String coleccion, {String? estado}) {
    return _firestore.collection(coleccion).snapshots().map((snapshot) {
      final rango = rangoSeleccionado;
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

  Stream<MetricaReporte> calcularMontoTotal() {
    return _firestore.collection('ventas').snapshots().map((snapshot) {
      final rango = rangoSeleccionado;
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
    DateTimeRange? rango,
    String? vendedorId,
    String? vendedorNombre,
    String? periodo,
  }) async {
    final rangoFiltro = rango ?? rangoSeleccionado;
    final vendedorFiltro = vendedorId ?? vendedorIdExportacion;

    final resultados = await Future.wait([
      _firestore.collection('ventas').get(),
      _firestore.collection('seguimientos').get(),
      _firestore.collection('clientes').get(),
    ]);

    List<Map<String, dynamic>> filtrar(
      QuerySnapshot<Map<String, dynamic>> snapshot,
    ) {
      return snapshot.docs.map((doc) => doc.data()).where((data) {
        if (rangoFiltro != null && !perteneceAlRango(data, rangoFiltro)) {
          return false;
        }
        if (vendedorFiltro != null && data['vendedorId'] != vendedorFiltro) {
          return false;
        }
        return true;
      }).toList();
    }

    return DatosReporteExportacion(
      ventas: filtrar(resultados[0]),
      seguimientos: filtrar(resultados[1]),
      clientes: filtrar(resultados[2]),
      periodo: periodo ?? textoFiltroActual(),
      vendedor: vendedorNombre ?? vendedorNombreExportacion,
    );
  }

  Future<String?> exportarReporte(String tipo, {required String accion}) async {
    if (exportando) return null;

    exportando = true;
    notifyListeners();

    try {
      final datos = await datosParaExportar();
      final fechaArchivo = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      late final List<int> bytes;
      late final String nombreArchivo;
      late final String mimeType;

      if (tipo == 'excel') {
        bytes = ExportacionReportesServicio.generarExcel(datos);
        nombreArchivo = 'reporte_comercial_$fechaArchivo.xlsx';
        mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else {
        final ejecutivo = tipo == 'ejecutivo';
        bytes = await ExportacionReportesServicio.generarPdf(
          datos,
          ejecutivo: ejecutivo,
        );
        nombreArchivo = ejecutivo
            ? 'reporte_ejecutivo_$fechaArchivo.pdf'
            : 'reporte_comercial_$fechaArchivo.pdf';
        mimeType = 'application/pdf';
      }

      if (accion == 'abrir') {
        await ExportacionReportesServicio.abrir(
          bytes: bytes,
          nombreArchivo: nombreArchivo,
          mimeType: mimeType,
        );
      } else {
        await ExportacionReportesServicio.compartir(
          bytes: Uint8List.fromList(bytes),
          nombreArchivo: nombreArchivo,
          mimeType: mimeType,
          periodo: datos.periodo,
        );
      }

      return null;
    } catch (error) {
      return 'No se pudo generar el reporte: $error';
    } finally {
      exportando = false;
      notifyListeners();
    }
  }

  Stream<List<ReporteVentaReciente>> ultimasVentas() {
    return _firestore.collection('ventas').snapshots().map((snapshot) {
      final rango = rangoSeleccionado;
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

  Stream<List<Map<String, dynamic>>> rendimientoVendedores() {
    return _firestore.collection('ventas').snapshots().asyncMap((
      ventasSnapshot,
    ) async {
      final rango = rangoSeleccionado;
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
