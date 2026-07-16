import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../repositories/usuarios_repository.dart';
import '../servicios/notificaciones_servicio.dart';
import '../servicios/sesion_usuario.dart';

class ResumenVendedorDashboard {
  final String nombre;
  int ventas = 0;
  int ventasCerradas = 0;
  int seguimientosPendientes = 0;
  int prospectos = 0;
  int convertidos = 0;
  double montoVentas = 0;
  double montoCerrado = 0;

  ResumenVendedorDashboard({required this.nombre});
}

class GraficosComercialesData {
  final Map<String, double> ventasQuincena;
  final List<MapEntry<String, double>> vendedoresOrdenados;

  const GraficosComercialesData({
    required this.ventasQuincena,
    required this.vendedoresOrdenados,
  });
}

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

  bool esDelMesActual(dynamic valor) {
    if (valor is! Timestamp) return false;
    final fecha = valor.toDate();
    final ahora = DateTime.now();
    return fecha.year == ahora.year && fecha.month == ahora.month;
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

  Stream<List<ResumenVendedorDashboard>> resumenVendedoresDashboard() {
    return _firestore.collection('ventas').snapshots().asyncMap((
      ventasSnapshot,
    ) async {
      final seguimientosSnapshot = await _firestore
          .collection('seguimientos')
          .get();
      final clientesSnapshot = await _firestore.collection('clientes').get();

      final resumenes = <String, ResumenVendedorDashboard>{};

      ResumenVendedorDashboard resumenDe(Map<String, dynamic> data) {
        final id = data['vendedorId']?.toString() ?? 'sin-asignar';
        return resumenes.putIfAbsent(
          id,
          () => ResumenVendedorDashboard(
            nombre:
                data['vendedorNombre']?.toString() ?? 'Sin vendedor asignado',
          ),
        );
      }

      for (final doc in ventasSnapshot.docs) {
        final data = doc.data();
        if (!esDelMesActual(data['fechaRegistro'])) continue;
        final resumen = resumenDe(data);
        resumen.ventas++;
        resumen.montoVentas += double.tryParse(data['monto'].toString()) ?? 0;
        if (data['estado'] == 'Cerrada') {
          resumen.ventasCerradas++;
          resumen.montoCerrado +=
              double.tryParse(data['monto'].toString()) ?? 0;
        }
      }

      for (final doc in seguimientosSnapshot.docs) {
        final data = doc.data();
        if (data['estado'] == 'Pendiente') {
          resumenDe(data).seguimientosPendientes++;
        }
      }

      for (final doc in clientesSnapshot.docs) {
        final data = doc.data();
        final resumen = resumenDe(data);
        final esCliente = data['estadoCliente'] == 'Cliente';
        if (!esCliente && esDelMesActual(data['fechaRegistro'])) {
          resumen.prospectos++;
        }
        if (esCliente && esDelMesActual(data['fechaConversionCliente'])) {
          resumen.convertidos++;
        }
      }

      final vendedores = resumenes.values.toList()
        ..sort((a, b) => b.montoCerrado.compareTo(a.montoCerrado));

      return vendedores;
    });
  }

  Stream<GraficosComercialesData> graficosComerciales() {
    return _firestore.collection('ventas').snapshots().map((snapshot) {
      final ahora = DateTime.now();
      final ventasQuincena = <String, double>{'1-15': 0, '16-fin': 0};
      final ventasPorVendedor = <String, double>{};

      for (final doc in snapshot.docs) {
        final venta = doc.data();
        if (!puedeVerDocumento(venta)) continue;

        final monto = double.tryParse(venta['monto'].toString()) ?? 0;
        final fechaRegistro = venta['fechaRegistro'];

        if (fechaRegistro is Timestamp) {
          final fecha = fechaRegistro.toDate();

          if (fecha.month == ahora.month && fecha.year == ahora.year) {
            final quincena = fecha.day <= 15 ? '1-15' : '16-fin';
            ventasQuincena[quincena] = ventasQuincena[quincena]! + monto;
          }
        }

        final vendedor =
            (venta['vendedorNombre'] ??
                    venta['vendedorCorreo'] ??
                    'Sin vendedor')
                .toString()
                .trim();

        if (vendedor.isNotEmpty) {
          ventasPorVendedor[vendedor] =
              (ventasPorVendedor[vendedor] ?? 0) + monto;
        }
      }

      final vendedoresOrdenados = ventasPorVendedor.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return GraficosComercialesData(
        ventasQuincena: ventasQuincena,
        vendedoresOrdenados: vendedoresOrdenados,
      );
    });
  }

  Stream<Map<String, int>> oportunidadesPorEtapa() {
    const etapas = [
      'Prospecto',
      'Contacto inicial',
      'Propuesta',
      'Negociacion',
      'Cierre',
    ];

    return _firestore.collection('clientes').snapshots().map((snapshot) {
      final conteo = {for (final etapa in etapas) etapa: 0};

      for (final doc in snapshot.docs) {
        final cliente = doc.data();
        if (!puedeVerDocumento(cliente)) continue;

        final etapa = etapaOportunidad(cliente);
        conteo[etapa] = (conteo[etapa] ?? 0) + 1;
      }

      return conteo;
    });
  }

  String etapaOportunidad(Map<String, dynamic> cliente) {
    final estado = (cliente['estadoCliente'] ?? '').toString().toLowerCase();
    final etapa = (cliente['etapa'] ?? cliente['etapaVenta'] ?? '')
        .toString()
        .toLowerCase();

    if (estado == 'cliente') return 'Cierre';
    if (etapa.contains('negoci')) return 'Negociacion';
    if (etapa.contains('propuesta')) return 'Propuesta';
    if (etapa.contains('contact')) return 'Contacto inicial';
    return 'Prospecto';
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
