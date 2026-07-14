import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cliente_model.dart';
import '../../servicios/sesion_usuario.dart';
import '../../viewmodels/agregar_seguimiento_viewmodel.dart';

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
  final comentarioController = TextEditingController();
  final proximaGestionController = TextEditingController();
  late final AgregarSeguimientoViewModel viewModel;
  late final Future<SesionUsuario> sesionFuture;

  @override
  void initState() {
    super.initState();
    viewModel = AgregarSeguimientoViewModel(
      clienteIdInicial: widget.clienteIdInicial,
      clienteNombreInicial: widget.clienteNombreInicial,
    );
    sesionFuture = obtenerSesionUsuario();
  }

  @override
  void dispose() {
    viewModel.dispose();
    comentarioController.dispose();
    proximaGestionController.dispose();
    super.dispose();
  }

  Future<void> guardarSeguimiento() async {
    final guardado = await viewModel.guardarSeguimiento(
      comentario: comentarioController.text,
      proximaGestion: proximaGestionController.text,
    );

    if (!mounted) return;

    if (!guardado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo guardar el seguimiento',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seguimiento guardado correctamente')),
    );

    Navigator.pop(context);
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.4),
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
          child: Icon(icono, color: color, size: 19),
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
        initialValue: viewModel.clienteNombreSeleccionado ?? 'Sin nombre',
        readOnly: true,
        decoration: campoDecoracion(label: 'Cliente', icono: Icons.person),
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

        return StreamBuilder<List<ClienteModel>>(
          stream: viewModel.escucharClientesPorSesion(sesion),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }

            final clientes = snapshot.data ?? [];

            return DropdownButtonFormField<String>(
              isExpanded: true,
              dropdownColor: Colors.white,
              borderRadius: BorderRadius.circular(18),
              menuMaxHeight: 320,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              initialValue:
                  clientes.any(
                    (cliente) => cliente.id == viewModel.clienteIdSeleccionado,
                  )
                  ? viewModel.clienteIdSeleccionado
                  : null,
              decoration: campoDecoracion(
                label: 'Cliente',
                icono: Icons.person,
                hintText: clientes.isEmpty
                    ? 'No hay clientes disponibles'
                    : null,
              ),
              items: clientes.map((cliente) {
                return DropdownMenuItem<String>(
                  value: cliente.id,
                  child: opcionDesplegable(
                    icono: Icons.person,
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
      },
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
                      colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
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
                        initialValue: viewModel.tipoSeleccionado,
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
                          if (value == null) return;
                          viewModel.seleccionarTipo(value);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: comentarioController,
                        maxLines: 4,
                        decoration: campoDecoracion(
                          label: 'Resultado u observación',
                          icono: Icons.notes,
                          hintText:
                              'Describe lo conversado o el acuerdo pendiente',
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
                        initialValue: viewModel.estadoSeleccionado,
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
                          if (value == null) return;
                          viewModel.seleccionarEstado(value);
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
                    onPressed: viewModel.cargando ? null : guardarSeguimiento,
                    child: viewModel.cargando
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
      },
    );
  }
}
