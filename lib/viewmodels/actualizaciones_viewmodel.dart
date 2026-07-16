import 'dart:io';

import 'package:flutter/foundation.dart';

import '../servicios/actualizacion_servicio.dart';

class ActualizacionesViewModel extends ChangeNotifier {
  ActualizacionesViewModel({this.actualizacionInicial});

  final ActualizacionInfo? actualizacionInicial;

  ActualizacionInfo? versionPrincipal;
  bool cargandoVersion = true;
  bool descargando = false;
  double progreso = 0;
  String? rutaDescargada;
  int? buildEnDescarga;
  String? mensajeError;

  Stream<List<ActualizacionInfo>> get versionesDisponibles {
    return ActualizacionServicio.versionesDisponibles();
  }

  Future<void> cargarVersionPrincipal() async {
    cargandoVersion = true;
    mensajeError = null;
    notifyListeners();

    try {
      versionPrincipal =
          actualizacionInicial ??
          await ActualizacionServicio.obtenerVersionPrincipal();
    } catch (_) {
      mensajeError = 'No se pudo cargar la version principal.';
    } finally {
      cargandoVersion = false;
      notifyListeners();
    }
  }

  Future<String?> descargarActualizacion(ActualizacionInfo version) async {
    if (!Platform.isAndroid) {
      return 'La instalacion interna de APK esta disponible para Android.';
    }

    descargando = true;
    progreso = 0;
    rutaDescargada = null;
    buildEnDescarga = version.buildActual;
    mensajeError = null;
    notifyListeners();

    try {
      final ruta = await ActualizacionServicio.descargarActualizacion(
        url: version.urlActualizacion,
        nombreArchivo:
            'sapinf_crm_${version.versionActual}_${version.buildActual}.apk',
        onProgreso: (valor) {
          progreso = valor.clamp(0, 1);
          notifyListeners();
        },
      );

      rutaDescargada = ruta;
      descargando = false;
      notifyListeners();
      return null;
    } catch (_) {
      descargando = false;
      mensajeError =
          'No se pudo descargar la actualizacion. Revisa el enlace configurado.';
      notifyListeners();
      return mensajeError;
    }
  }

  Future<String?> instalar(String ruta) async {
    final abierto = await ActualizacionServicio.instalarActualizacion(ruta);

    if (abierto) return null;

    return 'No se pudo abrir el instalador. Verifica permisos de instalacion.';
  }

  bool estaDescargando(ActualizacionInfo version) {
    return descargando && buildEnDescarga == version.buildActual;
  }

  bool esVersionInstalada(ActualizacionInfo version) {
    return version.buildActual == version.buildInstalado;
  }

  bool puedeReintentarInstalacion(ActualizacionInfo version) {
    return rutaDescargada != null && buildEnDescarga == version.buildActual;
  }
}
