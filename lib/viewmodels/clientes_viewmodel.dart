import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/cliente_model.dart';
import '../repositories/clientes_repository.dart';
import '../servicios/sesion_usuario.dart';

class ClientesViewModel extends ChangeNotifier {
  final ClientesRepository _clientesRepository;

  ClientesViewModel({
    ClientesRepository? clientesRepository,
    required bool mostrarClientesInicial,
  }) : _clientesRepository = clientesRepository ?? ClientesRepository(),
       mostrarClientes = mostrarClientesInicial;

  bool mostrarClientes;
  String textoBusqueda = '';

  Stream<List<ClienteModel>> get clientesStream =>
      _clientesRepository.escucharClientes();

  void cambiarFiltro(bool mostrarClientesNuevo) {
    mostrarClientes = mostrarClientesNuevo;
    notifyListeners();
  }

  void actualizarBusqueda(String valor) {
    textoBusqueda = valor.trim().toLowerCase();
    notifyListeners();
  }

  void limpiarBusqueda() {
    textoBusqueda = '';
    notifyListeners();
  }

  List<ClienteModel> filtrarClientes(
    List<ClienteModel> clientes,
    SesionUsuario sesion,
  ) {
    return clientes.where((cliente) {
      if (!sesion.esAdministrador && cliente.vendedorId != sesion.uid) {
        return false;
      }

      final esCliente = cliente.estadoCliente == 'Cliente';

      if (mostrarClientes != esCliente) {
        return false;
      }

      if (textoBusqueda.isEmpty) {
        return true;
      }

      return cliente.nombre.toLowerCase().contains(textoBusqueda) ||
          cliente.empresa.toLowerCase().contains(textoBusqueda) ||
          cliente.telefono.toLowerCase().contains(textoBusqueda) ||
          cliente.correo.toLowerCase().contains(textoBusqueda) ||
          cliente.estadoCliente.toLowerCase().contains(textoBusqueda);
    }).toList();
  }

  String fechaCorta(dynamic valor) {
    if (valor is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(valor.toDate());
  }
}
