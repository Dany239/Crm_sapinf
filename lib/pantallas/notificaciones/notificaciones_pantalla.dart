import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/notificaciones_servicio.dart';
import '../../servicios/sesion_usuario.dart';

class NotificacionesPantalla extends StatefulWidget {
  const NotificacionesPantalla({super.key});

  @override
  State<NotificacionesPantalla> createState() => _NotificacionesPantallaState();
}

class _NotificacionesPantallaState extends State<NotificacionesPantalla> {
  late final Future<SesionUsuario> sesionFuture;

  @override
  void initState() {
    super.initState();
    sesionFuture = obtenerSesionUsuario();
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

  String tiempoRelativo(Timestamp? fecha) {
    if (fecha == null) return 'Ahora';

    final diferencia = DateTime.now().difference(fecha.toDate());
    if (diferencia.inMinutes < 1) return 'Hace unos segundos';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes} min';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours} h';
    return 'Hace ${diferencia.inDays} d\u00edas';
  }

  Future<void> marcarTodasComoLeidas(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documentos,
    String uid,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    var cambios = 0;

    for (final doc in documentos) {
      if (!NotificacionesServicio.estaLeidaPor(doc.data(), uid)) {
        batch.update(doc.reference, {
          'leidaPor': FieldValue.arrayUnion([uid]),
        });
        cambios++;
      }
    }

    if (cambios > 0) await batch.commit();
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
            child: FutureBuilder<SesionUsuario>(
              future: sesionFuture,
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

  Widget _contenido(SesionUsuario sesion) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('notificaciones')
          .orderBy('fecha', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final notificaciones = snapshot.data!.docs
            .where(
              (doc) => NotificacionesServicio.esVisiblePara(doc.data(), sesion),
            )
            .toList();
        final pendientes = notificaciones
            .where(
              (doc) => !NotificacionesServicio.estaLeidaPor(
                doc.data(),
                sesion.uid,
              ),
            )
            .length;

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
                    sesion.esAdministrador
                        ? 'Actividad comercial'
                        : 'Mis actividades',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (pendientes > 0)
                    TextButton(
                      onPressed: () => marcarTodasComoLeidas(
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
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    SesionUsuario sesion,
  ) {
    final data = doc.data();
    final leida = NotificacionesServicio.estaLeidaPor(data, sesion.uid);
    final color = obtenerColor(data['color']?.toString() ?? '');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => NotificacionesServicio.marcarLeida(
        doc.reference,
        sesion.uid,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: leida ? const Color(0xFFF8FAFC) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                leida ? const Color(0xFFE8ECF2) : color.withValues(alpha: 0.28),
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
                obtenerIcono(data['icono']?.toString() ?? ''),
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
                          data['titulo']?.toString() ?? 'Notificaci\u00f3n',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight:
                                leida ? FontWeight.w600 : FontWeight.w700,
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
                    data['descripcion']?.toString() ?? '',
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
                    tiempoRelativo(data['fecha'] as Timestamp?),
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
