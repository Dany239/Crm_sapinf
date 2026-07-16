import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/usuario_model.dart';

class UsuariosRepository {
  final FirebaseAuth _auth;
  final CollectionReference<Map<String, dynamic>> _usuarios;

  UsuariosRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _usuarios = (firestore ?? FirebaseFirestore.instance).collection(
        'usuarios',
      );

  Future<String> crearUsuario({
    required UsuarioModel usuario,
    required String password,
  }) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: usuario.correo,
      password: password,
    );

    final uid = credencial.user!.uid;
    await credencial.user!.updateDisplayName(usuario.nombre);
    await _usuarios.doc(uid).set(usuario.toCreateMap());

    return uid;
  }

  String? get usuarioActualId => _auth.currentUser?.uid;

  String? get usuarioActualCorreo => _auth.currentUser?.email;

  String? get usuarioActualNombre => _auth.currentUser?.displayName;

  Future<void> cerrarSesion() {
    return _auth.signOut();
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNueva,
  }) async {
    final usuario = _auth.currentUser;
    final correo = usuario?.email;

    if (usuario == null || correo == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No hay usuario activo',
      );
    }

    final credencial = EmailAuthProvider.credential(
      email: correo,
      password: passwordActual,
    );

    await usuario.reauthenticateWithCredential(credencial);
    await usuario.updatePassword(passwordNueva);
  }

  Future<void> actualizarFotoActual(String fotoBase64) {
    final uid = usuarioActualId;
    if (uid == null) return Future.value();

    return _usuarios.doc(uid).set({
      'fotoBase64': fotoBase64,
      'fechaActualizacionFoto': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> registrarActividadActual() {
    final uid = usuarioActualId;
    if (uid == null) return Future.value();

    return _usuarios.doc(uid).set({
      'ultimaActividad': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<UsuarioModel?> escucharUsuarioActual() {
    final uid = usuarioActualId;
    if (uid == null) return Stream.value(null);

    return _usuarios.doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return UsuarioModel.fromMap(data, id: doc.id);
    });
  }

  Stream<List<UsuarioModel>> escucharUsuarios() {
    return _usuarios.snapshots().map((snapshot) {
      final usuarios = snapshot.docs
          .map((doc) => UsuarioModel.fromMap(doc.data(), id: doc.id))
          .toList();

      usuarios.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()),
      );

      return usuarios;
    });
  }

  Future<void> actualizarUsuario({
    required String usuarioId,
    required UsuarioModel usuario,
  }) async {
    await _usuarios.doc(usuarioId).update(usuario.toUpdateMap());

    await Future.wait([
      _actualizarNombreVendedorEnColeccion(
        coleccion: 'clientes',
        usuarioId: usuarioId,
        nombre: usuario.nombre,
        correo: usuario.correo,
      ),
      _actualizarNombreVendedorEnColeccion(
        coleccion: 'ventas',
        usuarioId: usuarioId,
        nombre: usuario.nombre,
        correo: usuario.correo,
      ),
      _actualizarNombreVendedorEnColeccion(
        coleccion: 'seguimientos',
        usuarioId: usuarioId,
        nombre: usuario.nombre,
        correo: usuario.correo,
      ),
    ]);
  }

  Future<void> eliminarUsuario(String usuarioId) {
    return _usuarios.doc(usuarioId).delete();
  }

  Future<void> _actualizarNombreVendedorEnColeccion({
    required String coleccion,
    required String usuarioId,
    required String nombre,
    required String correo,
  }) async {
    final firestore = _usuarios.firestore;
    final snapshot = await firestore
        .collection(coleccion)
        .where('vendedorId', isEqualTo: usuarioId)
        .get();

    WriteBatch batch = firestore.batch();
    var operaciones = 0;

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'vendedorNombre': nombre,
        'vendedorCorreo': correo,
      });
      operaciones++;

      if (operaciones == 450) {
        await batch.commit();
        batch = firestore.batch();
        operaciones = 0;
      }
    }

    if (operaciones > 0) {
      await batch.commit();
    }
  }
}
