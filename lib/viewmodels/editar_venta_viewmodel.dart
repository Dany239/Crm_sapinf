import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../repositories/clientes_repository.dart';
import '../repositories/ventas_repository.dart';
import '../servicios/sesion_usuario.dart';

class EditarVentaViewModel extends ChangeNotifier {
  final VentasRepository _ventasRepository;
  final ClientesRepository _clientesRepository;
  final String ventaId;
  final VentaModel ventaOriginal;

  EditarVentaViewModel({
    required this.ventaId,
    required Map<String, dynamic> venta,
    VentasRepository? ventasRepository,
    ClientesRepository? clientesRepository,
  }) : _ventasRepository = ventasRepository ?? VentasRepository(),
       _clientesRepository = clientesRepository ?? ClientesRepository(),
       ventaOriginal = VentaModel.fromMap(venta, id: ventaId) {
    clienteIdSeleccionado = ventaOriginal.clienteId;
    clienteNombreSeleccionado = ventaOriginal.cliente;
    servicioSeleccionado = ventaOriginal.servicio;
    estadoSeleccionado = ventaOriginal.estado;
  }

  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  String servicioSeleccionado = 'Desarrollo de software';
  String estadoSeleccionado = 'Pendiente';
  bool cargando = false;
  bool eliminando = false;
  String? mensajeError;

  Stream<List<ClienteModel>> escucharClientesDisponibles(SesionUsuario sesion) {
    return _clientesRepository.escucharClientesDisponibles(sesion);
  }

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

  Future<bool> actualizarVenta({
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

      await _ventasRepository.actualizarVenta(
        ventaId: ventaId,
        venta: venta,
        ventaAnterior: ventaOriginal,
        sesion: sesion,
      );

      return true;
    } catch (_) {
      mensajeError = 'No se pudo actualizar la venta';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarVenta() async {
    mensajeError = null;
    eliminando = true;
    notifyListeners();

    try {
      await _ventasRepository.eliminarVenta(ventaId);
      return true;
    } catch (_) {
      mensajeError = 'No se pudo eliminar la venta';
      return false;
    } finally {
      eliminando = false;
      notifyListeners();
    }
  }
}
