import 'dart:async';

import 'package:flutter/material.dart';

import '../repositories/usuarios_repository.dart';

class RegistradorActividad extends StatefulWidget {
  final Widget child;

  const RegistradorActividad({super.key, required this.child});

  @override
  State<RegistradorActividad> createState() => _RegistradorActividadState();
}

class _RegistradorActividadState extends State<RegistradorActividad>
    with WidgetsBindingObserver {
  final UsuariosRepository _usuariosRepository = UsuariosRepository();
  Timer? _temporizador;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _registrarActividad();
    _temporizador = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _registrarActividad(),
    );
  }

  Future<void> _registrarActividad() async {
    try {
      await _usuariosRepository.registrarActividadActual();
    } catch (_) {
      // La actividad se volvera a intentar en el siguiente intervalo.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _registrarActividad();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
