import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class PerfilPantalla extends StatelessWidget {
  const PerfilPantalla({super.key});

  Future<void> cerrarSesion(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> enviarCambioPassword(BuildContext context) async {
    final usuario = FirebaseAuth.instance.currentUser;
    final correo = usuario?.email;

    if (correo == null) return;

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

    if (passwordActual.isEmpty ||
        passwordNueva.isEmpty ||
        passwordConfirmar.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    if (passwordNueva.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('La contrase\u00f1a debe tener m\u00ednimo 6 caracteres'),
        ),
      );
      return;
    }

    if (passwordNueva != passwordConfirmar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contrase\u00f1as no coinciden')),
      );
      return;
    }

    try {
      final credencial = EmailAuthProvider.credential(
        email: correo,
        password: passwordActual,
      );

      await usuario!.reauthenticateWithCredential(credencial);
      await usuario.updatePassword(passwordNueva);
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      var mensaje = 'No se pudo cambiar la contrase\u00f1a';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        mensaje = 'La contrase\u00f1a actual no es correcta';
      } else if (e.code == 'weak-password') {
        mensaje = 'La nueva contrase\u00f1a es muy d\u00e9bil';
      } else if (e.code == 'requires-recent-login') {
        mensaje = 'Vuelve a iniciar sesi\u00f3n e intenta de nuevo';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
      return;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Contrase\u00f1a actualizada correctamente')),
    );
  }

  Future<void> seleccionarImagen(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();

    final XFile? imagen = await picker.pickImage(
      source: source,
      imageQuality: 55,
      maxWidth: 500,
    );

    if (imagen == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subiendo foto de perfil...')),
    );

    try {
      final bytes = await imagen.readAsBytes();
      final fotoBase64 = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'fotoBase64': fotoBase64,
        'fechaActualizacionFoto': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada correctamente')),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar la foto: ${e.code}'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar la foto: $e')),
      );
    }
  }

  ImageProvider? obtenerFotoPerfil(Map<String, dynamic>? data) {
    final fotoBase64 = data?['fotoBase64']?.toString();

    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      return MemoryImage(base64Decode(fotoBase64));
    }

    final fotoUrl = data?['foto']?.toString();

    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return NetworkImage(fotoUrl);
    }

    return null;
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                        seleccionarImagen(parentContext, ImageSource.gallery);
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
                        seleccionarImagen(parentContext, ImageSource.camera);
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
            Text(
              texto,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
            style: TextStyle(
              color: colorEfectivo,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final uid = usuario?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: uid == null
          ? const Center(child: Text('No hay usuario activo'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;

                final nombre = data?['nombre'] ?? 'Usuario';
                final rol = data?['rol'] ?? 'Sin rol';
                final rolFormateado = rol[0].toUpperCase() + rol.substring(1);
                final correo = usuario?.email ?? 'Sin correo';
                final fotoPerfil = obtenerFotoPerfil(data);

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
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
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
                                        color: Colors.black.withOpacity(0.10),
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
                                            color: Colors.black.withOpacity(
                                              0.16,
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
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
