import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RegistradorActividad extends StatefulWidget {
  final Widget child;

  const RegistradorActividad({
    super.key,
    required this.child,
  });

  @override
  State<RegistradorActividad> createState() => _RegistradorActividadState();
}

class _RegistradorActividadState extends State<RegistradorActividad>
    with WidgetsBindingObserver {
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
    final usuario = FirebaseAuth.instance.currentUser;
    if (usuario == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(usuario.uid)
          .set(
        {'ultimaActividad': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
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
