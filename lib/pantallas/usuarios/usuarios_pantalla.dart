import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/usuario_model.dart';
import '../../viewmodels/usuarios_viewmodel.dart';
import 'agregar_usuario_pantalla.dart';
import 'editar_usuario_pantalla.dart';

class UsuariosPantalla extends StatefulWidget {
  const UsuariosPantalla({super.key});

  @override
  State<UsuariosPantalla> createState() => _UsuariosPantallaState();
}

class _UsuariosPantallaState extends State<UsuariosPantalla> {
  late final UsuariosViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = UsuariosViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
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
    required UsuarioModel usuario,
  }) {
    final rol = usuario.rol;
    final esAdmin = rol == 'administrador';
    final color = esAdmin ? Colors.indigo : const Color(0xFF1565C0);
    final estaActivo = viewModel.estaActivo(usuario);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarUsuarioPantalla(
              usuarioId: usuario.id ?? '',
              usuario: usuario.toPlainMap(),
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
                    usuario.nombre,
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
                    usuario.correo,
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
                            '${viewModel.tiempoDesdeUltimaActividad(usuario.ultimaActividad)}',
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

  Widget contenidoUsuarios() {
    return StreamBuilder<List<UsuarioModel>>(
      stream: viewModel.usuariosStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final usuarios = snapshot.data ?? [];

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
                  return tarjetaUsuario(
                    context: context,
                    usuario: usuarios[index],
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgregarUsuarioPantalla(),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!viewModel.hayUsuarioActivo) {
      return const Scaffold(body: Center(child: Text('No hay usuario activo')));
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
      body: StreamBuilder<UsuarioModel?>(
        stream: viewModel.usuarioActualStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!viewModel.puedeGestionarUsuarios(snapshot.data)) {
            return accesoRestringido();
          }

          return contenidoUsuarios();
        },
      ),
    );
  }
}
