import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'logo_servicio.dart';

class AgregarServicioPantalla extends StatefulWidget {
  const AgregarServicioPantalla({super.key});

  @override
  State<AgregarServicioPantalla> createState() =>
      _AgregarServicioPantallaState();
}

class _AgregarServicioPantallaState extends State<AgregarServicioPantalla> {
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();

  bool cargando = false;
  String logoBase64 = '';

  Future<void> seleccionarLogo() async {
    final imagen = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 72,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (imagen == null) return;

    final bytes = await imagen.readAsBytes();
    if (!mounted) return;
    if (bytes.lengthInBytes > 750000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una imagen más liviana')),
      );
      return;
    }
    setState(() => logoBase64 = base64Encode(bytes));
  }

  Future<void> guardarServicio() async {
    if (nombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del servicio es obligatorio')),
      );
      return;
    }
    if (descripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La descripción es obligatoria')),
      );
      return;
    }
    if (logoBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el logo del servicio')),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    await FirebaseFirestore.instance.collection('servicios').add({
      'nombre': nombreController.text.trim(),
      'descripcion': descripcionController.text.trim(),
      'precio': precioController.text.trim(),
      'logoBase64': logoBase64,
      'fechaRegistro': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servicio guardado correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
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
          colors: [
            Color(0xFF1565C0),
            Color(0xFF29B6F6),
          ],
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
              Icons.design_services_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nuevo servicio',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Registra una solución para venderla después.',
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
        onPressed: cargando ? null : guardarServicio,
        icon: cargando
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
          cargando ? 'Guardando...' : 'Guardar servicio',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
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
            LogoServicio(logoBase64: logoBase64, size: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    logoBase64.isEmpty
                        ? 'Agregar logo del servicio'
                        : 'Cambiar logo',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1F2937),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Selecciona una imagen desde la galería',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
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
          'Agregar Servicio',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
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
                    label: 'Precio estimado',
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
