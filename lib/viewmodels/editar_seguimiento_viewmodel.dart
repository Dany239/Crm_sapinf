import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';
import '../models/seguimiento_model.dart';
import '../repositories/clientes_repository.dart';
import '../repositories/seguimientos_repository.dart';
import '../servicios/sesion_usuario.dart';

class EditarSeguimientoViewModel extends ChangeNotifier {
  final SeguimientosRepository _seguimientosRepository;
  final ClientesRepository _clientesRepository;
  final String seguimientoId;
  final SeguimientoModel seguimientoOriginal;

  EditarSeguimientoViewModel({
    required this.seguimientoId,
    required Map<String, dynamic> seguimiento,
    SeguimientosRepository? seguimientosRepository,
    ClientesRepository? clientesRepository,
  }) : _seguimientosRepository =
           seguimientosRepository ?? SeguimientosRepository(),
       _clientesRepository = clientesRepository ?? ClientesRepository(),
       seguimientoOriginal = SeguimientoModel.fromMap(
         seguimiento,
         id: seguimientoId,
       ) {
    clienteIdSeleccionado = seguimientoOriginal.clienteId;
    clienteNombreSeleccionado = seguimientoOriginal.cliente;
    fechaProximaSeleccionada =
        seguimientoOriginal.fechaProxima ??
        fechaDesdeTexto(seguimientoOriginal.proximaGestion);
    tipoSeleccionado = normalizarTipo(seguimientoOriginal.tipo);
    estadoSeleccionado = seguimientoOriginal.estado;
  }

  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  DateTime? fechaProximaSeleccionada;
  String tipoSeleccionado = 'Llamada';
  String estadoSeleccionado = 'Pendiente';
  bool cargando = false;
  bool eliminando = false;
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

  String normalizarTipo(String tipo) {
    if (tipo.toLowerCase().contains('reuni')) return 'Reunión';
    return tipo;
  }

  String textoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  DateTime? fechaDesdeTexto(String texto) {
    final secciones = texto.trim().split(' ');
    final partes = secciones.first.split('/');

    if (partes.length != 3) return null;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);

    if (dia == null || mes == null || anio == null) return null;

    var hora = 0;
    var minuto = 0;
    if (secciones.length > 1) {
      final partesHora = secciones[1].split(':');
      hora = int.tryParse(partesHora.first) ?? 0;
      if (partesHora.length > 1) {
        minuto = int.tryParse(partesHora[1]) ?? 0;
      }
    }

    return DateTime(anio, mes, dia, hora, minuto);
  }

  Future<bool> actualizarSeguimiento({
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
        evidenciaTipo: seguimientoOriginal.evidenciaTipo,
      );

      await _seguimientosRepository.actualizarSeguimiento(
        seguimientoId: seguimientoId,
        seguimiento: seguimiento,
        seguimientoAnterior: seguimientoOriginal,
        sesion: sesion,
      );

      return true;
    } catch (_) {
      mensajeError = 'No se pudo actualizar el seguimiento';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> eliminarSeguimiento() async {
    mensajeError = null;
    eliminando = true;
    notifyListeners();

    try {
      await _seguimientosRepository.eliminarSeguimiento(seguimientoId);
      return true;
    } catch (_) {
      mensajeError = 'No se pudo eliminar el seguimiento';
      return false;
    } finally {
      eliminando = false;
      notifyListeners();
    }
  }
}
