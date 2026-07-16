import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/notificacion_model.dart';
import '../../viewmodels/notificaciones_viewmodel.dart';

class NotificacionesPantalla extends StatefulWidget {
  const NotificacionesPantalla({super.key});

  @override
  State<NotificacionesPantalla> createState() => _NotificacionesPantallaState();
}

class _NotificacionesPantallaState extends State<NotificacionesPantalla> {
  final NotificacionesViewModel viewModel = NotificacionesViewModel();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  IconData obtenerIcono(String icono) {
    switch (icono) {
      case 'attach_money':
        return Icons.attach_money_rounded;
      case 'person_add':
        return Icons.person_add_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'notifications':
        return Icons.mail_outline_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  Color obtenerColor(String color) {
    switch (color) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final anchoPanel = ancho < 420 ? ancho * 0.88 : 370.0;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: anchoPanel,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: FutureBuilder<NotificacionesSesionViewData>(
              future: viewModel.sesionFuture,
              builder: (context, sesionSnapshot) {
                if (!sesionSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                return _contenido(sesionSnapshot.data!);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _contenido(NotificacionesSesionViewData sesion) {
    return StreamBuilder<List<NotificacionModel>>(
      stream: viewModel.notificacionesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notificaciones = viewModel.filtrarVisibles(
          snapshot.data ?? [],
          sesion,
        );
        final pendientes = viewModel.contarPendientes(
          notificaciones,
          sesion.uid,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 14, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notificaciones',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  if (pendientes > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        pendientes > 9 ? '9+' : '$pendientes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 14, 10),
              child: Row(
                children: [
                  Text(
                    sesion.subtitulo,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (pendientes > 0)
                    TextButton(
                      onPressed: () => viewModel.marcarTodasComoLeidas(
                        notificaciones,
                        sesion.uid,
                      ),
                      child: const Text('Marcar le\u00eddas'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: notificaciones.isEmpty
                  ? _estadoVacio()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 14, 24),
                      itemCount: notificaciones.length,
                      itemBuilder: (context, index) {
                        return _tarjeta(notificaciones[index], sesion);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _tarjeta(
    NotificacionModel notificacion,
    NotificacionesSesionViewData sesion,
  ) {
    final leida = notificacion.estaLeidaPor(sesion.uid);
    final color = obtenerColor(notificacion.color);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => viewModel.marcarLeida(notificacion, sesion.uid),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: leida ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: leida
                ? const Color(0xFFE8ECF2)
                : color.withValues(alpha: 0.28),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                obtenerIcono(notificacion.icono),
                color: color,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notificacion.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: leida
                                ? FontWeight.w600
                                : FontWeight.w700,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (!leida)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notificacion.descripcion,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      height: 1.4,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    viewModel.tiempoRelativo(notificacion.fecha),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1565C0),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Sin notificaciones',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
