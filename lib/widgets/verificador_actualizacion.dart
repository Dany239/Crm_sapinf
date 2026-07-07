import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../pantallas/actualizaciones/actualizaciones_pantalla.dart';
import '../servicios/actualizacion_servicio.dart';

class VerificadorActualizacion extends StatefulWidget {
  final Widget child;

  const VerificadorActualizacion({super.key, required this.child});

  @override
  State<VerificadorActualizacion> createState() =>
      _VerificadorActualizacionState();
}

class _VerificadorActualizacionState extends State<VerificadorActualizacion> {
  bool _verificacionRealizada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarActualizacion();
    });
  }

  Future<void> _verificarActualizacion() async {
    if (_verificacionRealizada) return;
    _verificacionRealizada = true;

    try {
      final actualizacion =
          await ActualizacionServicio.verificarActualizacion();

      if (!mounted || actualizacion == null) return;

      await _mostrarDialogoActualizacion(actualizacion);
    } catch (_) {
      // Si la verificacion falla, la app debe seguir funcionando normalmente.
    }
  }

  Future<void> _mostrarDialogoActualizacion(ActualizacionInfo actualizacion) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !actualizacion.obligatoria,
      builder: (context) {
        return PopScope(
          canPop: !actualizacion.obligatoria,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.system_update_alt_rounded,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    actualizacion.obligatoria
                        ? 'Actualizacion requerida'
                        : 'Nueva actualizacion',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version ${actualizacion.versionActual} disponible',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1565C0),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  actualizacion.mensaje,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF374151),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Instalada: ${actualizacion.versionInstalada}+${actualizacion.buildInstalado}',
                  style: GoogleFonts.poppins(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              if (!actualizacion.obligatoria)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Mas tarde',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActualizacionesPantalla(
                        actualizacionInicial: actualizacion,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.system_update_alt_rounded, size: 18),
                label: Text(
                  'Actualizar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
