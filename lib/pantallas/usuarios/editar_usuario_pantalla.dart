import 'package:flutter/material.dart';

import '../../viewmodels/editar_usuario_viewmodel.dart';

class EditarUsuarioPantalla extends StatefulWidget {
  final String usuarioId;
  final Map<String, dynamic> usuario;

  const EditarUsuarioPantalla({
    super.key,
    required this.usuarioId,
    required this.usuario,
  });

  @override
  State<EditarUsuarioPantalla> createState() => _EditarUsuarioPantallaState();
}

class _EditarUsuarioPantallaState extends State<EditarUsuarioPantalla> {
  late final EditarUsuarioViewModel viewModel;
  late final TextEditingController nombreController;
  late final TextEditingController correoController;

  @override
  void initState() {
    super.initState();
    viewModel = EditarUsuarioViewModel(
      usuarioId: widget.usuarioId,
      usuario: widget.usuario,
    );
    nombreController = TextEditingController(
      text: widget.usuario['nombre']?.toString() ?? '',
    );
    correoController = TextEditingController(
      text: widget.usuario['correo']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    nombreController.dispose();
    correoController.dispose();
    super.dispose();
  }

  Future<void> actualizarUsuario() async {
    final actualizado = await viewModel.actualizarUsuario(
      nombre: nombreController.text,
      correo: correoController.text,
    );

    if (!mounted) return;

    if (!actualizado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo actualizar el usuario',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario actualizado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> eliminarUsuario() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Usuario'),
          content: const Text('¿Seguro que deseas eliminar este usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final eliminado = await viewModel.eliminarUsuario();

    if (!mounted) return;

    if (!eliminado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo eliminar el usuario',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario eliminado correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Editar Usuario'),
            actions: [
              IconButton(
                icon: viewModel.eliminando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete),
                onPressed: viewModel.eliminando ? null : eliminarUsuario,
              ),
            ],
          ),
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
                if (viewModel.rolSeleccionado == 'vendedor') ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: viewModel.accesoAdministrador,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Acceso administrativo'),
                    subtitle: const Text(
                      'Puede consultar reportes y administrar módulos.',
                    ),
                    onChanged: viewModel.cambiarAccesoAdministrador,
                  ),
                ],
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: viewModel.cargando ? null : actualizarUsuario,
                    child: viewModel.cargando
                        ? const CircularProgressIndicator()
                        : const Text('Guardar Cambios'),
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
