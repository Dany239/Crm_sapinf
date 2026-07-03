import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarClientePantalla extends StatefulWidget {
  final String clienteId;
  final Map<String, dynamic> cliente;

  const EditarClientePantalla({
    super.key,
    required this.clienteId,
    required this.cliente,
  });

  @override
  State<EditarClientePantalla> createState() => _EditarClientePantallaState();
}

class _EditarClientePantallaState extends State<EditarClientePantalla> {
  late TextEditingController nombreController;
  late TextEditingController telefonoController;
  late TextEditingController correoController;
  late TextEditingController empresaController;

  bool cargando = false;

  @override
  void initState() {
    super.initState();

    nombreController =
        TextEditingController(text: widget.cliente['nombre'] ?? '');

    telefonoController =
        TextEditingController(text: widget.cliente['telefono'] ?? '');

    correoController =
        TextEditingController(text: widget.cliente['correo'] ?? '');

    empresaController =
        TextEditingController(text: widget.cliente['empresa'] ?? '');
  }

  Future<void> actualizarCliente() async {
    setState(() {
      cargando = true;
    });

    await FirebaseFirestore.instance
        .collection('clientes')
        .doc(widget.clienteId)
        .update({
      'nombre': nombreController.text.trim(),
      'telefono': telefonoController.text.trim(),
      'correo': correoController.text.trim(),
      'empresa': empresaController.text.trim(),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cliente actualizado correctamente'),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> eliminarCliente() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar cliente'),
          content: const Text(
            '¿Seguro que deseas eliminar este cliente?',
          ),
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

    if (confirmar == true) {
      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(widget.clienteId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente eliminado correctamente'),
        ),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    empresaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: eliminarCliente,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: correoController,
              decoration: const InputDecoration(
                labelText: 'Correo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: empresaController,
              decoration: const InputDecoration(
                labelText: 'Empresa',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cargando ? null : actualizarCliente,
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
