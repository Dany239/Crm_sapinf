import 'package:flutter/foundation.dart';

import '../models/usuario_model.dart';
import '../repositories/usuarios_repository.dart';

class NavegacionViewModel extends ChangeNotifier {
  NavegacionViewModel({UsuariosRepository? repository})
    : _repository = repository ?? UsuariosRepository();

  final UsuariosRepository _repository;

  int indiceActual = 0;

  bool get hayUsuarioAutenticado => _repository.usuarioActualId != null;

  Stream<UsuarioModel?> get usuarioActualStream {
    return _repository.escucharUsuarioActual();
  }

  void cambiarIndice(int index) {
    indiceActual = index;
    notifyListeners();
  }

  void asegurarIndiceValido(int totalPantallas) {
    if (indiceActual >= totalPantallas) {
      indiceActual = 0;
    }
  }
}
