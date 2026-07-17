import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/servicio_model.dart';
import '../viewmodels/editar_servicio_viewmodel.dart';
import 'logo_servicio.dart';

class EditarServicioPantalla extends StatefulWidget {
  final String servicioId;
  final Map<String, dynamic> servicio;

  const EditarServicioPantalla({
    super.key,
    required this.servicioId,
    required this.servicio,
  });

  @override
  State<EditarServicioPantalla> createState() => _EditarServicioPantallaState();
}

class _EditarServicioPantallaState extends State<EditarServicioPantalla> {
  late TextEditingController nombreController;
  late TextEditingController descripcionController;
  late TextEditingController precioController;
  late EditarServicioViewModel viewModel;

  @override
  void initState() {
    super.initState();
    final servicio = ServicioModel.fromMap(
      widget.servicio,
      id: widget.servicioId,
    );

    nombreController = TextEditingController(text: servicio.nombre);
    descripcionController = TextEditingController(text: servicio.descripcion);
    precioController = TextEditingController(text: servicio.precio);
    viewModel = EditarServicioViewModel(servicioInicial: servicio);
  }

  Future<void> seleccionarLogo() async {
    final error = await viewModel.seleccionarLogo();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen más liviana')),
      );
      return;
    }
    setState(() {});
  }

  Future<void> actualizarServicio() async {
    if (nombreController.text.trim().isEmpty ||
        descripcionController.text.trim().isEmpty ||
        viewModel.logoBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el nombre, la descripción y el logo'),
        ),
      );
      return;
    }

    setState(() {
      viewModel.cargando = true;
    });

    await viewModel.actualizarServicio(
      servicioId: widget.servicioId,
      nombre: nombreController.text,
      descripcion: descripcionController.text,
      precio: precioController.text,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servicio actualizado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> eliminarServicio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Eliminar servicio',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '¿Seguro que deseas eliminar este servicio?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_rounded, size: 18),
              label: Text(
                'Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar == true) {
      await viewModel.eliminarServicio(widget.servicioId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Servicio eliminado correctamente')),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  Widget campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: GoogleFonts.poppins(
        color: const Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        prefixIcon: Icon(icono, color: const Color(0xFF1565C0)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.5),
        ),
      ),
    );
  }

  Widget encabezado() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editar servicio',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Actualiza el precio, descripción o nombre del servicio.',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget botonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: viewModel.cargando ? null : actualizarServicio,
        icon: viewModel.cargando
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          viewModel.cargando ? 'Guardando...' : 'Guardar cambios',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget botonEliminar() {
    return IconButton(
      tooltip: 'Eliminar servicio',
      onPressed: eliminarServicio,
      icon: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
      ),
    );
  }

  Widget selectorLogo() {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: seleccionarLogo,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            LogoServicio(logoBase64: viewModel.logoBase64, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                viewModel.logoBase64.isEmpty
                    ? 'Agregar logo del servicio'
                    : 'Cambiar logo del servicio',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: Color(0xFF1565C0),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1F2937),
        title: Text(
          'Editar Servicio',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [botonEliminar()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        child: Column(
          children: [
            encabezado(),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  selectorLogo(),
                  const SizedBox(height: 14),
                  campoTexto(
                    controller: nombreController,
                    label: 'Nombre del servicio',
                    icono: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 14),
                  campoTexto(
                    controller: descripcionController,
                    label: 'Descripción',
                    icono: Icons.notes_rounded,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 14),
                  campoTexto(
                    controller: precioController,
                    label: 'Precio',
                    icono: Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 18),
                  botonGuardar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
