import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/sesion_usuario.dart';
import '../../servicios/notificaciones_servicio.dart';

class AgregarVentaPantalla extends StatefulWidget {
  final String? clienteIdInicial;
  final String? clienteNombreInicial;

  const AgregarVentaPantalla({
    super.key,
    this.clienteIdInicial,
    this.clienteNombreInicial,
  });

  @override
  State<AgregarVentaPantalla> createState() => _AgregarVentaPantallaState();
}

class _AgregarVentaPantallaState extends State<AgregarVentaPantalla> {
  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  final descripcionController = TextEditingController();
  final montoController = TextEditingController();

  String servicioSeleccionado = 'Desarrollo de software';
  String estadoSeleccionado = 'Pendiente';
  late Future<SesionUsuario> sesionFuture;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    clienteIdSeleccionado = widget.clienteIdInicial;
    clienteNombreSeleccionado = widget.clienteNombreInicial;
    sesionFuture = obtenerSesionUsuario();
  }

  Future<void> guardarVenta() async {
    if (clienteIdSeleccionado == null || montoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente y monto son obligatorios')),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    final sesion = await obtenerSesionUsuario();

    final referencia =
        await FirebaseFirestore.instance.collection('ventas').add({
      'clienteId': clienteIdSeleccionado,
      'cliente': clienteNombreSeleccionado,
      'servicio': servicioSeleccionado,
      'descripcion': descripcionController.text.trim(),
      'monto': montoController.text.trim(),
      'estado': estadoSeleccionado,
      ...datosPropietario(sesion),
      'fechaRegistro': FieldValue.serverTimestamp(),
    });

    await NotificacionesServicio.crear(
      titulo: 'Nueva venta registrada',
      descripcion:
          '${sesion.nombre} registr\u00f3 una venta para $clienteNombreSeleccionado por L. ${montoController.text.trim()}.',
      tipo: 'venta',
      icono: 'attach_money',
      color: 'green',
      autor: sesion,
      usuariosDestinatarios: [sesion.uid],
      referenciaId: referencia.id,
      referenciaColeccion: 'ventas',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venta guardada correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    descripcionController.dispose();
    montoController.dispose();
    super.dispose();
  }

  InputDecoration campoDecoracion({
    required String label,
    required IconData icono,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icono, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF1565C0),
          width: 1.4,
        ),
      ),
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
    );
  }

  Widget opcionDesplegable({
    required IconData icono,
    required String texto,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(
            icono,
            color: color,
            size: 19,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> opcionServicio(String value) {
    switch (value) {
      case 'Sistema web':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.language,
            texto: value,
            color: Colors.indigo,
          ),
        );
      case 'Aplicación móvil':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.phone_android,
            texto: value,
            color: Colors.teal,
          ),
        );
      case 'Soporte técnico':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.support_agent,
            texto: value,
            color: Colors.orange,
          ),
        );
      case 'Equipo informático':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.devices,
            texto: value,
            color: Colors.deepPurple,
          ),
        );
      default:
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.code,
            texto: value,
            color: const Color(0xFF1565C0),
          ),
        );
    }
  }

  DropdownMenuItem<String> opcionEstado(String value) {
    switch (value) {
      case 'En proceso':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.sync,
            texto: value,
            color: const Color(0xFF1565C0),
          ),
        );
      case 'Cerrada':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.check_circle,
            texto: value,
            color: Colors.green,
          ),
        );
      case 'Cancelada':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.cancel,
            texto: value,
            color: Colors.red,
          ),
        );
      default:
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.schedule,
            texto: value,
            color: Colors.orange,
          ),
        );
    }
  }

  Widget selectorCliente() {
    if (widget.clienteIdInicial != null) {
      return TextFormField(
        initialValue: clienteNombreSeleccionado ?? 'Sin nombre',
        readOnly: true,
        decoration: campoDecoracion(
          label: 'Cliente',
          icono: Icons.person,
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        return FutureBuilder<SesionUsuario>(
          future: sesionFuture,
          builder: (context, sesionSnapshot) {
            if (!sesionSnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            final sesion = sesionSnapshot.data!;
            final clientes = snapshot.data!.docs.where((doc) {
              final cliente = doc.data() as Map<String, dynamic>;
              final estadoCliente =
                  cliente['estadoCliente']?.toString() ?? 'Cliente potencial';
              final pertenece =
                  sesion.esAdministrador || cliente['vendedorId'] == sesion.uid;

              return pertenece && estadoCliente == 'Cliente';
            }).toList();

            return DropdownButtonFormField<String>(
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(18),
              menuMaxHeight: 320,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              initialValue:
                  clientes.any((doc) => doc.id == clienteIdSeleccionado)
                      ? clienteIdSeleccionado
                      : null,
              decoration: campoDecoracion(
                label: 'Cliente',
                icono: Icons.person,
                hintText:
                    clientes.isEmpty ? 'No hay clientes disponibles' : null,
              ),
              items: clientes.map((doc) {
                final cliente = doc.data() as Map<String, dynamic>;

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: opcionDesplegable(
                    icono: Icons.person,
                    texto: cliente['nombre'] ?? 'Sin nombre',
                    color: const Color(0xFF1565C0),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                final clienteDoc = clientes.firstWhere(
                  (doc) => doc.id == value,
                );
                final cliente = clienteDoc.data() as Map<String, dynamic>;

                setState(() {
                  clienteIdSeleccionado = clienteDoc.id;
                  clienteNombreSeleccionado = cliente['nombre'] ?? '';
                });
              },
            );
          },
        );
      },
    );
  }

  Widget encabezadoVenta() {
    return Container(
      width: double.infinity,
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
        borderRadius: BorderRadius.circular(24),
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.point_of_sale,
              color: Colors.white,
              size: 31,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nueva venta',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registra un servicio y su monto',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1F2937),
        title: Text(
          'Agregar Venta',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          children: [
            encabezadoVenta(),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                  selectorCliente(),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    menuMaxHeight: 320,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    initialValue: servicioSeleccionado,
                    decoration: campoDecoracion(
                      label: 'Servicio',
                      icono: Icons.design_services,
                    ),
                    items: [
                      opcionServicio('Desarrollo de software'),
                      opcionServicio('Sistema web'),
                      opcionServicio('Aplicación móvil'),
                      opcionServicio('Soporte técnico'),
                      opcionServicio('Equipo informático'),
                    ],
                    onChanged: (value) {
                      setState(() {
                        servicioSeleccionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descripcionController,
                    maxLines: 3,
                    decoration: campoDecoracion(
                      label: 'Descripción',
                      icono: Icons.notes,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    decoration: campoDecoracion(
                      label: 'Monto',
                      icono: Icons.payments,
                      hintText: 'Ej. 25000',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    menuMaxHeight: 280,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    initialValue: estadoSeleccionado,
                    decoration: campoDecoracion(
                      label: 'Estado',
                      icono: Icons.flag,
                    ),
                    items: [
                      opcionEstado('Pendiente'),
                      opcionEstado('En proceso'),
                      opcionEstado('Cerrada'),
                      opcionEstado('Cancelada'),
                    ],
                    onChanged: (value) {
                      setState(() {
                        estadoSeleccionado = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                onPressed: cargando ? null : guardarVenta,
                child: cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Guardar venta',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
