import 'package:flutter/foundation.dart';

import '../models/servicio_model.dart';
import '../repositories/servicios_repository.dart';

class SeleccionarServiciosViewModel extends ChangeNotifier {
  SeleccionarServiciosViewModel({
    required List<Map<String, String>> seleccionInicial,
    ServiciosRepository? repository,
  }) : _repository = repository ?? ServiciosRepository() {
    seleccionados = {
      for (final servicio in seleccionInicial)
        if ((servicio['id'] ?? '').isNotEmpty) servicio['id']!: servicio,
    };
  }

  final ServiciosRepository _repository;

  late Map<String, Map<String, String>> seleccionados;
  String busqueda = '';

  Stream<List<ServicioModel>> get serviciosStream {
    return _repository.escucharServicios();
  }

  void cambiarBusqueda(String valor) {
    busqueda = valor;
    notifyListeners();
  }

  List<ServicioModel> filtrarServicios(List<ServicioModel> servicios) {
    final consulta = busqueda.trim().toLowerCase();
    if (consulta.isEmpty) return servicios;

    return servicios.where((servicio) {
      final texto = '${servicio.nombre} ${servicio.descripcion}'.toLowerCase();
      return texto.contains(consulta);
    }).toList();
  }

  bool estaSeleccionado(String id) {
    return seleccionados.containsKey(id);
  }

  void alternarServicio(ServicioModel servicio) {
    final id = servicio.id;
    if (seleccionados.containsKey(id)) {
      seleccionados.remove(id);
    } else {
      seleccionados[id] = servicio.toSelectionMap();
    }
    notifyListeners();
  }

  List<Map<String, String>> obtenerSeleccion() {
    return seleccionados.values.toList();
  }
}
