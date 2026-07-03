import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/sesion_usuario.dart';
import '../../servicios/notificaciones_servicio.dart';

class EditarSeguimientoPantalla extends StatefulWidget {
  final String seguimientoId;
  final Map<String, dynamic> seguimiento;

  const EditarSeguimientoPantalla({
    super.key,
    required this.seguimientoId,
    required this.seguimiento,
  });

  @override
  State<EditarSeguimientoPantalla> createState() =>
      _EditarSeguimientoPantallaState();
}

class _EditarSeguimientoPantallaState extends State<EditarSeguimientoPantalla> {
  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  late TextEditingController comentarioController;
  late TextEditingController proximaGestionController;

  late String tipoSeleccionado;
  late String estadoSeleccionado;
  DateTime? fechaProximaSeleccionada;
  late Future<SesionUsuario> sesionFuture;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    sesionFuture = obtenerSesionUsuario();

    clienteIdSeleccionado = widget.seguimiento['clienteId'];
    clienteNombreSeleccionado = widget.seguimiento['cliente'];

    comentarioController = TextEditingController(
      text: widget.seguimiento['comentario'] ?? '',
    );

    final fechaProxima = widget.seguimiento['fechaProxima'];
    if (fechaProxima is Timestamp) {
      fechaProximaSeleccionada = fechaProxima.toDate();
    } else {
      fechaProximaSeleccionada = fechaDesdeTexto(
        widget.seguimiento['proximaGestion']?.toString() ?? '',
      );
    }

    proximaGestionController = TextEditingController(
      text: fechaProximaSeleccionada == null
          ? widget.seguimiento['proximaGestion'] ?? ''
          : textoFecha(fechaProximaSeleccionada!),
    );

