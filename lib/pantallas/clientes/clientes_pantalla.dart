import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'agregar_cliente_pantalla.dart';
import 'detalle_cliente_pantalla.dart';
import 'editar_cliente_pantalla.dart';
import '../../models/cliente_model.dart';
import '../../viewmodels/clientes_viewmodel.dart';

class ClientesPantalla extends StatefulWidget {
  final bool mostrarClientes;

  const ClientesPantalla({super.key, this.mostrarClientes = false});

  @override
  State<ClientesPantalla> createState() => _ClientesPantallaState();
}

class _ClientesPantallaState extends State<ClientesPantalla> {
  final buscarController = TextEditingController();
  late final ClientesViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ClientesViewModel(
      mostrarClientesInicial: widget.mostrarClientes,
    );
  }

  @override
  void dispose() {
    buscarController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  void abrirAgregarCliente() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AgregarClientePantalla()),
    );
  }

  Widget tabFiltro({
    required String texto,
    required IconData icono,
    required bool activo,
    required VoidCallback onTap,
  }) {
    final color = activo ? const Color(0xFF1565C0) : Colors.grey.shade600;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          decoration: BoxDecoration(
            color: activo ? const Color(0xFFE3F2FD) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activo ? const Color(0xFFBBDEFB) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 19, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  texto,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoLinea({required IconData icono, required String texto}) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icono, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tarjetaCliente({required ClienteModel cliente}) {
    final nombre = cliente.nombre;
    final telefono = cliente.telefono;
    final correo = cliente.correo;
    final empresa = cliente.empresa;
    final vendedor = cliente.vendedorNombre ?? 'Sin vendedor asignado';
    final estadoCliente = cliente.estadoCliente;
    final esCliente = estadoCliente == 'Cliente';
    final colorEstado = esCliente ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleClientePantalla(
                clienteId: cliente.id ?? '',
                cliente: cliente.toPlainMap(),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  esCliente ? Icons.verified_user : Icons.person_add,
                  color: const Color(0xFF1565C0),
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colorEstado.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            estadoCliente,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: colorEstado.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    infoLinea(icono: Icons.business, texto: empresa),
                    infoLinea(icono: Icons.phone, texto: telefono),
                    infoLinea(icono: Icons.email, texto: correo),
                    infoLinea(
                      icono: Icons.badge_outlined,
                      texto: 'Ingresado por $vendedor',
                    ),
                    infoLinea(
                      icono: Icons.calendar_today_outlined,
                      texto: viewModel.fechaCorta(cliente.fechaRegistro),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditarClientePantalla(
                        clienteId: cliente.id ?? '',
                        cliente: cliente.toPlainMap(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget estadoVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                viewModel.mostrarClientes ? Icons.people : Icons.person_search,
                color: const Color(0xFF1565C0),
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              viewModel.mostrarClientes
                  ? 'No hay clientes registrados'
                  : 'No hay clientes potenciales',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Cuando agregues registros aparecerán en esta lista.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
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
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            onPressed: abrirAgregarCliente,
            child: const Icon(Icons.add),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                  child: Column(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
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
                              color: const Color(
                                0xFF1565C0,
                              ).withValues(alpha: 0.22),
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
                              child: Icon(
                                viewModel.mostrarClientes
                                    ? Icons.verified_user
                                    : Icons.person_add,
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
                                    viewModel.mostrarClientes
                                        ? 'Clientes'
                                        : 'Clientes potenciales',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    viewModel.mostrarClientes
                                        ? 'Personas que ya concretaron con SAPINF.'
                                        : 'Prospectos en seguimiento comercial.',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            tabFiltro(
                              texto: 'Potenciales',
                              icono: Icons.person_search,
                              activo: !viewModel.mostrarClientes,
                              onTap: () {
                                viewModel.cambiarFiltro(false);
                              },
                            ),
                            const SizedBox(width: 8),
                            tabFiltro(
                              texto: 'Clientes',
                              icono: Icons.verified_user,
                              activo: viewModel.mostrarClientes,
                              onTap: () {
                                viewModel.cambiarFiltro(true);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: buscarController,
                        decoration: InputDecoration(
                          hintText: viewModel.mostrarClientes
                              ? 'Buscar cliente...'
                              : 'Buscar cliente potencial...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: viewModel.textoBusqueda.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    buscarController.clear();
                                    viewModel.limpiarBusqueda();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 1.3,
                            ),
                          ),
                        ),
                        onChanged: (valor) {
                          viewModel.actualizarBusqueda(valor);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<ClientesSesionViewData>(
                    future: viewModel.sesionFuture,
                    builder: (context, sesionSnapshot) {
                      if (!sesionSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final sesion = sesionSnapshot.data!;

                      return StreamBuilder<List<ClienteModel>>(
                        stream: viewModel.clientesStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final clientes = viewModel.filtrarClientes(
                            snapshot.data ?? [],
                            sesion,
                          );

                          if (clientes.isEmpty) {
                            return estadoVacio();
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.fromLTRB(18, 8, 18, 96),
                            itemCount: clientes.length,
                            itemBuilder: (context, index) {
                              return tarjetaCliente(cliente: clientes[index]);
                            },
                          );
                        },
                      );
                    },
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
