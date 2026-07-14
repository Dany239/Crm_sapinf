import 'package:flutter/foundation.dart';

import '../models/seguimiento_model.dart';
import '../repositories/seguimientos_repository.dart';
import '../servicios/sesion_usuario.dart';

class AgendaViewModel extends ChangeNotifier {
  AgendaViewModel({SeguimientosRepository? seguimientosRepository})
    : _seguimientosRepository =
          seguimientosRepository ?? SeguimientosRepository();

  final SeguimientosRepository _seguimientosRepository;

  DateTime fechaSeleccionada = DateTime.now();

  Stream<List<SeguimientoModel>> get seguimientosStream {
    return _seguimientosRepository.escucharSeguimientos();
  }

  DateTime inicioSemana(DateTime fecha) {
    return DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
    ).subtract(Duration(days: fecha.weekday - 1));
  }

  List<DateTime> diasDeSemana() {
    final inicio = inicioSemana(fechaSeleccionada);
    return List.generate(7, (index) => inicio.add(Duration(days: index)));
  }

  bool mismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void cambiarMes(int cantidad) {
    fechaSeleccionada = DateTime(
      fechaSeleccionada.year,
      fechaSeleccionada.month + cantidad,
      fechaSeleccionada.day,
    );
    notifyListeners();
  }

  void seleccionarFecha(DateTime fecha) {
    fechaSeleccionada = fecha;
    notifyListeners();
  }

  DateTime? fechaSeguimiento(SeguimientoModel seguimiento) {
    return seguimiento.fechaProxima ??
        SeguimientoModel.fechaDesdeDato(seguimiento.fechaRegistro);
  }

  String horaSeguimiento(SeguimientoModel seguimiento) {
    final fecha = fechaSeguimiento(seguimiento);

    if (fecha == null) {
      return '--:--';
    }

    final hora = fecha.hour == 0
        ? 12
        : fecha.hour > 12
        ? fecha.hour - 12
        : fecha.hour;
    final minutos = fecha.minute.toString().padLeft(2, '0');
    final periodo = fecha.hour >= 12 ? 'PM' : 'AM';

    return '${hora.toString().padLeft(2, '0')}:$minutos $periodo';
  }

  List<SeguimientoModel> filtrarPorFecha(
    List<SeguimientoModel> seguimientos,
    SesionUsuario sesion,
  ) {
    final filtrados = seguimientos.where((seguimiento) {
      if (!sesion.esAdministrador && seguimiento.vendedorId != sesion.uid) {
        return false;
      }

      final fecha = fechaSeguimiento(seguimiento);
      if (fecha == null) return false;

      return mismoDia(fecha, fechaSeleccionada);
    }).toList();

    filtrados.sort((a, b) {
      final fechaA = fechaSeguimiento(a) ?? DateTime(1900);
      final fechaB = fechaSeguimiento(b) ?? DateTime(1900);
      return fechaA.compareTo(fechaB);
    });

    return filtrados;
  }
}
