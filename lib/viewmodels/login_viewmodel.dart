import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LoginViewModel extends ChangeNotifier {
  LoginViewModel({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;
  bool _cargando = false;

  bool get cargando => _cargando;

  void _setCargando(bool valor) {
    if (_cargando == valor) return;
    _cargando = valor;
    notifyListeners();
  }

  Future<String?> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    final correoLimpio = correo.trim();
    final passwordLimpio = password.trim();

    if (correoLimpio.isEmpty || passwordLimpio.isEmpty) {
      return 'Ingrese correo y contraseña';
    }

    _setCargando(true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: correoLimpio,
        password: passwordLimpio,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeErrorInicioSesion(e);
    } finally {
      _setCargando(false);
    }
  }

  Future<String?> enviarRecuperacionPassword(String correo) async {
    final correoLimpio = correo.trim();

    if (correoLimpio.isEmpty) {
      return 'Escribe tu correo electrónico';
    }

    try {
      await _auth.sendPasswordResetEmail(email: correoLimpio);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensajeErrorRecuperacion(e);
    }
  }

  String _mensajeErrorInicioSesion(FirebaseAuthException e) {
    if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
      return 'Correo o contraseña incorrectos';
    }
    if (e.code == 'wrong-password') {
      return 'Contraseña incorrecta';
    }
    if (e.code == 'invalid-email') {
      return 'Correo inválido';
    }
    if (e.code == 'network-request-failed') {
      return 'Error de conexión a internet';
    }

    return 'Error al iniciar sesión';
  }

  String _mensajeErrorRecuperacion(FirebaseAuthException e) {
    if (e.code == 'invalid-email') {
      return 'Correo inválido';
    }
    if (e.code == 'user-not-found') {
      return 'No existe una cuenta con ese correo';
    }

    return 'No se pudo enviar el correo';
  }
}
