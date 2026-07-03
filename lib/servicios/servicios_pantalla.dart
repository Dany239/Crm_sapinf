import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'agregar_servicio_pantalla.dart';
import 'editar_servicio_pantalla.dart';
import 'logo_servicio.dart';

class ServiciosPantalla extends StatefulWidget {
  const ServiciosPantalla({super.key});

  @override
  State<ServiciosPantalla> createState() => _ServiciosPantallaState();
}

class _ServiciosPantallaState extends State<ServiciosPantalla> {
  final buscarController = TextEditingController();
  String busqueda = '';

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  String formatoLempiras(dynamic valor) {
    final numero = double.tryParse(valor.toString()) ?? 0;
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 0,
    );

    return formato.format(numero);
  }

  List<QueryDocumentSnapshot> filtrarServicios(
      List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final servicio = doc.data() as Map<String, dynamic>;
      final texto = [
        servicio['nombre'],
        servicio['descripcion'],
        servicio['precio'],
      ].join(' ').toLowerCase();

      return texto.contains(busqueda.toLowerCase());
    }).toList();
  }

  Widget encabezado(int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1565C0),
            Color(0xFF29B6F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.design_services_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Servicios',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$total soluciones disponibles',
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

  Widget buscador() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: buscarController,
        onChanged: (value) {
          setState(() {
            busqueda = value;
          });
        },
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Buscar servicio...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget tarjetaServicio({
    required String id,
    required Map<String, dynamic> servicio,
  }) {
    final nombre = servicio['nombre'] ?? 'Sin nombre';
    final descripcion = servicio['descripcion'] ?? 'Sin descripción';
    final precio = servicio['precio'] ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarServicioPantalla(
              servicioId: id,
              servicio: servicio,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            LogoServicio(
              logoBase64: servicio['logoBase64']?.toString(),
              size: 50,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      formatoLempiras(precio),
                      style: GoogleFonts.poppins(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget vacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.design_services_outlined,
                color: Color(0xFF1565C0),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No hay servicios',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Agrega el primer servicio para cotizarlo en ventas.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
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
          'Servicios',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nuevo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AgregarServicioPantalla(),
            ),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('servicios').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todos = snapshot.data!.docs;
          final servicios = filtrarServicios(todos);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              encabezado(todos.length),
              const SizedBox(height: 16),
              buscador(),
              const SizedBox(height: 16),
              if (servicios.isEmpty)
                SizedBox(height: 280, child: vacio())
              else
                ...servicios.map((doc) {
                  final servicio = doc.data() as Map<String, dynamic>;
                  return tarjetaServicio(id: doc.id, servicio: servicio);
                }),
            ],
          );
        },
      ),
    );
  }
}
