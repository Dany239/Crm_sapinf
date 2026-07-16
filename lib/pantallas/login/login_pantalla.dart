import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'registro_pantalla.dart';
import '../../widgets/sapinf_logo.dart';
import '../../widgets/sapinf_textfield.dart';
import '../../viewmodels/login_viewmodel.dart';

class LoginPantalla extends StatefulWidget {
  const LoginPantalla({super.key});

  @override
  State<LoginPantalla> createState() => _LoginPantallaState();
}

class _LoginPantallaState extends State<LoginPantalla> {
  final LoginViewModel viewModel = LoginViewModel();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  final resetCorreoController = TextEditingController();

  bool verPassword = false;

  bool get cargando => viewModel.cargando;

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_actualizarEstado);
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizarEstado);
    viewModel.dispose();
    correoController.dispose();
    passwordController.dispose();
    resetCorreoController.dispose();
    super.dispose();
  }

  void _actualizarEstado() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> iniciarSesion() async {
    final mensaje = await viewModel.iniciarSesion(
      correo: correoController.text,
      password: passwordController.text,
    );

    if (!mounted || mensaje == null) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> enviarRecuperacionPassword() async {
    final mensaje = await viewModel.enviarRecuperacionPassword(
      resetCorreoController.text,
    );

    if (!mounted) return;

    if (mensaje != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Te enviamos un correo para cambiar tu contraseña'),
      ),
    );
  }

  void mostrarRecuperarPassword() {
    resetCorreoController.text = correoController.text.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Recuperar contraseña',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F1F44),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Te enviaremos un enlace para cambiarla de forma segura.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                campoLogin(
                  controller: resetCorreoController,
                  texto: 'Correo electrónico',
                  icono: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: enviarRecuperacionPassword,
                    icon: const Icon(Icons.mark_email_read_rounded),
                    label: Text(
                      'Enviar enlace',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget campoLogin({
    required TextEditingController controller,
    required String texto,
    required IconData icono,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3DDF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.20),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icono, color: Colors.white, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              style: GoogleFonts.poppins(
                color: const Color(0xFF0F1F44),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: texto,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          ?suffixIcon,
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget botonLogin() {
    return Container(
      width: double.infinity,
      height: 62,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: cargando ? null : iniciarSesion,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          disabledBackgroundColor: const Color(0xFF29B6F6),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: cargando
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login_rounded, size: 29),
                  const SizedBox(width: 16),
                  Text(
                    'Iniciar sesión',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget separadorDecorativo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 74,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                const Color(0xFF9DB8F2).withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFF1565C0),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 74,
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF9DB8F2).withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget tarjetaLogin(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final compacto = ancho < 390;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: EdgeInsets.fromLTRB(
        compacto ? 22 : 30,
        compacto ? 26 : 34,
        compacto ? 22 : 30,
        compacto ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 24),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(-8, -8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SapinfLogo(size: 165),
          const SizedBox(height: 18),
          Text(
            'SAPINF CRM',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: compacto ? 31 : 36,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF10275F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gestión de clientes y ventas',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: compacto ? 14 : 15,
              color: const Color(0xFF7B849C),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          separadorDecorativo(),
          const SizedBox(height: 28),
          SapinfTextField(
            controller: correoController,
            hintText: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          campoLogin(
            controller: passwordController,
            texto: 'Contraseña',
            icono: Icons.lock_outline_rounded,
            obscureText: !verPassword,
            suffixIcon: IconButton(
              splashRadius: 22,
              icon: Icon(
                verPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: const Color(0xFF31477A),
              ),
              onPressed: () {
                setState(() {
                  verPassword = !verPassword;
                });
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: mostrarRecuperarPassword,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1565C0),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          botonLogin(),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '¿No tienes cuenta?',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF667085),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegistroPantalla(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Regístrate',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1565C0),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06163D),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/fondo_sapinf.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                child: tarjetaLogin(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
