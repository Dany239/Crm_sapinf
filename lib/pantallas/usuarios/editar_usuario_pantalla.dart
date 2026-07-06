import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late TextEditingController nombreController;
  late TextEditingController correoController;

  String rolSeleccionado = 'vendedor';
  bool accesoAdministrador = false;
  bool cargando = false;

  @override
  void initState() {
    super.initState();

    nombreController = TextEditingController(
      text: widget.usuario['nombre'] ?? '',
    );

    correoController = TextEditingController(
      text: widget.usuario['correo'] ?? '',
    );

    rolSeleccionado = widget.usuario['rol'] ?? 'vendedor';
    accesoAdministrador = widget.usuario['accesoAdministrador'] == true;
  }

  Future<void> actualizarUsuario() async {
    if (nombreController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete todos los campos')),
      );
      return;
    }

    final nombre = nombreController.text.trim();
    final correo = correoController.text.trim();

    setState(() {
      cargando = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .update({
            'nombre': nombre,
            'correo': correo,
            'rol': rolSeleccionado,
            'accesoAdministrador':
                rolSeleccionado == 'administrador' || accesoAdministrador,
            'fechaActualizacion': FieldValue.serverTimestamp(),
          });

      await Future.wait([
        actualizarNombreVendedorEnColeccion('clientes', nombre, correo),
        actualizarNombreVendedorEnColeccion('ventas', nombre, correo),
        actualizarNombreVendedorEnColeccion('seguimientos', nombre, correo),
      ]);
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        cargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: ${e.code}')),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usuario actualizado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> actualizarNombreVendedorEnColeccion(
    String coleccion,
    String nombre,
    String correo,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(coleccion)
        .where('vendedorId', isEqualTo: widget.usuarioId)
        .get();

    WriteBatch batch = FirebaseFirestore.instance.batch();
    var operaciones = 0;

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'vendedorNombre': nombre,
        'vendedorCorreo': correo,
      });
      operaciones++;

      if (operaciones == 450) {
        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        operaciones = 0;
      }
    }

    if (operaciones > 0) {
      await batch.commit();
    }
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
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.usuarioId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario eliminado correctamente')),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: eliminarUsuario,
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
            if (rolSeleccionado == 'vendedor') ...[
              const SizedBox(height: 10),
              SwitchListTile(
                value: accesoAdministrador,
                contentPadding: EdgeInsets.zero,
                title: const Text('Acceso administrativo'),
                subtitle: const Text(
                  'Puede consultar reportes y administrar m\u00f3dulos.',
                ),
                onChanged: (valor) {
                  setState(() {
                    accesoAdministrador = valor;
                  });
                },
              ),
            ],
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : actualizarUsuario,
                child: cargando
                    ? const CircularProgressIndicator()
                    : const Text('Guardar Cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
