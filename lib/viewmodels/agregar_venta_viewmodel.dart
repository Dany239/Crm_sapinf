import 'package:flutter/foundation.dart';

import '../models/venta_model.dart';
import '../repositories/ventas_repository.dart';
import '../servicios/sesion_usuario.dart';

class AgregarVentaViewModel extends ChangeNotifier {
  final VentasRepository _ventasRepository;

  AgregarVentaViewModel({
    VentasRepository? ventasRepository,
    String? clienteIdInicial,
    String? clienteNombreInicial,
  }) : _ventasRepository = ventasRepository ?? VentasRepository(),
       clienteIdSeleccionado = clienteIdInicial,
       clienteNombreSeleccionado = clienteNombreInicial;

  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  String servicioSeleccionado = 'Desarrollo de software';
  String estadoSeleccionado = 'Pendiente';
  bool cargando = false;
  String? mensajeError;

  void seleccionarCliente({
    required String clienteId,
    required String clienteNombre,
  }) {
    clienteIdSeleccionado = clienteId;
    clienteNombreSeleccionado = clienteNombre;
    notifyListeners();
  }

  void seleccionarServicio(String servicio) {
    servicioSeleccionado = servicio;
    notifyListeners();
  }

  void seleccionarEstado(String estado) {
    estadoSeleccionado = estado;
    notifyListeners();
  }

  Future<bool> guardarVenta({
    required String descripcion,
    required String monto,
  }) async {
    mensajeError = null;

    if (clienteIdSeleccionado == null || monto.trim().isEmpty) {
      mensajeError = 'Cliente y monto son obligatorios';
      notifyListeners();
      return false;
    }

    cargando = true;
    notifyListeners();

    try {
      final sesion = await obtenerSesionUsuario();
      final venta = VentaModel(
        clienteId: clienteIdSeleccionado,
        cliente: clienteNombreSeleccionado,
        servicio: servicioSeleccionado,
        descripcion: descripcion.trim(),
        monto: monto.trim(),
        estado: estadoSeleccionado,
      );

      await _ventasRepository.crearVenta(venta: venta, sesion: sesion);
      return true;
    } catch (_) {
      mensajeError = 'No se pudo guardar la venta';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
