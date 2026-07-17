import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/seguimiento_model.dart';
import '../repositories/seguimientos_repository.dart';
import '../servicios/sesion_usuario.dart';

class SeguimientosSesionViewData {
  const SeguimientosSesionViewData({
    required this.uid,
    required this.esAdministrador,
  });

  factory SeguimientosSesionViewData.fromSesion(SesionUsuario sesion) {
    return SeguimientosSesionViewData(
      uid: sesion.uid,
      esAdministrador: sesion.esAdministrador,
    );
  }

  final String uid;
  final bool esAdministrador;
}

class SeguimientosViewModel extends ChangeNotifier {
  final SeguimientosRepository _seguimientosRepository;

  SeguimientosViewModel({SeguimientosRepository? seguimientosRepository})
    : _seguimientosRepository =
          seguimientosRepository ?? SeguimientosRepository() {
    sesionFuture = obtenerSesionUsuario().then(
      SeguimientosSesionViewData.fromSesion,
    );
  }

  String busqueda = '';
  String filtroEstado = 'Todos';
  late final Future<SeguimientosSesionViewData> sesionFuture;

  Stream<List<SeguimientoModel>> get seguimientosStream =>
      _seguimientosRepository.escucharSeguimientos();

  void actualizarBusqueda(String valor) {
    busqueda = valor.trim().toLowerCase();
    notifyListeners();
  }

  void limpiarBusqueda() {
    busqueda = '';
    notifyListeners();
  }

  void cambiarFiltroEstado(String estado) {
    filtroEstado = estado;
    notifyListeners();
  }

  List<SeguimientoModel> filtrarSeguimientos(
    List<SeguimientoModel> seguimientos,
    SeguimientosSesionViewData sesion,
  ) {
    return seguimientos.where((seguimiento) {
      if (!sesion.esAdministrador && seguimiento.vendedorId != sesion.uid) {
        return false;
      }

      final texto = [
        seguimiento.cliente,
        seguimiento.comentario,
        seguimiento.tipo,
        seguimiento.estado,
      ].join(' ').toLowerCase();

      final coincideBusqueda = texto.contains(busqueda);
      final coincideEstado =
          filtroEstado == 'Todos' || seguimiento.estado == filtroEstado;

      return coincideBusqueda && coincideEstado;
    }).toList();
  }

  dynamic fechaActividad(SeguimientoModel seguimiento) {
    if (seguimiento.estado == 'Realizado') {
      return seguimiento.fechaRealizacion;
    }

    if (seguimiento.fechaProxima != null) {
      return Timestamp.fromDate(seguimiento.fechaProxima!);
    }

    return seguimiento.fechaRegistro;
  }

  String fechaCorta(dynamic valor) {
    if (valor is DateTime) return DateFormat('dd/MM/yyyy HH:mm').format(valor);
    if (valor is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy HH:mm').format(valor.toDate());
  }
}
