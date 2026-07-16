import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/sapinf_colors.dart';
import '../../viewmodels/splash_viewmodel.dart';
import '../../widgets/sapinf_logo.dart';

class SplashPantalla extends StatefulWidget {
  final Widget siguientePantalla;

  const SplashPantalla({super.key, required this.siguientePantalla});

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla>
    with TickerProviderStateMixin {
  late final AnimationController animacionController;
  late final AnimationController cargaController;
  late final Animation<double> entrada;
  late final Timer temporizador;
  late final SplashViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SplashViewModel();

    animacionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    entrada = CurvedAnimation(
      parent: animacionController,
      curve: Curves.easeOutCubic,
    );

    cargaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();

    animacionController.forward();
    temporizador = Timer(const Duration(seconds: 6), abrirApp);
  }

  Future<void> abrirApp() async {
    await viewModel.cerrarSesionInicial();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => widget.siguientePantalla,
        transitionDuration: const Duration(milliseconds: 450),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    temporizador.cancel();
    viewModel.dispose();
    animacionController.dispose();
    cargaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.sizeOf(context).height;
    final logoSize = alto < 720 ? 210.0 : 260.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashFondo(),
          SafeArea(
            child: FadeTransition(
              opacity: entrada,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 38),
                    const Align(
                      alignment: Alignment.topRight,
                      child: _PuntosDecorativos(),
                    ),
                    const Spacer(flex: 2),
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.88, end: 1).animate(
                        CurvedAnimation(
                          parent: animacionController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: SapinfLogo(size: logoSize),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'SAPINF',
                            style: TextStyle(
                              color: SapinfColors.azulOscuro,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'CRM',
                            style: TextStyle(
                              color: SapinfColors.celeste,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _SeparadorMarca(),
                    const SizedBox(height: 16),
                    const Text(
                      'Sistema Inteligente de Gesti\u00f3n Comercial',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SapinfColors.azulOscuro,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const Spacer(flex: 1),
                    RotationTransition(
                      turns: cargaController,
                      child: const _SpinnerCarga(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cargando...',
                      style: TextStyle(
                        color: SapinfColors.azulOscuro,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(flex: 3),
                    const _AccionesSplash(),
                    const SizedBox(height: 52),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashFondo extends StatelessWidget {
  const _SplashFondo();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashFondoPainter(), child: Container());
  }
}

class _SplashFondoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final azul = SapinfColors.azulPrincipal;
    final azulOscuro = SapinfColors.azulOscuro;
    final celeste = SapinfColors.celeste;

    final fondo = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, fondo);

    final topPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              celeste.withValues(alpha: 0.82),
              celeste.withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(-size.width * 0.02, -size.height * 0.02),
              radius: size.width * 0.48,
            ),
          );
    canvas.drawCircle(
      Offset(-size.width * 0.02, -size.height * 0.02),
      size.width * 0.48,
      topPaint,
    );

    for (var i = 0; i < 8; i++) {
      final paint = Paint()
        ..color = azul.withValues(alpha: 0.10 - (i * 0.008))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(
        Offset(-size.width * 0.02, -size.height * 0.02),
        size.width * (0.18 + i * 0.045),
        paint,
      );
    }

    final wave1 = Path()
      ..moveTo(0, size.height * 0.66)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.86,
        size.width * 0.50,
        size.height * 0.76,
        size.width,
        size.height * 0.58,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave1,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.72),
            celeste.withValues(alpha: 0.74),
            azul,
          ],
        ).createShader(Offset.zero & size),
    );

    final wave2 = Path()
      ..moveTo(0, size.height * 0.77)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.86,
        size.width * 0.48,
        size.height * 0.91,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave2,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF05BFFF), azul, azulOscuro],
        ).createShader(Offset.zero & size),
    );

    final wave3 = Path()
      ..moveTo(0, size.height * 0.84)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.94,
        size.width * 0.58,
        size.height * 0.86,
        size.width,
        size.height * 0.77,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      wave3,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
          colors: [azul.withValues(alpha: 0.90), azulOscuro],
        ).createShader(Offset.zero & size),
    );

    for (var i = 0; i < 8; i++) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16 - (i * 0.012))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(
        Offset(size.width * 0.98, size.height * 0.78),
        size.width * (0.10 + i * 0.045),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PuntosDecorativos extends StatelessWidget {
  const _PuntosDecorativos();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Wrap(
        spacing: 9,
        runSpacing: 9,
        children: List.generate(
          9,
          (_) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: SapinfColors.celeste.withValues(alpha: 0.38),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _SeparadorMarca extends StatelessWidget {
  const _SeparadorMarca();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 126, height: 2, color: SapinfColors.celeste),
        const SizedBox(width: 14),
        Container(
          width: 13,
          height: 13,
          decoration: const BoxDecoration(
            color: SapinfColors.celeste,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        Container(width: 126, height: 2, color: SapinfColors.celeste),
      ],
    );
  }
}

class _SpinnerCarga extends StatelessWidget {
  const _SpinnerCarga();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 50,
      child: CustomPaint(painter: _SpinnerCargaPainter()),
    );
  }
}

class _SpinnerCargaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);

    for (var i = 0; i < 12; i++) {
      final opacity = 0.22 + (i / 12) * 0.78;
      final angle = (i / 12) * 6.283185307179586;
      final start = Offset(
        centro.dx + size.width * 0.30 * math.cos(angle),
        centro.dy + size.height * 0.30 * math.sin(angle),
      );
      final end = Offset(
        centro.dx + size.width * 0.42 * math.cos(angle),
        centro.dy + size.height * 0.42 * math.sin(angle),
      );

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = SapinfColors.celeste.withValues(alpha: opacity)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AccionesSplash extends StatelessWidget {
  const _AccionesSplash();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _AccionSplash(icono: Icons.groups_rounded, texto: 'Conecta'),
        _SeparadorAccion(),
        _AccionSplash(icono: Icons.analytics_outlined, texto: 'Gestiona'),
        _SeparadorAccion(),
        _AccionSplash(icono: Icons.track_changes_rounded, texto: 'Crece'),
      ],
    );
  }
}

class _AccionSplash extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _AccionSplash({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 34),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeparadorAccion extends StatelessWidget {
  const _SeparadorAccion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: Colors.white.withValues(alpha: 0.55),
    );
  }
}
