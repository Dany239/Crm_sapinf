import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cliente_model.dart';
import '../../viewmodels/agregar_venta_viewmodel.dart';

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
  final descripcionController = TextEditingController();
  final montoController = TextEditingController();
  late final AgregarVentaViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AgregarVentaViewModel(
      clienteIdInicial: widget.clienteIdInicial,
      clienteNombreInicial: widget.clienteNombreInicial,
    );
  }

  Future<void> guardarVenta() async {
    final guardado = await viewModel.guardarVenta(
      descripcion: descripcionController.text,
      monto: montoController.text,
    );

    if (!mounted) return;

    if (!guardado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo guardar la venta',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Venta guardada correctamente')),
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    viewModel.dispose();
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
        initialValue: viewModel.clienteNombreSeleccionado ?? 'Sin nombre',
        readOnly: true,
        decoration: campoDecoracion(label: 'Cliente', icono: Icons.person),
      );
    }

    return StreamBuilder<List<ClienteModel>>(
      stream: viewModel.clientesDisponiblesStream,
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
            hintText: clientes.isEmpty ? 'No hay clientes disponibles' : null,
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
  }

  Widget encabezadoVenta() {
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
                        initialValue: viewModel.servicioSeleccionado,
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
                          if (value == null) return;
                          viewModel.seleccionarServicio(value);
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
                        initialValue: viewModel.estadoSeleccionado,
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
                          if (value == null) return;
                          viewModel.seleccionarEstado(value);
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
                    onPressed: viewModel.cargando ? null : guardarVenta,
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
      },
    );
  }
}
