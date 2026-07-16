import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../repositories/usuarios_repository.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class InicioViewModel extends ChangeNotifier {
  InicioViewModel({
    FirebaseFirestore? firestore,
    UsuariosRepository? usuariosRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _usuariosRepository = usuariosRepository ?? UsuariosRepository();

  final FirebaseFirestore _firestore;
  final UsuariosRepository _usuariosRepository;

  String rol = '';
  bool accesoAdministrador = false;

  bool get tieneAccesoAdministrador {
    return esRolAdministrador(rol) || accesoAdministrador;
  }

  String? get usuarioActualId => _usuariosRepository.usuarioActualId;
  String? get usuarioActualCorreo => _usuariosRepository.usuarioActualCorreo;

  bool esRolAdministrador(String? valor) {
    final rolNormalizado = valor?.toString().trim().toLowerCase() ?? '';
    return rolNormalizado == 'administrador' || rolNormalizado == 'admin';
  }

  bool valorBooleano(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is String) {
      final normalizado = valor.trim().toLowerCase();
      return normalizado == 'true' ||
          normalizado == 'si' ||
          normalizado == 'sí' ||
          normalizado == '1';
    }
    if (valor is num) return valor == 1;
    return false;
  }

  bool tieneAccesoAdministradorDesdeData(Map<String, dynamic>? data) {
    if (data == null) return tieneAccesoAdministrador;

    return esRolAdministrador(data['rol']?.toString()) ||
        valorBooleano(data['accesoAdministrador']) ||
        valorBooleano(data['esAdministrador']) ||
        valorBooleano(data['admin']);
  }

  Future<void> cargarRol() async {
    try {
      final uid = usuarioActualId;

      if (uid == null) {
        rol = 'vendedor';
        notifyListeners();
        return;
      }

      final doc = await _firestore.collection('usuarios').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() ?? {};
        final rolUsuario =
            data['rol']?.toString().trim().toLowerCase() ?? 'vendedor';
        final tieneAccesoExtra = tieneAccesoAdministradorDesdeData(data);

        rol = rolUsuario;
        accesoAdministrador = tieneAccesoExtra;
        notifyListeners();

        final sesion = SesionUsuario(
          uid: uid,
          nombre: data['nombre']?.toString() ?? 'Vendedor',
          correo: data['correo']?.toString() ?? usuarioActualCorreo ?? '',
          rol: rolUsuario,
          accesoAdministrador: tieneAccesoExtra,
        );

        try {
          await NotificacionesServicio.generarRecordatoriosPendientes(sesion);
        } catch (_) {
          // Los accesos no deben depender de la generacion de recordatorios.
        }
      } else {
        rol = 'vendedor';
        notifyListeners();
      }
    } catch (_) {
      rol = 'vendedor';
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() {
    return _usuariosRepository.cerrarSesion();
  }

  Stream<Map<String, dynamic>?> usuarioActualDataStream() {
    final uid = usuarioActualId;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('usuarios')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  bool puedeVerDocumento(Map<String, dynamic> data) {
    if (tieneAccesoAdministrador) return true;

    final uid = usuarioActualId;
    if (uid == null) return false;

    return data['vendedorId'] == uid;
  }

  Stream<int> contarDocumentos(String coleccion) {
    return _firestore.collection(coleccion).snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return puedeVerDocumento(data);
      }).length;
    });
  }

  Stream<int> contarClientesPotenciales() {
    return _firestore.collection('clientes').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (!puedeVerDocumento(data)) return false;

        final estado = data['estadoCliente']?.toString() ?? 'Cliente potencial';

        return estado != 'Cliente';
      }).length;
    });
  }

  Stream<int> contarClientesConvertidos() {
    return _firestore.collection('clientes').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (!puedeVerDocumento(data)) return false;

        final estado = data['estadoCliente']?.toString() ?? 'Cliente potencial';

        return estado == 'Cliente';
      }).length;
    });
  }

  Stream<int> contarVentasCerradas() {
    return _firestore
        .collection('ventas')
        .where('estado', isEqualTo: 'Cerrada')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            return puedeVerDocumento(data);
          }).length;
        });
  }

  Stream<int> ventasEsteMes() {
    final ahora = DateTime.now();

    return _firestore.collection('ventas').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (!puedeVerDocumento(data)) return false;

        if (data['fechaRegistro'] == null) return false;

        final fecha = (data['fechaRegistro'] as Timestamp).toDate();

        return fecha.month == ahora.month && fecha.year == ahora.year;
      }).length;
    });
  }

  Stream<int> clientesNuevosEsteMes() {
    final ahora = DateTime.now();

    return _firestore.collection('clientes').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        if (!puedeVerDocumento(data)) return false;

        if (data['fechaRegistro'] == null) return false;

        final fecha = (data['fechaRegistro'] as Timestamp).toDate();

        return fecha.month == ahora.month && fecha.year == ahora.year;
      }).length;
    });
  }

  Stream<double> ingresosEsteMes() {
    final ahora = DateTime.now();

    return _firestore.collection('ventas').snapshots().map((snapshot) {
      double total = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!puedeVerDocumento(data)) continue;

        if (data['fechaRegistro'] == null) continue;

        final fecha = (data['fechaRegistro'] as Timestamp).toDate();

        if (fecha.month == ahora.month && fecha.year == ahora.year) {
          total += double.tryParse(data['monto'].toString()) ?? 0;
        }
      }

      return total;
    });
  }

  Stream<Map<String, dynamic>?> clienteDestacado() {
    return _firestore.collection('ventas').snapshots().map((snapshot) {
      final Map<String, double> totales = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (!puedeVerDocumento(data)) continue;

        final cliente = (data['cliente'] ?? 'Sin cliente').toString();
        final monto = double.tryParse(data['monto'].toString()) ?? 0;

        if (cliente.trim().isEmpty) continue;

        totales[cliente] = (totales[cliente] ?? 0) + monto;
      }

      if (totales.isEmpty) return null;

      final clienteTop = totales.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );

      return {'cliente': clienteTop.key, 'total': clienteTop.value};
    });
  }

  Stream<int> contarSeguimientosPendientes() {
    return _firestore
        .collection('seguimientos')
        .where('estado', isEqualTo: 'Pendiente')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            return puedeVerDocumento(data);
          }).length;
        });
  }

  Stream<int> contarNotificacionesPendientes() {
    final uid = usuarioActualId ?? '';

    final sesion = SesionUsuario(
      uid: uid,
      nombre: '',
      correo: '',
      rol: rol,
      accesoAdministrador: accesoAdministrador,
    );

    return _firestore.collection('notificaciones').snapshots().map((snapshot) {
      return snapshot.docs.where((doc) {
        final data = doc.data();
        return NotificacionesServicio.esVisiblePara(data, sesion) &&
            !NotificacionesServicio.estaLeidaPor(data, uid);
      }).length;
    });
  }

  String formatoLempiras(num valor) {
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 0,
    );

    return formato.format(valor);
  }

  String nombreUsuario(User? usuario) {
    final nombre = usuario?.displayName;
    if (nombre != null && nombre.trim().isNotEmpty) return nombre;

    final correo = usuario?.email;
    if (correo != null && correo.contains('@')) {
      return correo.split('@').first;
    }

    return 'vendedor';
  }
}
