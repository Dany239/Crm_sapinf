import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/seguimiento_model.dart';
import '../../viewmodels/seguimientos_viewmodel.dart';
import 'agregar_seguimiento_pantalla.dart';
import 'editar_seguimiento_pantalla.dart';

class SeguimientosPantalla extends StatefulWidget {
  const SeguimientosPantalla({super.key});

  @override
  State<SeguimientosPantalla> createState() => _SeguimientosPantallaState();
}

class _SeguimientosPantallaState extends State<SeguimientosPantalla> {
  final buscarController = TextEditingController();
  late final SeguimientosViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = SeguimientosViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    buscarController.dispose();
    super.dispose();
  }

  IconData iconoTipo(String tipo) {
    if (tipo == 'Llamada') return Icons.phone_rounded;
    if (tipo.toLowerCase().contains('reuni')) return Icons.groups_rounded;
    if (tipo == 'Correo') return Icons.email_rounded;
    if (tipo == 'Mensaje') return Icons.message_rounded;
    if (tipo == 'Visita') return Icons.location_on_rounded;
    return Icons.event_note_rounded;
  }

  Color colorTipo(String tipo) {
    if (tipo == 'Correo') return Colors.teal;
    if (tipo == 'Mensaje') return Colors.indigo;
    if (tipo == 'Visita') return Colors.orange;
    if (tipo.toLowerCase().contains('reuni')) return Colors.deepPurple;
    return const Color(0xFF1565C0);
  }

  Color colorEstado(String estado) {
    if (estado == 'Realizado') return Colors.green;
    if (estado == 'Cancelado') return Colors.red;
    return Colors.orange;
  }

  Widget filtroChip(String texto) {
    final activo = viewModel.filtroEstado == texto;

    return ChoiceChip(
      label: Text(texto),
      selected: activo,
      showCheckmark: false,
      selectedColor: const Color(0xFF1565C0),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: activo ? const Color(0xFF1565C0) : Colors.grey.shade200,
      ),
      labelStyle: GoogleFonts.poppins(
        color: activo ? Colors.white : Colors.grey.shade700,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      onSelected: (_) => viewModel.cambiarFiltroEstado(texto),
    );
  }

  Widget encabezado(int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(
              Icons.task_alt_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seguimientos',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '$total gestiones registradas',
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

  Widget buscador() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: buscarController,
        onChanged: viewModel.actualizarBusqueda,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          hintText: 'Buscar seguimiento...',
          hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: viewModel.busqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    buscarController.clear();
                    viewModel.limpiarBusqueda();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget tarjetaSeguimiento({required SeguimientoModel seguimiento}) {
    final cliente = seguimiento.cliente ?? 'Sin cliente';
    final comentario = seguimiento.comentario.isEmpty
        ? 'Sin comentario'
        : seguimiento.comentario;
    final tipo = seguimiento.tipo;
    final estado = seguimiento.estado;
    final vendedor = seguimiento.vendedorNombre ?? 'Sin vendedor asignado';
    final fechaActividad = viewModel.fechaActividad(seguimiento);
    final tipoColor = colorTipo(tipo);
    final estadoColor = colorEstado(estado);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditarSeguimientoPantalla(
              seguimientoId: seguimiento.id ?? '',
              seguimiento: seguimiento.toPlainMap(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tipoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(iconoTipo(tipo), color: tipoColor, size: 25),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comentario,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    cliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$vendedor · ${viewModel.fechaCorta(fechaActividad)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      etiqueta(tipo, tipoColor),
                      etiqueta(estado, estadoColor),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget etiqueta(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget vacio() {
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF1565C0),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No hay seguimientos',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Agrega una gestión para darle continuidad al cliente.',
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
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            title: Text(
              'Seguimientos',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'Nuevo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AgregarSeguimientoPantalla(),
                ),
              );
            },
          ),
          body: FutureBuilder<SeguimientosSesionViewData>(
            future: viewModel.sesionFuture,
            builder: (context, sesionSnapshot) {
              if (!sesionSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sesion = sesionSnapshot.data!;

              return StreamBuilder<List<SeguimientoModel>>(
                stream: viewModel.seguimientosStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final seguimientos = viewModel.filtrarSeguimientos(
                    snapshot.data ?? [],
                    sesion,
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    children: [
                      encabezado(seguimientos.length),
                      const SizedBox(height: 16),
                      buscador(),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            filtroChip('Todos'),
                            const SizedBox(width: 8),
                            filtroChip('Pendiente'),
                            const SizedBox(width: 8),
                            filtroChip('Realizado'),
                            const SizedBox(width: 8),
                            filtroChip('Cancelado'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (seguimientos.isEmpty)
                        SizedBox(height: 260, child: vacio())
                      else
                        ...seguimientos.map(
                          (seguimiento) =>
                              tarjetaSeguimiento(seguimiento: seguimiento),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
