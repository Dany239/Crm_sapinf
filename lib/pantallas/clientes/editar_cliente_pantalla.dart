import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/seleccionar_servicios_pantalla.dart';
import '../../viewmodels/editar_cliente_viewmodel.dart';

class EditarClientePantalla extends StatefulWidget {
  final String clienteId;
  final Map<String, dynamic> cliente;

  const EditarClientePantalla({
    super.key,
    required this.clienteId,
    required this.cliente,
  });

  @override
  State<EditarClientePantalla> createState() => _EditarClientePantallaState();
}

class _EditarClientePantallaState extends State<EditarClientePantalla> {
  late final EditarClienteViewModel viewModel;
  late final TextEditingController nombreController;
  late final TextEditingController telefonoController;
  late final TextEditingController correoController;
  late final TextEditingController empresaController;
  late final TextEditingController direccionController;

  @override
  void initState() {
    super.initState();
    viewModel = EditarClienteViewModel(
      clienteId: widget.clienteId,
      cliente: widget.cliente,
    );
    nombreController = TextEditingController(
      text: widget.cliente['nombre']?.toString() ?? '',
    );
    telefonoController = TextEditingController(
      text: widget.cliente['telefono']?.toString() ?? '',
    );
    correoController = TextEditingController(
      text: widget.cliente['correo']?.toString() ?? '',
    );
    empresaController = TextEditingController(
      text: widget.cliente['empresa']?.toString() ?? '',
    );
    direccionController = TextEditingController(
      text: widget.cliente['direccion']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    nombreController.dispose();
    telefonoController.dispose();
    correoController.dispose();
    empresaController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  Future<void> actualizarCliente() async {
    final actualizado = await viewModel.actualizarCliente(
      nombre: nombreController.text,
      telefono: telefonoController.text,
      correo: correoController.text,
      empresa: empresaController.text,
      direccion: direccionController.text,
    );

    if (!mounted) return;

    if (!actualizado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo actualizar el cliente',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente actualizado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> eliminarCliente() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eliminar cliente',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Seguro que deseas eliminar este cliente? Esta acción no se puede deshacer.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Eliminar',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final eliminado = await viewModel.eliminarCliente();

    if (!mounted) return;

    if (!eliminado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo eliminar el cliente',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente eliminado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> seleccionarServicios() async {
    final resultado = await Navigator.push<List<Map<String, String>>>(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarServiciosPantalla(
          seleccionInicial: viewModel.serviciosSeleccionados,
        ),
      ),
    );

    if (resultado != null && mounted) {
      viewModel.actualizarServicios(resultado);
    }
  }

  InputDecoration campoDecoracion({
    required String label,
    required IconData icono,
  }) {
    return InputDecoration(
      labelText: label,
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
      labelStyle: GoogleFonts.poppins(
        color: Colors.grey.shade600,
        fontSize: 13,
      ),
    );
  }

  Widget selectorServicios() {
    final serviciosSeleccionados = viewModel.serviciosSeleccionados;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: seleccionarServicios,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF1565C0)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Servicios de interés',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF10245A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    serviciosSeleccionados.isEmpty
                        ? 'Seleccionar uno o varios servicios'
                        : serviciosSeleccionados
                              .map((servicio) => servicio['nombre'])
                              .join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget encabezadoCliente() {
    final estadoCliente = viewModel.clienteOriginal.estadoCliente;
    final esCliente = estadoCliente == 'Cliente';
    final estadoColor = esCliente ? Colors.green : Colors.orange;

    return Container(
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              esCliente ? Icons.verified_user : Icons.person_add,
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
                  nombreController.text.trim().isEmpty
                      ? 'Cliente'
                      : nombreController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empresaController.text.trim().isEmpty
                      ? 'Sin empresa'
                      : empresaController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    estadoCliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: estadoColor.shade700,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
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
              'Editar Cliente',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Tooltip(
                  message: 'Eliminar cliente',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: viewModel.eliminando ? null : eliminarCliente,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.18),
                        ),
                      ),
                      child: viewModel.eliminando
                          ? const Padding(
                              padding: EdgeInsets.all(11),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.red,
                              ),
                            )
                          : const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 23,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            child: Column(
              children: [
                encabezadoCliente(),
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
                      TextField(
                        controller: nombreController,
                        decoration: campoDecoracion(
                          label: 'Nombre',
                          icono: Icons.person,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: campoDecoracion(
                          label: 'Teléfono',
                          icono: Icons.phone,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: campoDecoracion(
                          label: 'Correo',
                          icono: Icons.email,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: empresaController,
                        decoration: campoDecoracion(
                          label: 'Empresa',
                          icono: Icons.business,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: direccionController,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: campoDecoracion(
                          label: 'Dirección',
                          icono: Icons.location_on_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      selectorServicios(),
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
                    onPressed: viewModel.cargando ? null : actualizarCliente,
                    child: viewModel.cargando
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
                                'Guardar cambios',
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
      },
    );
  }
}
