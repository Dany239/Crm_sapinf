import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';
import '../models/venta_model.dart';
import '../repositories/clientes_repository.dart';
import '../repositories/ventas_repository.dart';
import '../servicios/sesion_usuario.dart';

class AgregarVentaViewModel extends ChangeNotifier {
  final VentasRepository _ventasRepository;
  final ClientesRepository _clientesRepository;

  AgregarVentaViewModel({
    VentasRepository? ventasRepository,
    ClientesRepository? clientesRepository,
    String? clienteIdInicial,
    String? clienteNombreInicial,
  }) : _ventasRepository = ventasRepository ?? VentasRepository(),
       _clientesRepository = clientesRepository ?? ClientesRepository(),
       clienteIdSeleccionado = clienteIdInicial,
       clienteNombreSeleccionado = clienteNombreInicial;

  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  String servicioSeleccionado = 'Desarrollo de software';
  String estadoSeleccionado = 'Pendiente';
  bool cargando = false;
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
