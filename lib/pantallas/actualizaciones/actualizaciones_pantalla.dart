import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/actualizacion_servicio.dart';

class ActualizacionesPantalla extends StatefulWidget {
  final ActualizacionInfo? actualizacionInicial;

  const ActualizacionesPantalla({super.key, this.actualizacionInicial});

  @override
  State<ActualizacionesPantalla> createState() =>
      _ActualizacionesPantallaState();
}

class _ActualizacionesPantallaState extends State<ActualizacionesPantalla> {
  ActualizacionInfo? versionPrincipal;
  bool cargandoVersion = true;
  bool descargando = false;
  double progreso = 0;
  String? rutaDescargada;
  int? buildEnDescarga;

  @override
  void initState() {
    super.initState();
    _cargarVersionPrincipal();
  }

  Future<void> _cargarVersionPrincipal() async {
    try {
      final version =
          widget.actualizacionInicial ??
          await ActualizacionServicio.obtenerVersionPrincipal();

      if (!mounted) return;

      setState(() {
        versionPrincipal = version;
        cargandoVersion = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        cargandoVersion = false;
      });
    }
  }

  Future<void> _descargarEInstalar(ActualizacionInfo version) async {
    if (!Platform.isAndroid) {
      _mostrarMensaje(
        'La instalacion interna de APK esta disponible para Android.',
      );
      return;
    }

    setState(() {
      descargando = true;
      progreso = 0;
      rutaDescargada = null;
      buildEnDescarga = version.buildActual;
    });

    try {
      final ruta = await ActualizacionServicio.descargarActualizacion(
        url: version.urlActualizacion,
        nombreArchivo:
            'sapinf_crm_${version.versionActual}_${version.buildActual}.apk',
        onProgreso: (valor) {
          if (!mounted) return;
          setState(() {
            progreso = valor.clamp(0, 1);
          });
        },
      );

      if (!mounted) return;

      setState(() {
        rutaDescargada = ruta;
        descargando = false;
      });

      await _instalar(ruta);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        descargando = false;
      });

      _mostrarMensaje(
        'No se pudo descargar la actualizacion. Revisa el enlace configurado.',
      );
    }
  }

  Future<void> _instalar(String ruta) async {
    final abierto = await ActualizacionServicio.instalarActualizacion(ruta);

    if (!mounted) return;

    if (!abierto) {
      _mostrarMensaje(
        'No se pudo abrir el instalador. Verifica permisos de instalacion.',
      );
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Color _colorTipo(String tipo) {
    final normalizado = tipo.toLowerCase().trim();
    if (normalizado.contains('rollback') ||
        normalizado.contains('recuperacion') ||
        normalizado.contains('anterior')) {
      return Colors.orange;
    }
    if (normalizado.contains('beta')) return Colors.purple;
    return const Color(0xFF1565C0);
  }

  String _textoTipo(String tipo) {
    final normalizado = tipo.toLowerCase().trim();
    if (normalizado.contains('rollback') ||
        normalizado.contains('recuperacion') ||
        normalizado.contains('anterior')) {
      return 'Version de recuperacion';
    }
    if (normalizado.contains('beta')) return 'Version beta';
    return 'Version estable';
  }

  Widget _encabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.system_update_alt_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Centro de actualizaciones',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Instala nuevas versiones o recupera una version estable.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaVersion(ActualizacionInfo version, {bool principal = false}) {
    final color = _colorTipo(version.tipo);
    final descargandoEsta =
        descargando && buildEnDescarga == version.buildActual;
    final instalada = version.buildActual == version.buildInstalado;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: principal
              ? color.withValues(alpha: 0.35)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  principal
                      ? Icons.new_releases_rounded
                      : Icons.restore_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAPINF CRM ${version.versionActual}',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_textoTipo(version.tipo)} - build ${version.buildActual}',
                      style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (instalada)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Instalada',
                    style: GoogleFonts.poppins(
                      color: Colors.green.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            version.mensaje,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          if (descargandoEsta) ...[
            LinearProgressIndicator(
              value: progreso <= 0 ? null : progreso,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
            ),
            const SizedBox(height: 8),
            Text(
              'Descargando ${(progreso * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: instalada
                        ? null
                        : () => _descargarEInstalar(version),
                    icon: const Icon(Icons.download_rounded, size: 19),
                    label: Text(
                      version.buildActual < version.buildInstalado
                          ? 'Recuperar version'
                          : 'Descargar e instalar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                if (rutaDescargada != null &&
                    buildEnDescarga == version.buildActual) ...[
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: () => _instalar(rutaDescargada!),
                    icon: const Icon(Icons.install_mobile_rounded),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _instruccionRollback() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Text(
        'Nota tecnica: Android no permite instalar un APK con build menor sobre uno mayor. Para volver a una version anterior, se debe subir el codigo estable anterior con un build nuevo mas alto.',
        style: GoogleFonts.poppins(
          color: Colors.orange.shade900,
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _versionesRecuperacion() {
    return StreamBuilder<List<ActualizacionInfo>>(
      stream: ActualizacionServicio.versionesDisponibles(),
      builder: (context, snapshot) {
        final versiones = snapshot.data ?? const <ActualizacionInfo>[];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (versiones.isEmpty) {
          return Text(
            'Aun no hay versiones de recuperacion configuradas en Firestore.',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          );
        }

        return Column(
          children: versiones
              .map((version) => _tarjetaVersion(version))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Actualizaciones',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarVersionPrincipal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            _encabezado(),
            const SizedBox(height: 18),
            Text(
              'Version publicada',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),
            if (cargandoVersion)
              const Center(child: CircularProgressIndicator())
            else if (versionPrincipal == null)
              Text(
                'No hay una version principal configurada.',
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              )
            else
              _tarjetaVersion(versionPrincipal!, principal: true),
            const SizedBox(height: 8),
            _instruccionRollback(),
            const SizedBox(height: 20),
            Text(
              'Versiones de recuperacion',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),
            _versionesRecuperacion(),
          ],
        ),
      ),
    );
  }
}