    tipoSeleccionado = normalizarTipo(
      widget.seguimiento['tipo'] ?? 'Llamada',
    );
    estadoSeleccionado = widget.seguimiento['estado'] ?? 'Pendiente';
  }

  String normalizarTipo(String tipo) {
    if (tipo.toLowerCase().contains('reuni')) return 'Reunión';
    return tipo;
  }

  String textoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} $hora:$minuto';
  }

  DateTime? fechaDesdeTexto(String texto) {
    final secciones = texto.trim().split(' ');
    final partes = secciones.first.split('/');

    if (partes.length != 3) return null;

    final dia = int.tryParse(partes[0]);
    final mes = int.tryParse(partes[1]);
    final anio = int.tryParse(partes[2]);

    if (dia == null || mes == null || anio == null) return null;

    var hora = 0;
    var minuto = 0;
    if (secciones.length > 1) {
      final partesHora = secciones[1].split(':');
      hora = int.tryParse(partesHora.first) ?? 0;
      if (partesHora.length > 1) {
        minuto = int.tryParse(partesHora[1]) ?? 0;
      }
    }

    return DateTime(anio, mes, dia, hora, minuto);
  }

  Future<void> seleccionarFechaProxima() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaProximaSeleccionada ?? ahora,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 3),
      helpText: 'Selecciona la próxima gestión',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fecha == null) return;

    if (!mounted) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        fechaProximaSeleccionada ?? DateTime.now(),
      ),
      helpText: 'Selecciona la hora',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );
    if (hora == null) return;

    final fechaConHora = DateTime(
      fecha.year,
      fecha.month,
      fecha.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      fechaProximaSeleccionada = fechaConHora;
      proximaGestionController.text = textoFecha(fechaConHora);
    });
  }

  Future<void> actualizarSeguimiento() async {
    setState(() {
      cargando = true;
    });

    final sesion = await obtenerSesionUsuario();
    final yaRealizado = widget.seguimiento['fechaRealizacion'] is Timestamp;
    final estadoAnterior =
        widget.seguimiento['estado']?.toString() ?? 'Pendiente';

    await FirebaseFirestore.instance
        .collection('seguimientos')
        .doc(widget.seguimientoId)
        .update({
      'clienteId': clienteIdSeleccionado,
      'cliente': clienteNombreSeleccionado,
      'tipo': tipoSeleccionado,
      'comentario': comentarioController.text.trim(),
      'resultado': comentarioController.text.trim(),
      'proximaGestion': proximaGestionController.text.trim(),
      'fechaProxima': fechaProximaSeleccionada == null
          ? null
          : Timestamp.fromDate(fechaProximaSeleccionada!),
      'estado': estadoSeleccionado,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      'fechaRealizacion': estadoSeleccionado == 'Realizado' && !yaRealizado
          ? FieldValue.serverTimestamp()
          : widget.seguimiento['fechaRealizacion'],
      'actualizadoPorId': sesion.uid,
      'actualizadoPorNombre': sesion.nombre,
      'evidenciaTipo': widget.seguimiento['evidenciaTipo'] ?? 'Registro manual',
    });

    if (estadoAnterior != estadoSeleccionado) {
      await NotificacionesServicio.crear(
        titulo: 'Seguimiento $estadoSeleccionado',
        descripcion:
            '${sesion.nombre} marc\u00f3 $tipoSeleccionado con $clienteNombreSeleccionado como $estadoSeleccionado.',
        tipo: 'seguimiento_estado',
        icono: tipoSeleccionado == 'Correo' ? 'notifications' : 'phone',
        color: estadoSeleccionado == 'Realizado'
            ? 'green'
            : estadoSeleccionado == 'Cancelado'
                ? 'red'
                : 'orange',
        autor: sesion,
        usuariosDestinatarios: [
          widget.seguimiento['vendedorId']?.toString() ?? '',
          sesion.uid,
        ],
        referenciaId: widget.seguimientoId,
        referenciaColeccion: 'seguimientos',
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seguimiento actualizado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> eliminarSeguimiento() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Eliminar seguimiento',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '¿Seguro que deseas eliminar este seguimiento?',
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
      await FirebaseFirestore.instance
          .collection('seguimientos')
          .doc(widget.seguimientoId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seguimiento eliminado correctamente')),
      );

      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    comentarioController.dispose();
    proximaGestionController.dispose();
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
      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
      prefixIcon: Icon(icono, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
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
        borderSide: const BorderSide(
          color: Color(0xFF1565C0),
          width: 1.5,
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
              Icons.edit_calendar_rounded,
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
                  'Editar gestión',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Actualiza el estado y la próxima acción del cliente.',
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  DropdownMenuItem<String> opcionTipo(String tipo) {
    switch (tipo) {
      case 'Reunión':
        return DropdownMenuItem(
          value: tipo,
          child: opcionDesplegable(
            icono: Icons.groups_rounded,
            texto: tipo,
            color: Colors.deepPurple,
          ),
        );
      case 'Correo':
        return DropdownMenuItem(
          value: tipo,
          child: opcionDesplegable(
            icono: Icons.email_rounded,
            texto: tipo,
            color: Colors.teal,
          ),
        );
      case 'Mensaje':
        return DropdownMenuItem(
          value: tipo,
          child: opcionDesplegable(
            icono: Icons.message_rounded,
            texto: tipo,
            color: Colors.indigo,
          ),
        );
      case 'Visita':
        return DropdownMenuItem(
          value: tipo,
          child: opcionDesplegable(
            icono: Icons.location_on_rounded,
            texto: tipo,
            color: Colors.orange,
          ),
        );
      default:
        return DropdownMenuItem(
          value: tipo,
          child: opcionDesplegable(
            icono: Icons.phone_rounded,
            texto: tipo,
            color: const Color(0xFF1565C0),
          ),
        );
    }
  }

  DropdownMenuItem<String> opcionEstado(String estado) {
    final color = estado == 'Realizado'
        ? Colors.green
        : estado == 'Cancelado'
            ? Colors.red
            : Colors.orange;

    return DropdownMenuItem(
      value: estado,
      child: opcionDesplegable(
        icono: Icons.flag_rounded,
        texto: estado,
        color: color,
      ),
    );
  }

  Widget campoCliente() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('clientes').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 58,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        return FutureBuilder<SesionUsuario>(
          future: sesionFuture,
          builder: (context, sesionSnapshot) {
            if (!sesionSnapshot.hasData) {
              return Container(
                height: 58,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              );
            }

            final sesion = sesionSnapshot.data!;
            final clientes = snapshot.data!.docs.where((doc) {
              final cliente = doc.data() as Map<String, dynamic>;
              return sesion.esAdministrador ||
                  cliente['vendedorId'] == sesion.uid;
            }).toList();

            return DropdownButtonFormField<String>(
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(18),
              menuMaxHeight: 280,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              initialValue:
                  clientes.any((doc) => doc.id == clienteIdSeleccionado)
                      ? clienteIdSeleccionado
                      : null,
              decoration: campoDecoracion(
                label: 'Cliente',
                icono: Icons.person_rounded,
                hintText:
                    clientes.isEmpty ? 'No hay clientes disponibles' : null,
              ),
              items: clientes.map((doc) {
                final cliente = doc.data() as Map<String, dynamic>;
                final nombre = cliente['nombre'] ?? 'Sin nombre';

                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: opcionDesplegable(
                    icono: Icons.person_rounded,
                    texto: nombre,
                    color: const Color(0xFF1565C0),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                final clienteDoc =
                    clientes.firstWhere((doc) => doc.id == value);
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

  Widget botonGuardar() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: cargando ? null : actualizarSeguimiento,
        icon: cargando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded),
        label: Text(
          cargando ? 'Guardando...' : 'Guardar cambios',
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

  Widget botonEliminar() {
    return IconButton(
      tooltip: 'Eliminar seguimiento',
      onPressed: eliminarSeguimiento,
      icon: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.red,
          size: 22,
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
          'Editar Seguimiento',
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
                  campoCliente(),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    menuMaxHeight: 260,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    initialValue: tipoSeleccionado,
                    decoration: campoDecoracion(
                      label: 'Tipo de seguimiento',
                      icono: Icons.route_rounded,
                    ),
                    items: [
                      opcionTipo('Llamada'),
                      opcionTipo('Reunión'),
                      opcionTipo('Correo'),
                      opcionTipo('Mensaje'),
                      opcionTipo('Visita'),
                    ],
                    onChanged: (value) {
                      setState(() {
                        tipoSeleccionado = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: comentarioController,
                    maxLines: 4,
                    style: GoogleFonts.poppins(),
                    decoration: campoDecoracion(
                      label: 'Resultado u observaci\u00f3n',
                      icono: Icons.notes_rounded,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: proximaGestionController,
                    readOnly: true,
                    onTap: seleccionarFechaProxima,
                    style: GoogleFonts.poppins(),
                    decoration: campoDecoracion(
                      label: 'Próxima gestión',
                      icono: Icons.event_rounded,
                      hintText: 'Selecciona una fecha',
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    menuMaxHeight: 240,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    initialValue: estadoSeleccionado,
                    decoration: campoDecoracion(
                      label: 'Estado',
                      icono: Icons.flag_rounded,
                    ),
                    items: [
                      opcionEstado('Pendiente'),
                      opcionEstado('Realizado'),
                      opcionEstado('Cancelado'),
                    ],
                    onChanged: (value) {
                      setState(() {
                        estadoSeleccionado = value!;
                      });
                    },
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
