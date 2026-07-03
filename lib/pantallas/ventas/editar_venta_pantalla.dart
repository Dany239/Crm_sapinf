import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/sesion_usuario.dart';
import '../../servicios/notificaciones_servicio.dart';

class EditarVentaPantalla extends StatefulWidget {
  final String ventaId;
  final Map<String, dynamic> venta;

  const EditarVentaPantalla({
    super.key,
    required this.ventaId,
    required this.venta,
  });

  @override
  State<EditarVentaPantalla> createState() => _EditarVentaPantallaState();
}

class _EditarVentaPantallaState extends State<EditarVentaPantalla> {
  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  late TextEditingController descripcionController;
  late TextEditingController montoController;

  late String servicioSeleccionado;
  late String estadoSeleccionado;
  late Future<SesionUsuario> sesionFuture;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    sesionFuture = obtenerSesionUsuario();

    clienteIdSeleccionado = widget.venta['clienteId'];
    clienteNombreSeleccionado = widget.venta['cliente'];
    descripcionController =
        TextEditingController(text: widget.venta['descripcion'] ?? '');
    montoController = TextEditingController(text: widget.venta['monto'] ?? '');

    servicioSeleccionado = widget.venta['servicio'] ?? 'Desarrollo de software';
    estadoSeleccionado = widget.venta['estado'] ?? 'Pendiente';
  }

  Future<void> actualizarVenta() async {
    setState(() {
      cargando = true;
    });

    final sesion = await obtenerSesionUsuario();
    final estadoAnterior = widget.venta['estado']?.toString() ?? 'Pendiente';

    await FirebaseFirestore.instance
        .collection('ventas')
        .doc(widget.ventaId)
        .update({
      'clienteId': clienteIdSeleccionado,
      'cliente': clienteNombreSeleccionado,
      'servicio': servicioSeleccionado,
      'descripcion': descripcionController.text.trim(),
      'monto': montoController.text.trim(),
      'estado': estadoSeleccionado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
    });

    if (estadoAnterior != estadoSeleccionado) {
      await NotificacionesServicio.crear(
        titulo: 'Venta $estadoSeleccionado',
        descripcion:
            '${sesion.nombre} cambi\u00f3 la venta de $clienteNombreSeleccionado de $estadoAnterior a $estadoSeleccionado.',
        tipo: 'venta_estado',
        icono: 'attach_money',
        color: estadoSeleccionado == 'Cerrada'
            ? 'green'
            : estadoSeleccionado == 'Cancelada'
                ? 'red'
                : 'orange',
        autor: sesion,
        usuariosDestinatarios: [
          widget.venta['vendedorId']?.toString() ?? '',
          sesion.uid,
        ],
        referenciaId: widget.ventaId,
        referenciaColeccion: 'ventas',
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venta actualizada correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> eliminarVenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar venta'),
          content: const Text('¿Seguro que deseas eliminar esta venta?'),
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
          .collection('ventas')
          .doc(widget.ventaId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta eliminada correctamente')),
      );

      Navigator.pop(context);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1F2937),
        title: Text(
          'Editar Venta',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Tooltip(
              message: 'Eliminar venta',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: eliminarVenta,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          children: [
            Container(
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
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Actualizar venta',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ajusta el servicio, monto y estado de la oportunidad.',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.86),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                      icono: Icons.build_circle,
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
                    maxLines: 4,
                    decoration: campoDecoracion(
                      label: 'Descripción',
                      icono: Icons.description,
                      hintText: 'Describe el alcance o necesidad del cliente',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: montoController,
                    keyboardType: TextInputType.number,
                    decoration: campoDecoracion(
                      label: 'Monto',
                      icono: Icons.payments,
                      hintText: 'Ejemplo: 50000',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    menuMaxHeight: 260,
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
            const SizedBox(height: 18),
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
                onPressed: cargando ? null : actualizarVenta,
                child: cargando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Guardar cambios',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
