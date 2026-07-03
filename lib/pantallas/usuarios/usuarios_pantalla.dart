import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import 'agregar_usuario_pantalla.dart';
import 'editar_usuario_pantalla.dart';

class UsuariosPantalla extends StatelessWidget {
  const UsuariosPantalla({super.key});

  String tiempoDesdeUltimaActividad(dynamic valor) {
    if (valor is! Timestamp) return 'Aun no registra actividad';

    final diferencia = DateTime.now().difference(valor.toDate());

    if (diferencia.inMinutes < 1) return 'Ahora mismo';
    if (diferencia.inMinutes < 60) {
      return 'Hace ${diferencia.inMinutes} minutos';
    }
    if (diferencia.inHours < 24) {
      return 'Hace ${diferencia.inHours} horas';
    }
    if (diferencia.inDays == 1) return 'Hace 1 dia';
    return 'Hace ${diferencia.inDays} dias';
  }

  Widget accesoRestringido() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.red,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Acceso restringido',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Solo administradores pueden gestionar usuarios.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget tarjetaUsuario({
    required BuildContext context,
    required String id,
    required Map<String, dynamic> usuario,
  }) {
    final rol = usuario['rol'] ?? 'Sin rol';
    final esAdmin = rol == 'administrador';
    final color = esAdmin ? Colors.indigo : const Color(0xFF1565C0);
    final ultimaActividad = usuario['ultimaActividad'];
    final estaActivo = ultimaActividad is Timestamp &&
        DateTime.now().difference(ultimaActividad.toDate()).inMinutes <= 15;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarUsuarioPantalla(
              usuarioId: id,
              usuario: usuario,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                esAdmin
                    ? Icons.admin_panel_settings_rounded
                    : Icons.person_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usuario['nombre'] ?? 'Sin nombre',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    usuario['correo'] ?? 'Sin correo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (!esAdmin) ...[
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: estaActivo
                                ? Colors.green
                                : Colors.amber.shade700,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${estaActivo ? 'Activo' : 'Sin actividad'} · '
                            '${tiempoDesdeUltimaActividad(ultimaActividad)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: estaActivo
                                  ? Colors.green.shade700
                                  : Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                rol,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuarioActual = FirebaseAuth.instance.currentUser;

    if (usuarioActual == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario activo')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1F2937),
        title: Text(
          'Usuarios',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(usuarioActual.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          final rol = data?['rol']?.toString() ?? 'vendedor';

          if (rol != 'administrador') {
            return accesoRestringido();
          }

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance.collection('usuarios').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final usuarios = snapshot.data!.docs;

              return Stack(
                children: [
                  if (usuarios.isEmpty)
                    Center(
                      child: Text(
                        'No hay usuarios registrados',
                        style: GoogleFonts.poppins(),
                      ),
                    )
                  else
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: usuarios.length,
                      itemBuilder: (context, index) {
                        final usuario =
                            usuarios[index].data() as Map<String, dynamic>;

                        return tarjetaUsuario(
                          context: context,
                          id: usuarios[index].id,
                          usuario: usuario,
                        );
                      },
                    ),
                  Positioned(
                    right: 16,
                    bottom: 18,
                    child: FloatingActionButton.extended(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.person_add_rounded),
                      label: Text(
                        'Nuevo',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AgregarUsuarioPantalla(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
