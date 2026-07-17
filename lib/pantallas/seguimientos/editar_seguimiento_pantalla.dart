import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cliente_model.dart';
import '../../viewmodels/editar_seguimiento_viewmodel.dart';

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
  late final EditarSeguimientoViewModel viewModel;
  late final TextEditingController comentarioController;
  late final TextEditingController proximaGestionController;

  @override
  void initState() {
    super.initState();
    viewModel = EditarSeguimientoViewModel(
      seguimientoId: widget.seguimientoId,
      seguimiento: widget.seguimiento,
    );
    comentarioController = TextEditingController(
      text: widget.seguimiento['comentario']?.toString() ?? '',
    );
    proximaGestionController = TextEditingController(
      text: viewModel.fechaProximaSeleccionada == null
          ? widget.seguimiento['proximaGestion']?.toString() ?? ''
          : viewModel.textoFecha(viewModel.fechaProximaSeleccionada!),
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    comentarioController.dispose();
    proximaGestionController.dispose();
    super.dispose();
  }

  Future<void> seleccionarFechaProxima() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: viewModel.fechaProximaSeleccionada ?? ahora,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 3),
      helpText: 'Selecciona la próxima gestión',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (fecha == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        viewModel.fechaProximaSeleccionada ?? DateTime.now(),
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

    viewModel.seleccionarFechaProxima(fechaConHora);
    proximaGestionController.text = viewModel.textoFecha(fechaConHora);
  }

  Future<void> actualizarSeguimiento() async {
    final actualizado = await viewModel.actualizarSeguimiento(
      comentario: comentarioController.text,
      proximaGestion: proximaGestionController.text,
    );

    if (!mounted) return;

    if (!actualizado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo actualizar el seguimiento',
          ),
        ),
      );
      return;
    }

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

    if (confirmar != true) return;

    final eliminado = await viewModel.eliminarSeguimiento();

    if (!mounted) return;

    if (!eliminado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo eliminar el seguimiento',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seguimiento eliminado correctamente')),
    );

    Navigator.pop(context);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    return StreamBuilder<List<ClienteModel>>(
      stream: viewModel.clientesDisponiblesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 58,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        }

        final clientes = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(18),
          menuMaxHeight: 280,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          initialValue:
              clientes.any(
                (cliente) => cliente.id == viewModel.clienteIdSeleccionado,
              )
              ? viewModel.clienteIdSeleccionado
              : null,
          decoration: campoDecoracion(
            label: 'Cliente',
            icono: Icons.person_rounded,
            hintText: clientes.isEmpty ? 'No hay clientes disponibles' : null,
          ),
          items: clientes.map((cliente) {
            return DropdownMenuItem<String>(
              value: cliente.id,
              child: opcionDesplegable(
                icono: Icons.person_rounded,
                texto: cliente.nombre,
                color: const Color(0xFF1565C0),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            final cliente = clientes.firstWhere(
              (cliente) => cliente.id == value,
            );

            viewModel.seleccionarCliente(
              clienteId: cliente.id ?? '',
              clienteNombre: cliente.nombre,
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
        onPressed: viewModel.cargando ? null : actualizarSeguimiento,
        icon: viewModel.cargando
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
      tooltip: 'Eliminar seguimiento',
      onPressed: viewModel.eliminando ? null : eliminarSeguimiento,
      icon: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(15),
        ),
        child: viewModel.eliminando
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.red,
                ),
              )
            : const Icon(Icons.delete_rounded, color: Colors.red, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
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
                        initialValue: viewModel.tipoSeleccionado,
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
                          if (value == null) return;
                          viewModel.seleccionarTipo(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: comentarioController,
                        maxLines: 4,
                        style: GoogleFonts.poppins(),
                        decoration: campoDecoracion(
                          label: 'Resultado u observación',
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
                        initialValue: viewModel.estadoSeleccionado,
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
                          if (value == null) return;
                          viewModel.seleccionarEstado(value);
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
      },
    );
  }
}
