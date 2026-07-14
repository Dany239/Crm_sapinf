import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/cliente_model.dart';
import '../repositories/clientes_repository.dart';
import '../servicios/sesion_usuario.dart';

class DetalleClienteViewModel extends ChangeNotifier {
  final ClientesRepository _clientesRepository;
  final String clienteId;
  final ClienteModel cliente;

  DetalleClienteViewModel({
    required this.clienteId,
    required Map<String, dynamic> datosCliente,
    ClientesRepository? clientesRepository,
  }) : _clientesRepository = clientesRepository ?? ClientesRepository(),
       cliente = ClienteModel.fromMap(datosCliente, id: clienteId);

  bool convirtiendo = false;
  bool eliminando = false;
  String? mensajeError;

  String get nombre => cliente.nombre;
  String get empresa => cliente.empresa;
  String get telefono => cliente.telefono;
  String get correo => cliente.correo;
  String get direccion => cliente.direccion;
  String get estadoCliente => cliente.estadoCliente;
  bool get esCliente => estadoCliente == 'Cliente';

  Stream<List<Map<String, dynamic>>> get ventasStream =>
      _clientesRepository.escucharVentasPorCliente(nombre);

  Stream<List<Map<String, dynamic>>> get seguimientosStream =>
      _clientesRepository.escucharSeguimientosPorCliente(nombre);

  Future<bool> convertirEnCliente() async {
    mensajeError = null;
    convirtiendo = true;
    notifyListeners();

    try {
      final sesion = await obtenerSesionUsuario();
      await _clientesRepository.convertirEnCliente(
        clienteId: clienteId,
        cliente: cliente,
        sesion: sesion,
      );
      return true;
    } catch (_) {
      mensajeError = 'No se pudo convertir el prospecto en cliente';
      return false;
    } finally {
      convirtiendo = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarCliente() async {
    mensajeError = null;
    eliminando = true;
    notifyListeners();

    try {
      await _clientesRepository.eliminarCliente(clienteId);
      return true;
    } catch (_) {
      mensajeError = 'No se pudo eliminar el cliente';
      return false;
    } finally {
      eliminando = false;
      notifyListeners();
    }
  }

  ResumenCliente calcularResumen({
    required List<Map<String, dynamic>> ventas,
    required List<Map<String, dynamic>> seguimientos,
  }) {
    double totalComprado = 0;
    Timestamp? ultimaVentaFecha;

    for (final venta in ventas) {
      final monto = double.tryParse(venta['monto'].toString()) ?? 0;
      totalComprado += monto;

      final fecha = venta['fechaRegistro'];
      if (fecha is Timestamp &&
          (ultimaVentaFecha == null ||
              fecha.toDate().isAfter(ultimaVentaFecha.toDate()))) {
        ultimaVentaFecha = fecha;
      }
    }

    return ResumenCliente(
      totalComprado: totalComprado,
      cantidadVentas: ventas.length,
      cantidadSeguimientos: seguimientos.length,
      ultimaVentaFecha: ultimaVentaFecha,
    );
  }

  List<Map<String, dynamic>> crearTimeline({
    required List<Map<String, dynamic>> ventas,
    required List<Map<String, dynamic>> seguimientos,
    required bool incluirVentas,
  }) {
    final actividades = <Map<String, dynamic>>[];

    if (incluirVentas) {
      for (final venta in ventas) {
        final fecha = venta['fechaRegistro'];

        actividades.add({
          'tipo': 'venta',
          'titulo': 'Venta registrada',
          'detalle': venta['servicio'] ?? '',
          'monto': double.tryParse(venta['monto'].toString()) ?? 0,
          'estado': venta['estado'] ?? '',
          'fecha': fecha is Timestamp ? fecha.toDate() : DateTime.now(),
        });
      }
    }

    for (final seguimiento in seguimientos) {
      final fecha = seguimiento['fechaRegistro'];

      actividades.add({
        'tipo': 'seguimiento',
        'titulo': seguimiento['tipo'] ?? 'Seguimiento',
        'detalle': seguimiento['comentario'] ?? '',
        'estado': seguimiento['estado'] ?? '',
        'fecha': fecha is Timestamp ? fecha.toDate() : DateTime.now(),
      });
    }

    actividades.sort((a, b) => b['fecha'].compareTo(a['fecha']));
    return actividades;
  }

  String formatoLempiras(num valor) {
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 0,
    );

    return formato.format(valor);
  }

  String formatearFecha(Timestamp? fecha) {
    if (fecha == null) return 'Sin fecha';
    final date = fecha.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatearFechaHora(dynamic fecha) {
    if (fecha is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
  }
}

class ResumenCliente {
  final double totalComprado;
  final int cantidadVentas;
  final int cantidadSeguimientos;
  final Timestamp? ultimaVentaFecha;

  const ResumenCliente({
    required this.totalComprado,
    required this.cantidadVentas,
    required this.cantidadSeguimientos,
    required this.ultimaVentaFecha,
  });
}
