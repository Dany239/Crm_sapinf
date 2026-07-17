import 'package:flutter/material.dart';

import '../../models/usuario_model.dart';
import '../../viewmodels/perfil_viewmodel.dart';

class PerfilPantalla extends StatefulWidget {
  const PerfilPantalla({super.key, this.onVolver});

  final VoidCallback? onVolver;

  @override
  State<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends State<PerfilPantalla> {
  final PerfilViewModel viewModel = PerfilViewModel();

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> cerrarSesion(BuildContext context) async {
    await viewModel.cerrarSesion();
  }

  void volver() {
    if (widget.onVolver != null) {
      widget.onVolver!();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> enviarCambioPassword(BuildContext context) async {
    final passwordActualController = TextEditingController();
    final passwordNuevaController = TextEditingController();
    final passwordConfirmarController = TextEditingController();

    final datos = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Cambiar contrase\u00f1a'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordActualController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contrase\u00f1a actual',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordNuevaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nueva contrase\u00f1a',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordConfirmarController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirmar contrase\u00f1a',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, {
                  'actual': passwordActualController.text.trim(),
                  'nueva': passwordNuevaController.text.trim(),
                  'confirmar': passwordConfirmarController.text.trim(),
                });
              },
              icon: const Icon(Icons.lock_reset),
              label: const Text('Actualizar'),
            ),
          ],
        );
      },
    );

    passwordActualController.dispose();
    passwordNuevaController.dispose();
    passwordConfirmarController.dispose();

    if (datos == null) return;
    if (!context.mounted) return;

    final passwordActual = datos['actual'] ?? '';
    final passwordNueva = datos['nueva'] ?? '';
    final passwordConfirmar = datos['confirmar'] ?? '';

    final mensajeError = await viewModel.cambiarPasswordValidado(
      passwordActual: passwordActual,
      passwordNueva: passwordNueva,
      passwordConfirmar: passwordConfirmar,
    );

    if (!context.mounted) return;

    if (mensajeError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeError)));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contrase\u00f1a actualizada correctamente'),
      ),
    );
  }

  Future<void> seleccionarImagen(
    BuildContext context,
    PerfilFotoOrigen origen,
  ) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Subiendo foto de perfil...')));

    final resultado = await viewModel.seleccionarYActualizarFoto(origen);

    if (!context.mounted) return;

    if (resultado.actualizada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada correctamente')),
      );
      return;
    }

    if (resultado.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(resultado.error!)));
    }
  }

  ImageProvider? obtenerFotoPerfil(UsuarioModel? usuario) {
    return viewModel.obtenerFotoPerfil(usuario);
  }

  void mostrarOpcionesFoto(BuildContext context) {
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(26),
              topRight: Radius.circular(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Foto de perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _opcionFoto(
                      icono: Icons.photo_library,
                      texto: 'Galer\u00eda',
                      onTap: () {
                        Navigator.pop(context);
                        seleccionarImagen(
                          parentContext,
                          PerfilFotoOrigen.galeria,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _opcionFoto(
                      icono: Icons.photo_camera,
                      texto: 'C\u00e1mara',
                      onTap: () {
                        Navigator.pop(context);
                        seleccionarImagen(
                          parentContext,
                          PerfilFotoOrigen.camara,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionFoto({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icono, color: const Color(0xFF1565C0)),
            ),
            const SizedBox(height: 8),
            Text(texto, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget filaInfo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget opcionPerfil({
    required IconData icono,
    required String texto,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Builder(
      builder: (context) {
        final colorEfectivo = color ?? Theme.of(context).colorScheme.onSurface;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icono, color: colorEfectivo),
          title: Text(
            texto,
            style: TextStyle(color: colorEfectivo, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: !viewModel.hayUsuarioActivo
          ? const Center(child: Text('No hay usuario activo'))
          : StreamBuilder<UsuarioModel?>(
              stream: viewModel.usuarioStream,
              builder: (context, snapshot) {
                final usuario = snapshot.data;

                final nombre = usuario?.nombre ?? 'Usuario';
                final rolFormateado = viewModel.rolFormateado(usuario);
                final correo = viewModel.correoActual;
                final fotoPerfil = obtenerFotoPerfil(usuario);

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(
                          top: 45,
                          left: 20,
                          right: 20,
                          bottom: 70,
                        ),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF0D47A1),
                              Color(0xFF1565C0),
                              Color(0xFF29B6F6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: volver,
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Mi Perfil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -55),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: const Color(0xFFE3F2FD),
                                    backgroundImage: fotoPerfil,
                                    child: fotoPerfil == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 62,
                                            color: Color(0xFF1565C0),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(18),
                                    onTap: () => mostrarOpcionesFoto(context),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF29B6F6),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.16,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    nombre,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    rolFormateado,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'SAPINF CRM v1.0',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(),
                                  filaInfo('Correo', correo),
                                  filaInfo('Rol', rolFormateado),
                                  const Divider(),
                                  opcionPerfil(
                                    icono: Icons.lock_reset,
                                    texto: 'Cambiar contrase\u00f1a',
                                    onTap: () => enviarCambioPassword(context),
                                  ),
                                  opcionPerfil(
                                    icono: Icons.info_outline,
                                    texto: 'Acerca del sistema',
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('SAPINF CRM'),
                                            content: const Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Versi\u00f3n 1.0',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                Text(
                                                  'Desarrollado en Flutter + Firebase',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cerrar'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  opcionPerfil(
                                    icono: Icons.logout,
                                    texto: 'Cerrar sesi\u00f3n',
                                    color: Colors.red,
                                    onTap: () => cerrarSesion(context),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
