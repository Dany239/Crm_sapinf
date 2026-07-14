import 'package:flutter/material.dart';

import '../../viewmodels/agregar_usuario_viewmodel.dart';

class AgregarUsuarioPantalla extends StatefulWidget {
  const AgregarUsuarioPantalla({super.key});

  @override
  State<AgregarUsuarioPantalla> createState() => _AgregarUsuarioPantallaState();
}

class _AgregarUsuarioPantallaState extends State<AgregarUsuarioPantalla> {
  final nombreController = TextEditingController();
  final correoController = TextEditingController();
  final passwordController = TextEditingController();
  late final AgregarUsuarioViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AgregarUsuarioViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    nombreController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> guardarUsuario() async {
    final guardado = await viewModel.guardarUsuario(
      nombre: nombreController.text,
      correo: correoController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    if (!guardado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.mensajeError ?? 'Error al crear usuario'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario creado correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
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
                  initialValue: viewModel.rolSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'administrador',
                      child: Text('Administrador'),
                    ),
                    DropdownMenuItem(
                      value: 'vendedor',
                      child: Text('Vendedor'),
                    ),
                  ],
                  onChanged: (valor) {
                    if (valor == null) return;
                    viewModel.seleccionarRol(valor);
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: viewModel.cargando ? null : guardarUsuario,
                    child: viewModel.cargando
                        ? const CircularProgressIndicator()
                        : const Text('Guardar Usuario'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
