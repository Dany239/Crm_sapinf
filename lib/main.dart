import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'pantallas/login/login_pantalla.dart';
import 'pantallas/navegacion/navegacion_pantalla.dart';
import 'pantallas/splash/splash_pantalla.dart';
import 'theme/sapinf_colors.dart';
import 'widgets/registrador_actividad.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAPINF CRM',
      locale: const Locale('es', 'HN'),
      supportedLocales: const [Locale('es', 'HN'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: SapinfColors.azulPrincipal,
          primary: SapinfColors.azulPrincipal,
          secondary: SapinfColors.celeste,
          surface: SapinfColors.blanco,
        ),
        scaffoldBackgroundColor: SapinfColors.grisClaro,
        appBarTheme: const AppBarTheme(
          backgroundColor: SapinfColors.grisClaro,
          foregroundColor: SapinfColors.textPrimary,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: SapinfColors.azulPrincipal,
          foregroundColor: SapinfColors.blanco,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SapinfColors.azulPrincipal,
            foregroundColor: SapinfColors.blanco,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: SapinfColors.celeste,
        ),
      ),
      home: const SplashPantalla(siguientePantalla: AuthGate()),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const RegistradorActividad(child: NavegacionPantalla());
        }

        return const LoginPantalla();
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SAPINF CRM')),
      body: const Center(
        child: Text(
          'Firebase conectado correctamente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
