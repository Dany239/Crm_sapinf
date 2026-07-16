import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SplashViewModel extends ChangeNotifier {
  SplashViewModel({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void> cerrarSesionInicial() {
    return _auth.signOut();
  }
}
