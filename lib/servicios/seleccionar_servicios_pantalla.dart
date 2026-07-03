import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'logo_servicio.dart';

class SeleccionarServiciosPantalla extends StatefulWidget {
  final List<Map<String, String>> seleccionInicial;

  const SeleccionarServiciosPantalla({
    super.key,
    this.seleccionInicial = const [],
  });

  @override
  State<SeleccionarServiciosPantalla> createState() =>
      _SeleccionarServiciosPantallaState();
}

class _SeleccionarServiciosPantallaState
    extends State<SeleccionarServiciosPantalla> {
  final buscarController = TextEditingController();
  late final Map<String, Map<String, String>> seleccionados;
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    seleccionados = {
      for (final servicio in widget.seleccionInicial)
        if ((servicio['id'] ?? '').isNotEmpty) servicio['id']!: servicio,
    };
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  Map<String, String> convertirServicio(
    String id,
    Map<String, dynamic> datos,
  ) {
    return {
      'id': id,
      'nombre': datos['nombre']?.toString() ?? 'Sin nombre',
      'descripcion': datos['descripcion']?.toString() ?? '',
      'logoBase64': datos['logoBase64']?.toString() ?? '',
    };
  }

  void alternarServicio(Map<String, String> servicio) {
    final id = servicio['id']!;
    setState(() {
      if (seleccionados.containsKey(id)) {
        seleccionados.remove(id);
      } else {
        seleccionados[id] = servicio;
      }
    });
  }

  void confirmarSeleccion() {
    Navigator.pop(context, seleccionados.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F7FB),
        foregroundColor: const Color(0xFF10245A),
        title: Text(
          'Catálogo de servicios',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
            child: Column(
              children: [
                Text(
                  'Selecciona uno o varios servicios de interés',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF52648D),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: buscarController,
                  onChanged: (valor) => setState(() => busqueda = valor),
                  decoration: InputDecoration(
                    hintText: 'Buscar servicio...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('servicios').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('No se pudieron cargar los servicios'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final consulta = busqueda.trim().toLowerCase();
                final servicios = snapshot.data!.docs.where((doc) {
                  final datos = doc.data() as Map<String, dynamic>;
                  final texto =
                      '${datos['nombre'] ?? ''} ${datos['descripcion'] ?? ''}'
                          .toLowerCase();
                  return texto.contains(consulta);
                }).toList();

                if (servicios.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay servicios disponibles',
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  itemCount: servicios.length,
                  itemBuilder: (context, index) {
                    final doc = servicios[index];
                    final datos = doc.data() as Map<String, dynamic>;
                    final servicio = convertirServicio(doc.id, datos);
                    final seleccionado = seleccionados.containsKey(doc.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => alternarServicio(servicio),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: seleccionado
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey.shade200,
                                width: seleccionado ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                LogoServicio(
                                  logoBase64: servicio['logoBase64'],
                                  size: 54,
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        servicio['nombre']!,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF10245A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (servicio['descripcion']!.isNotEmpty)
                                        Text(
                                          servicio['descripcion']!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: const Color(0xFF52648D),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Checkbox(
                                  value: seleccionado,
                                  activeColor: const Color(0xFF1565C0),
                                  shape: const CircleBorder(),
                                  onChanged: (_) =>
                                      alternarServicio(servicio),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      seleccionados.isEmpty ? null : confirmarSeleccion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    seleccionados.isEmpty
                        ? 'Selecciona al menos uno'
                        : 'Seleccionar (${seleccionados.length})',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
