import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/servicio_model.dart';
import '../repositories/servicios_repository.dart';

class ServiciosViewModel extends ChangeNotifier {
  ServiciosViewModel({ServiciosRepository? repository})
    : _repository = repository ?? ServiciosRepository();

  final ServiciosRepository _repository;
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
      final texto = [
        servicio.nombre,
        servicio.descripcion,
        servicio.precio,
      ].join(' ').toLowerCase();

      return texto.contains(consulta);
    }).toList();
  }

  String formatoLempiras(String valor) {
    final numero = double.tryParse(valor) ?? 0;
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 0,
    );

    return formato.format(numero);
  }
}
