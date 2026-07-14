import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';
import '../repositories/clientes_repository.dart';

class EditarClienteViewModel extends ChangeNotifier {
  final ClientesRepository _clientesRepository;
  final String clienteId;
  final ClienteModel clienteOriginal;

  EditarClienteViewModel({
    required this.clienteId,
    required Map<String, dynamic> cliente,
    ClientesRepository? clientesRepository,
  }) : _clientesRepository = clientesRepository ?? ClientesRepository(),
       clienteOriginal = ClienteModel.fromMap(cliente, id: clienteId) {
    serviciosSeleccionados = [
      for (
        var index = 0;
        index < clienteOriginal.serviciosInteresIds.length;
        index++
      )
        {
          'id': clienteOriginal.serviciosInteresIds[index],
          'nombre': index < clienteOriginal.serviciosInteresNombres.length
              ? clienteOriginal.serviciosInteresNombres[index]
              : 'Servicio',
          'descripcion': '',
          'logoBase64': '',
        },
    ];
  }

  late List<Map<String, String>> serviciosSeleccionados;
  bool cargando = false;
  bool eliminando = false;
  String? mensajeError;

  void actualizarServicios(List<Map<String, String>> servicios) {
    serviciosSeleccionados = servicios;
    notifyListeners();
  }

  Future<bool> actualizarCliente({
    required String nombre,
    required String telefono,
    required String correo,
    required String empresa,
    required String direccion,
  }) async {
    mensajeError = null;

    if (nombre.trim().isEmpty) {
      mensajeError = 'El nombre es obligatorio';
      notifyListeners();
      return false;
    }

    cargando = true;
    notifyListeners();

    try {
      final cliente = ClienteModel(
        nombre: nombre.trim(),
        telefono: telefono.trim(),
        correo: correo.trim(),
        empresa: empresa.trim(),
        direccion: direccion.trim(),
        serviciosInteresIds: serviciosSeleccionados
            .map((servicio) => servicio['id'] ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
        serviciosInteresNombres: serviciosSeleccionados
            .map((servicio) => servicio['nombre'] ?? '')
            .where((nombre) => nombre.isNotEmpty)
            .toList(),
        estadoCliente: clienteOriginal.estadoCliente,
      );

      await _clientesRepository.actualizarCliente(
        clienteId: clienteId,
        cliente: cliente,
      );

      return true;
    } catch (_) {
      mensajeError = 'No se pudo actualizar el cliente';
      return false;
    } finally {
      cargando = false;
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
}
