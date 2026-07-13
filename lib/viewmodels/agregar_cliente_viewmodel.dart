import 'package:flutter/foundation.dart';

import '../models/cliente_model.dart';
import '../repositories/clientes_repository.dart';
import '../servicios/sesion_usuario.dart';

class AgregarClienteViewModel extends ChangeNotifier {
  final ClientesRepository _clientesRepository;

  AgregarClienteViewModel({ClientesRepository? clientesRepository})
    : _clientesRepository = clientesRepository ?? ClientesRepository();

  List<Map<String, String>> serviciosSeleccionados = [];
  bool cargando = false;
  String? mensajeError;

  void actualizarServicios(List<Map<String, String>> servicios) {
    serviciosSeleccionados = servicios;
    notifyListeners();
  }

  Future<bool> guardarCliente({
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

    if (serviciosSeleccionados.isEmpty) {
      mensajeError = 'Selecciona al menos un servicio de interés';
      notifyListeners();
      return false;
    }

    cargando = true;
    notifyListeners();

    try {
      final sesion = await obtenerSesionUsuario();
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
        estadoCliente: 'Cliente potencial',
      );

      await _clientesRepository.crearClientePotencial(
        cliente: cliente,
        sesion: sesion,
      );

      return true;
    } catch (_) {
      mensajeError = 'No se pudo guardar el cliente potencial';
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }
}
