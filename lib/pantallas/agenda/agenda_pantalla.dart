import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../seguimientos/agregar_seguimiento_pantalla.dart';
import '../seguimientos/editar_seguimiento_pantalla.dart';
import '../../models/seguimiento_model.dart';
import '../../servicios/sesion_usuario.dart';
import '../../viewmodels/agenda_viewmodel.dart';

class AgendaPantalla extends StatefulWidget {
  const AgendaPantalla({super.key});

  @override
  State<AgendaPantalla> createState() => _AgendaPantallaState();
}

class _AgendaPantallaState extends State<AgendaPantalla> {
  final AgendaViewModel viewModel = AgendaViewModel();
  late Future<SesionUsuario> sesionFuture;

  @override
  void initState() {
    super.initState();
    sesionFuture = obtenerSesionUsuario();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  final meses = const [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre',
  ];

  final diasCortos = const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  IconData iconoTipo(String tipo) {
    if (tipo == 'Llamada') return Icons.phone_rounded;
    if (tipo.toLowerCase().contains('reuni')) return Icons.groups_rounded;
    if (tipo == 'Correo') return Icons.email_rounded;
    if (tipo == 'Visita') return Icons.location_on_rounded;
    return Icons.event_note_rounded;
  }

  Color colorEstado(String estado) {
    if (estado == 'Realizado') return Colors.green;
    if (estado == 'Cancelado') return Colors.red;
    return Colors.orange;
  }

  Color colorTipo(String tipo) {
    if (tipo == 'Correo') return Colors.teal;
    if (tipo == 'Visita') return Colors.orange;
    if (tipo.toLowerCase().contains('reuni')) return Colors.deepPurple;
    return const Color(0xFF1565C0);
  }

  List<DateTime> diasDeSemana() {
    return viewModel.diasDeSemana();
  }

  bool mismoDia(DateTime a, DateTime b) {
    return viewModel.mismoDia(a, b);
  }

  void cambiarMes(int cantidad) {
    setState(() {
      viewModel.cambiarMes(cantidad);
    });
  }

  Future<void> abrirCalendario() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: viewModel.fechaSeleccionada,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Selecciona una fecha',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      fieldLabelText: 'Fecha',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );

    if (fecha != null && mounted) {
      setState(() {
        viewModel.seleccionarFecha(fecha);
      });
    }
  }

  Widget botonCircular({required IconData icono, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Icon(icono, color: const Color(0xFF1565C0)),
      ),
    );
  }

  Widget selectorMes() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => cambiarMes(-1),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${meses[viewModel.fechaSeleccionada.month - 1]} ${viewModel.fechaSeleccionada.year}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Agenda comercial',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => cambiarMes(1),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: diasDeSemana().map((fecha) {
              final seleccionado = mismoDia(fecha, viewModel.fechaSeleccionada);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        viewModel.seleccionarFecha(fecha);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: seleccionado
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Column(
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              diasCortos[fecha.weekday - 1],
                              style: GoogleFonts.poppins(
                                color: seleccionado
                                    ? const Color(0xFF1565C0)
                                    : Colors.white.withValues(alpha: 0.80),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${fecha.day}',
                            style: GoogleFonts.poppins(
                              color: seleccionado
                                  ? const Color(0xFF1565C0)
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget tarjetaActividad({required SeguimientoModel seguimiento}) {
    final cliente = seguimiento.cliente ?? 'Sin cliente';
    final tipo = seguimiento.tipo;
    final comentario = seguimiento.comentario;
    final estado = seguimiento.estado;
    final color = colorEstado(estado);
    final tipoColor = colorTipo(tipo);

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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                viewModel.horaSeguimiento(seguimiento),
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tipoColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(iconoTipo(tipo), size: 22, color: tipoColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cliente,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comentario.isEmpty ? 'Sin comentario' : comentario,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$tipo · $estado',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF1565C0),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sin actividades para este día',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Usa las flechas para moverte entre días o meses.',
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
    final hoy = DateTime.now();
    final esHoy = mismoDia(hoy, viewModel.fechaSeleccionada);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text(
          'Agenda',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: botonCircular(
              icono: Icons.today_rounded,
              onTap: abrirCalendario,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: selectorMes(),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: StreamBuilder<List<SeguimientoModel>>(
              stream: viewModel.seguimientosStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return FutureBuilder<SesionUsuario>(
                  future: sesionFuture,
                  builder: (context, sesionSnapshot) {
                    if (!sesionSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final sesion = sesionSnapshot.data!;
                    final seguimientos = viewModel.filtrarPorFecha(
                      snapshot.data ?? [],
                      sesion,
                    );

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      esHoy
                                          ? 'Hoy - ${viewModel.fechaSeleccionada.day} de ${meses[viewModel.fechaSeleccionada.month - 1]}'
                                          : '${viewModel.fechaSeleccionada.day} de ${meses[viewModel.fechaSeleccionada.month - 1]}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${seguimientos.length} actividades programadas',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: seguimientos.isEmpty
                              ? estadoVacio()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    110,
                                  ),
                                  itemCount: seguimientos.length,
                                  itemBuilder: (context, index) {
                                    final seguimiento = seguimientos[index];

                                    return tarjetaActividad(
                                      seguimiento: seguimiento,
                                    );
                                  },
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
