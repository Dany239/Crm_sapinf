import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../servicios/seleccionar_servicios_pantalla.dart';
import '../../viewmodels/agregar_cliente_viewmodel.dart';

class AgregarClientePantalla extends StatefulWidget {
  const AgregarClientePantalla({super.key});

  @override
  State<AgregarClientePantalla> createState() => _AgregarClientePantallaState();
}

class _AgregarClientePantallaState extends State<AgregarClientePantalla> {
  final nombreController = TextEditingController();
  final telefonoController = TextEditingController();
  final correoController = TextEditingController();
  final empresaController = TextEditingController();
  final direccionController = TextEditingController();
  late final AgregarClienteViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = AgregarClienteViewModel();
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

  Future<void> guardarCliente() async {
    final guardado = await viewModel.guardarCliente(
      nombre: nombreController.text,
      telefono: telefonoController.text,
      correo: correoController.text,
      empresa: empresaController.text,
      direccion: direccionController.text,
    );

    if (!mounted) return;

    if (!guardado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo guardar el cliente potencial',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente potencial guardado correctamente')),
    );

    Navigator.pop(context);
  }

  Future<void> seleccionarContacto() async {
    try {
      final permiso = await FlutterContacts.permissions.request(
        PermissionType.read,
      );

      if (permiso != PermissionStatus.granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Autoriza el acceso a contactos para seleccionar una persona.',
            ),
          ),
        );
        return;
      }

      final contacto = await FlutterContacts.native.showPicker(
        properties: const {
          ContactProperty.name,
          ContactProperty.phone,
          ContactProperty.email,
          ContactProperty.address,
          ContactProperty.organization,
        },
      );
      if (contacto == null || !mounted) return;

      setState(() {
        final nombre = contacto.displayName?.trim() ?? '';
        if (nombre.isNotEmpty) nombreController.text = nombre;
        if (contacto.phones.isNotEmpty) {
          telefonoController.text = contacto.phones.first.number;
        }
        if (contacto.emails.isNotEmpty) {
          correoController.text = contacto.emails.first.address;
        }
        if (contacto.addresses.isNotEmpty) {
          direccionController.text =
              contacto.addresses.first.formatted?.trim() ?? '';
        }
        if (contacto.organizations.isNotEmpty) {
          final empresa = contacto.organizations.first.name?.trim() ?? '';
          if (empresa.isNotEmpty) empresaController.text = empresa;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir los contactos')),
      );
    }
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
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icono, color: const Color(0xFF1565C0)),
      suffixIcon: suffixIcon,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Servicios de interés',
              style: GoogleFonts.poppins(
                color: const Color(0xFF10245A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviciosSeleccionados.isEmpty
                            ? 'Seleccionar servicios'
                            : '${serviciosSeleccionados.length} seleccionado(s)',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF10245A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        serviciosSeleccionados.isEmpty
                            ? 'Elige uno o varios del catálogo'
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
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF1565C0),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget encabezadoCliente() {
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
              Icons.person_add_alt_1,
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
                  'Nuevo potencial',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Registra los datos del prospecto',
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
                    'Cliente potencial',
                    style: GoogleFonts.poppins(
                      color: Colors.orange.shade700,
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
              'Agregar Cliente potencial',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
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
                          hintText: 'Nombre del prospecto',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: campoDecoracion(
                          label: 'Teléfono',
                          icono: Icons.phone,
                          suffixIcon: IconButton(
                            tooltip: 'Seleccionar contacto',
                            onPressed: seleccionarContacto,
                            icon: const Icon(
                              Icons.contacts_rounded,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          hintText: 'Número de contacto',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: campoDecoracion(
                          label: 'Correo',
                          icono: Icons.email,
                          hintText: 'correo@empresa.com',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: empresaController,
                        decoration: campoDecoracion(
                          label: 'Empresa',
                          icono: Icons.business,
                          hintText: 'Nombre de la empresa',
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
                          hintText: 'Dirección del cliente potencial',
                        ),
                      ),
                      const SizedBox(height: 18),
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
                    onPressed: viewModel.cargando ? null : guardarCliente,
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
                                'Guardar cliente potencial',
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
