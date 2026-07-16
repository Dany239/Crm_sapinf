import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/registro_viewmodel.dart';

class RegistroPantalla extends StatefulWidget {
  const RegistroPantalla({super.key});

  @override
  State<RegistroPantalla> createState() => _RegistroPantallaState();
}

class _RegistroPantallaState extends State<RegistroPantalla> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final RegistroViewModel viewModel = RegistroViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_actualizar);
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizar);
    viewModel.dispose();
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  Future<void> registrarVendedor() async {
    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    final error = viewModel.validar(
      nombre: nombre,
      correo: correo,
      password: password,
    );

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final mensajeError = await viewModel.registrarVendedor(
      nombre: nombre,
      correo: correo,
      password: password,
    );

    if (!mounted) return;

    if (mensajeError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensajeError)));
      return;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  InputDecoration campoDecoracion({
    required String texto,
    required IconData icono,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: texto,
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      prefixIcon: Icon(icono, color: const Color(0xFF1565C0)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
      ),
    );
  }

  Widget botonRegistro() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: viewModel.cargando ? null : registrarVendedor,
        icon: viewModel.cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.person_add_rounded),
        label: Text(
          viewModel.cargando ? 'Creando cuenta...' : 'Crear cuenta',
          style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1F2937),
        title: Text(
          'Registrarse',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nueva cuenta',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Tu cuenta se creará como vendedor.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: nombreController,
                    textCapitalization: TextCapitalization.words,
                    decoration: campoDecoracion(
                      texto: 'Nombre completo',
                      icono: Icons.person_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: correoController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: campoDecoracion(
                      texto: 'Correo electrónico',
                      icono: Icons.email_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: passwordController,
                    obscureText: !viewModel.verPassword,
                    decoration: campoDecoracion(
                      texto: 'Contraseña',
                      icono: Icons.lock_rounded,
                      suffixIcon: IconButton(
                        icon: Icon(
                          viewModel.verPassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: viewModel.alternarVerPassword,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  botonRegistro(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
