import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/sesion_usuario.dart';
import '../../servicios/notificaciones_servicio.dart';

class AgregarSeguimientoPantalla extends StatefulWidget {
  final String? clienteIdInicial;
  final String? clienteNombreInicial;

  const AgregarSeguimientoPantalla({
    super.key,
    this.clienteIdInicial,
    this.clienteNombreInicial,
  });

  @override
  State<AgregarSeguimientoPantalla> createState() =>
      _AgregarSeguimientoPantallaState();
}

class _AgregarSeguimientoPantallaState
    extends State<AgregarSeguimientoPantalla> {
  String? clienteIdSeleccionado;
  String? clienteNombreSeleccionado;
  final comentarioController = TextEditingController();
  final proximaGestionController = TextEditingController();
  DateTime? fechaProximaSeleccionada;

  String tipoSeleccionado = 'Llamada';
  String estadoSeleccionado = 'Realizado';
  late Future<SesionUsuario> sesionFuture;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    clienteIdSeleccionado = widget.clienteIdInicial;
    clienteNombreSeleccionado = widget.clienteNombreInicial;
    sesionFuture = obtenerSesionUsuario();
  }

  Future<void> guardarSeguimiento() async {
    if (clienteIdSeleccionado == null ||
        comentarioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Cliente y resultado u observaci\u00f3n son obligatorios'),
        ),
      );
      return;
    }

    setState(() {
      cargando = true;
    });

    final sesion = await obtenerSesionUsuario();

    final referencia =
        await FirebaseFirestore.instance.collection('seguimientos').add({
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
      ...datosPropietario(sesion),
      'fechaRegistro': FieldValue.serverTimestamp(),
      'fechaRealizacion': estadoSeleccionado == 'Realizado'
          ? FieldValue.serverTimestamp()
          : null,
      'evidenciaTipo': 'Registro manual',
    });

    await NotificacionesServicio.crear(
      titulo: estadoSeleccionado == 'Realizado'
          ? 'Seguimiento realizado'
          : 'Seguimiento programado',
      descripcion:
          '${sesion.nombre} registr\u00f3 $tipoSeleccionado con $clienteNombreSeleccionado como $estadoSeleccionado.',
      tipo: 'seguimiento',
      icono: tipoSeleccionado == 'Correo' ? 'notifications' : 'phone',
      color: 'orange',
      autor: sesion,
      usuariosDestinatarios: [sesion.uid],
      referenciaId: referencia.id,
      referenciaColeccion: 'seguimientos',
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seguimiento guardado correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    comentarioController.dispose();
    proximaGestionController.dispose();
    super.dispose();
  }

  String textoFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/${fecha.year} $hora:$minuto';
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

  DropdownMenuItem<String> opcionTipo(String value) {
    switch (value) {
      case 'Llamada':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.phone,
            texto: value,
            color: const Color(0xFF1565C0),
          ),
        );
      case 'Reunión':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.groups,
            texto: value,
            color: Colors.deepPurple,
          ),
        );
      case 'Correo':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.email,
            texto: value,
            color: Colors.teal,
          ),
        );
      case 'Mensaje':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.message_rounded,
            texto: value,
            color: Colors.indigo,
          ),
        );
      default:
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.location_on,
            texto: value,
            color: Colors.orange,
          ),
        );
    }
  }

  DropdownMenuItem<String> opcionEstado(String value) {
    switch (value) {
      case 'Realizado':
        return DropdownMenuItem(
          value: value,
          child: opcionDesplegable(
            icono: Icons.check_circle,
            texto: value,
            color: Colors.green,
          ),
        );
      case 'Cancelado':
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

  Widget campoCliente() {
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
              return sesion.esAdministrador ||
                  cliente['vendedorId'] == sesion.uid;
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
          'Agregar Seguimiento',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Icons.phone_in_talk,
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
                          'Nueva gestión',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Registra el próximo paso con este cliente potencial.',
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
                      icono: Icons.route,
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
                    decoration: campoDecoracion(
                      label: 'Resultado u observaci\u00f3n',
                      icono: Icons.notes,
                      hintText: 'Describe lo conversado o el acuerdo pendiente',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: proximaGestionController,
                    readOnly: true,
                    onTap: seleccionarFechaProxima,
                    decoration: campoDecoracion(
                      label: 'Próxima gestión',
                      icono: Icons.event,
                      hintText: 'Selecciona fecha y hora',
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
                      icono: Icons.flag,
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
                onPressed: cargando ? null : guardarSeguimiento,
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
                        'Guardar seguimiento',
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
