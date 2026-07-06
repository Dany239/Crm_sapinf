import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AgregarUsuarioPantalla extends StatefulWidget {
  const AgregarUsuarioPantalla({super.key});

  @override
  State<AgregarUsuarioPantalla> createState() => _AgregarUsuarioPantallaState();
}

class _AgregarUsuarioPantallaState extends State<AgregarUsuarioPantalla> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();

  String rolSeleccionado = 'vendedor';
  bool cargando = false;

  Future<void> guardarUsuario() async {
    if (nombreController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos')),
      );
      return;
    }

    if (passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contraseña debe tener mínimo 6 caracteres'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    try {
      final credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: correoController.text.trim(),
            password: passwordController.text.trim(),
          );

      final uid = credencial.user!.uid;
      await credencial.user!.updateDisplayName(nombreController.text.trim());

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': nombreController.text.trim(),
        'correo': correoController.text.trim(),
        'rol': rolSeleccionado,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario creado correctamente')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al crear usuario';

      if (e.code == 'email-already-in-use') {
        mensaje = 'Este correo ya está registrado';
      } else if (e.code == 'invalid-email') {
        mensaje = 'Correo electrónico inválido';
      } else if (e.code == 'weak-password') {
        mensaje = 'La contraseña es muy débil';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: correoController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña temporal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: rolSeleccionado,
              decoration: const InputDecoration(
                labelText: 'Rol',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'administrador',
                  child: Text('Administrador'),
                ),
                DropdownMenuItem(value: 'vendedor', child: Text('Vendedor')),
              ],
              onChanged: (valor) {
                setState(() {
                  rolSeleccionado = valor!;
                });
              },
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : guardarUsuario,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text('Guardar Usuario'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
