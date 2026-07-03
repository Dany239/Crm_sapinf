import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SesionUsuario {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final bool accesoAdministrador;

  const SesionUsuario({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.accesoAdministrador = false,
  });

  bool get esAdministrador => rol == 'administrador' || accesoAdministrador;
}

Future<SesionUsuario> obtenerSesionUsuario() async {
  final usuario = FirebaseAuth.instance.currentUser;

  if (usuario == null) {
    return const SesionUsuario(
      uid: '',
      nombre: 'Vendedor',
      correo: '',
      rol: 'vendedor',
    );
  }

  final doc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(usuario.uid)
      .get();
  final data = doc.data();
  final nombre = data?['nombre']?.toString();

  return SesionUsuario(
    uid: usuario.uid,
    nombre:
        nombre == null || nombre.isEmpty ? usuario.email ?? 'Vendedor' : nombre,
    correo: usuario.email ?? data?['correo']?.toString() ?? '',
    rol: data?['rol']?.toString() ?? 'vendedor',
    accesoAdministrador: data?['accesoAdministrador'] == true,
  );
}

Map<String, dynamic> datosPropietario(SesionUsuario sesion) {
  return {
    'vendedorId': sesion.uid,
    'vendedorNombre': sesion.nombre,
    'vendedorCorreo': sesion.correo,
  };
}
