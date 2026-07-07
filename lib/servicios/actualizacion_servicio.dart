import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class ActualizacionInfo {
  final String versionActual;
  final int buildActual;
  final bool obligatoria;
  final String mensaje;
  final String urlActualizacion;
  final String tipo;
  final String versionInstalada;
  final int buildInstalado;

  const ActualizacionInfo({
    required this.versionActual,
    required this.buildActual,
    required this.obligatoria,
    required this.mensaje,
    required this.urlActualizacion,
    this.tipo = 'estable',
    required this.versionInstalada,
    required this.buildInstalado,
  });

  bool get hayNuevaVersion => buildActual > buildInstalado;
}

class ActualizacionServicio {
  static final DocumentReference<Map<String, dynamic>> _documento =
      FirebaseFirestore.instance.collection('configuracion').doc('app_version');

  static Future<ActualizacionInfo?> verificarActualizacion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final buildInstalado = int.tryParse(packageInfo.buildNumber) ?? 0;

    final snapshot = await _documento.get();
    final data = snapshot.data();

    if (data == null) return null;

    final buildActual = _enteroDesdeData(data['buildActual']);
    final versionActual =
        data['versionActual']?.toString().trim() ?? packageInfo.version;
    final obligatoria = _booleanoDesdeData(data['actualizacionObligatoria']);
    final mensaje =
        data['mensaje']?.toString().trim() ??
        'Hay una nueva versión disponible de SAPINF CRM.';
    final urlActualizacion = data['urlActualizacion']?.toString().trim() ?? '';

    final info = ActualizacionInfo(
      versionActual: versionActual,
      buildActual: buildActual,
      obligatoria: obligatoria,
      mensaje: mensaje,
      urlActualizacion: urlActualizacion,
      tipo: data['tipo']?.toString().trim() ?? 'estable',
      versionInstalada: packageInfo.version,
      buildInstalado: buildInstalado,
    );

    return info.hayNuevaVersion ? info : null;
  }

  static Future<ActualizacionInfo?> obtenerVersionPrincipal() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final buildInstalado = int.tryParse(packageInfo.buildNumber) ?? 0;
    final snapshot = await _documento.get();
    final data = snapshot.data();

    if (data == null) return null;

    return ActualizacionInfo(
      versionActual:
          data['versionActual']?.toString().trim() ?? packageInfo.version,
      buildActual: _enteroDesdeData(data['buildActual']),
      obligatoria: _booleanoDesdeData(data['actualizacionObligatoria']),
      mensaje:
          data['mensaje']?.toString().trim() ??
          'Hay una nueva version disponible de SAPINF CRM.',
      urlActualizacion: data['urlActualizacion']?.toString().trim() ?? '',
      tipo: data['tipo']?.toString().trim() ?? 'estable',
      versionInstalada: packageInfo.version,
      buildInstalado: buildInstalado,
    );
  }

  static Stream<List<ActualizacionInfo>> versionesDisponibles() async* {
    final packageInfo = await PackageInfo.fromPlatform();
    final buildInstalado = int.tryParse(packageInfo.buildNumber) ?? 0;

    yield* FirebaseFirestore.instance
        .collection('versiones_app')
        .orderBy('buildActual', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return ActualizacionInfo(
              versionActual:
                  data['versionActual']?.toString().trim() ??
                  packageInfo.version,
              buildActual: _enteroDesdeData(data['buildActual']),
              obligatoria: _booleanoDesdeData(data['actualizacionObligatoria']),
              mensaje:
                  data['mensaje']?.toString().trim() ??
                  'Version disponible de SAPINF CRM.',
              urlActualizacion:
                  data['urlActualizacion']?.toString().trim() ?? '',
              tipo: data['tipo']?.toString().trim() ?? 'estable',
              versionInstalada: packageInfo.version,
              buildInstalado: buildInstalado,
            );
          }).toList();
        });
  }

  static Future<String> descargarActualizacion({
    required String url,
    required String nombreArchivo,
    required void Function(double progreso) onProgreso,
  }) async {
    if (url.trim().isEmpty) {
      throw Exception('No hay enlace de actualizacion configurado.');
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      throw Exception('El enlace de actualizacion no es valido.');
    }

    final directorio = await getTemporaryDirectory();
    final nombreSeguro = nombreArchivo.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );
    final archivo = File('${directorio.path}/$nombreSeguro');
    final cliente = HttpClient();

    try {
      final request = await cliente.getUrl(uri);
      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('No se pudo descargar la actualizacion.');
      }

      final total = response.contentLength;
      var recibido = 0;

      final sink = archivo.openWrite();

      await for (final chunk in response) {
        recibido += chunk.length;
        sink.add(chunk);

        if (total > 0) {
          onProgreso(recibido / total);
        }
      }

      await sink.close();
      onProgreso(1);

      return archivo.path;
    } finally {
      cliente.close(force: true);
    }
  }

  static Future<bool> instalarActualizacion(String rutaArchivo) async {
    if (rutaArchivo.trim().isEmpty) return false;

    final resultado = await OpenFile.open(rutaArchivo);
    return resultado.type == ResultType.done;
  }

  static int _enteroDesdeData(dynamic valor) {
    if (valor is int) return valor;
    if (valor is num) return valor.toInt();
    if (valor is String) return int.tryParse(valor.trim()) ?? 0;
    return 0;
  }

  static bool _booleanoDesdeData(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is num) return valor == 1;
    if (valor is String) {
      final normalizado = valor.trim().toLowerCase();
      return normalizado == 'true' ||
          normalizado == 'si' ||
          normalizado == 'sí' ||
          normalizado == '1';
    }
    return false;
  }
}
