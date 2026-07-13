import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/venta_model.dart';
import '../repositories/ventas_repository.dart';
import '../servicios/sesion_usuario.dart';

class VentasViewModel extends ChangeNotifier {
  final VentasRepository _repository;
  final String? estadoInicial;

  String textoBusqueda = '';

  VentasViewModel({VentasRepository? repository, this.estadoInicial})
    : _repository = repository ?? VentasRepository();

  Stream<List<VentaModel>> get ventasStream => _repository.escucharVentas();

  void actualizarBusqueda(String valor) {
    textoBusqueda = valor.trim().toLowerCase();
    notifyListeners();
  }

  void limpiarBusqueda() {
    textoBusqueda = '';
    notifyListeners();
  }

  List<VentaModel> filtrarVentas(
    List<VentaModel> ventas,
    SesionUsuario sesion,
  ) {
    return ventas.where((venta) {
      if (!sesion.esAdministrador && venta.vendedorId != sesion.uid) {
        return false;
      }

      if (estadoInicial != null && venta.estado != estadoInicial) {
        return false;
      }

      if (textoBusqueda.isEmpty) {
        return true;
      }

      final cliente = (venta.cliente ?? '').toLowerCase();
      final servicio = venta.servicio.toLowerCase();
      final estado = venta.estado.toLowerCase();
      final monto = venta.monto.toLowerCase();
      final vendedor = (venta.vendedorNombre ?? '').toLowerCase();

      return cliente.contains(textoBusqueda) ||
          servicio.contains(textoBusqueda) ||
          estado.contains(textoBusqueda) ||
          monto.contains(textoBusqueda) ||
          vendedor.contains(textoBusqueda);
    }).toList();
  }

  String formatoLempiras(dynamic valor) {
    final monto = num.tryParse(valor?.toString() ?? '0') ?? 0;
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 0,
    );

    return formato.format(monto);
  }

  String fechaCorta(dynamic valor) {
    if (valor is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(valor.toDate());
  }
}
