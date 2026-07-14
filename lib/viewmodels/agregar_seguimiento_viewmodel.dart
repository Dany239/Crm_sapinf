import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';
import '../models/seguimiento_model.dart';
import '../repositories/clientes_repository.dart';
import '../repositories/seguimientos_repository.dart';
import '../servicios/sesion_usuario.dart';

class AgregarSeguimientoViewModel extends ChangeNotifier {
  final SeguimientosRepository _seguimientosRepository;
  final ClientesRepository _clientesRepository;

  AgregarSeguimientoViewModel({
    SeguimientosRepository? seguimientosRepository,
    ClientesRepository? clientesRepository,
    String? clienteIdInicial,
    String? clienteNombreInicial,
  }) : _seguimientosRepository =
           seguimientosRepository ?? SeguimientosRepository(),
       _clientesRepository = clientesRepository ?? ClientesRepository(),
       clienteIdSeleccionado = clienteIdInicial,
       clienteNombreSeleccionado = clienteNombreInicial;

  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  DateTime? fechaProximaSeleccionada;
  String tipoSeleccionado = 'Llamada';
  String estadoSeleccionado = 'Realizado';
  bool cargando = false;
  String? mensajeError;

  Stream<List<ClienteModel>> escucharClientesPorSesion(SesionUsuario sesion) {
    return _clientesRepository.escucharClientes().map(
      (clientes) => clientes
          .where(
            (cliente) =>
                sesion.esAdministrador || cliente.vendedorId == sesion.uid,
          )
          .toList(),
    );
  }

  void seleccionarCliente({
    required String clienteId,
    required String clienteNombre,
  }) {
    clienteIdSeleccionado = clienteId;
    clienteNombreSeleccionado = clienteNombre;
    notifyListeners();
  }

  void seleccionarTipo(String tipo) {
    tipoSeleccionado = tipo;
    notifyListeners();
  }

  void seleccionarEstado(String estado) {
    estadoSeleccionado = estado;
    notifyListeners();
  }

  void seleccionarFechaProxima(DateTime fecha) {
    fechaProximaSeleccionada = fecha;
    notifyListeners();
  }

  String textoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  Future<bool> guardarSeguimiento({
    required String comentario,
    required String proximaGestion,
  }) async {
    mensajeError = null;

    if (clienteIdSeleccionado == null || comentario.trim().isEmpty) {
      mensajeError = 'Cliente y resultado u observación son obligatorios';
      notifyListeners();
      return false;
    }

    cargando = true;
    notifyListeners();

    try {
      final sesion = await obtenerSesionUsuario();
      final seguimiento = SeguimientoModel(
        clienteId: clienteIdSeleccionado,
        cliente: clienteNombreSeleccionado,
        tipo: tipoSeleccionado,
        comentario: comentario.trim(),
        proximaGestion: proximaGestion.trim(),
        fechaProxima: fechaProximaSeleccionada,
        estado: estadoSeleccionado,
      );

      await _seguimientosRepository.crearSeguimiento(
        seguimiento: seguimiento,
        sesion: sesion,
      );

      return true;
    } catch (_) {
      mensajeError = 'No se pudo guardar el seguimiento';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
