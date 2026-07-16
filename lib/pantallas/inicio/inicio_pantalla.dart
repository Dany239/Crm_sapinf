import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

import '../seguimientos/seguimientos_pantalla.dart';
import '../../servicios/servicios_pantalla.dart';
import '../reportes/reportes_pantalla.dart';
import '../usuarios/usuarios_pantalla.dart';
import '../agenda/agenda_pantalla.dart';
import '../notificaciones/notificaciones_pantalla.dart';
import '../clientes/clientes_pantalla.dart';
import '../ventas/ventas_pantalla.dart';
import '../centro_control/centro_control_comercial_pantalla.dart';
import '../actualizaciones/actualizaciones_pantalla.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/dashboard_header.dart';
import '../../viewmodels/inicio_viewmodel.dart';

class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final InicioViewModel viewModel = InicioViewModel();
  String rol = '';
  bool accesoAdministrador = false;

  bool get tieneAccesoAdministrador =>
      esRolAdministrador(rol) || accesoAdministrador;

  bool esRolAdministrador(String? valor) {
    final rolNormalizado = valor?.toString().trim().toLowerCase() ?? '';
    return rolNormalizado == 'administrador' || rolNormalizado == 'admin';
  }

  bool valorBooleano(dynamic valor) {
    if (valor is bool) return valor;
    if (valor is String) {
      final normalizado = valor.trim().toLowerCase();
      return normalizado == 'true' ||
          normalizado == 'si' ||
          normalizado == 'sí' ||
          normalizado == '1';
    }
    if (valor is num) return valor == 1;
    return false;
  }

  bool tieneAccesoAdministradorDesdeData(Map<String, dynamic>? data) {
    if (data == null) return tieneAccesoAdministrador;

    return esRolAdministrador(data['rol']?.toString()) ||
        valorBooleano(data['accesoAdministrador']) ||
        valorBooleano(data['esAdministrador']) ||
        valorBooleano(data['admin']);
  }

  Widget soloAdministrador(Widget child) {
    final uid = viewModel.usuarioActualId;

    if (uid == null) return const SizedBox.shrink();

    return StreamBuilder<Map<String, dynamic>?>(
      stream: viewModel.usuarioActualDataStream(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (!tieneAccesoAdministradorDesdeData(data)) {
          return const SizedBox.shrink();
        }

        return child;
      },
    );
  }

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_actualizarDesdeViewModel);
    viewModel.cargarRol();
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizarDesdeViewModel);
    viewModel.dispose();
    super.dispose();
  }

  void _actualizarDesdeViewModel() {
    if (!mounted) return;
    setState(() {
      rol = viewModel.rol;
      accesoAdministrador = viewModel.accesoAdministrador;
    });
  }

  Future<void> cerrarSesion(BuildContext context) async {
    await viewModel.cerrarSesion();

    if (!context.mounted) return;

    Navigator.pop(context);
  }

  String formatoLempiras(num valor) {
    return viewModel.formatoLempiras(valor);
  }

  Widget tarjetaClientesDashboard() {
    return StreamBuilder<int>(
      stream: viewModel.contarClientesPotenciales(),
      builder: (context, snapshot) {
        return KpiCard(
          titulo: 'Potenciales',
          valor: '${snapshot.data ?? 0}',
          subtitulo: 'Ver lista',
          icono: Icons.people,
          color: const Color(0xFF1565C0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ClientesPantalla()),
            );
          },
        );
      },
    );
  }

  Widget tarjetaVentasMesDashboard() {
    return StreamBuilder<double>(
      stream: viewModel.ingresosEsteMes(),
      builder: (context, snapshot) {
        return KpiCard(
          titulo: 'Ventas del mes',
          valor: formatoLempiras(snapshot.data ?? 0),
          subtitulo: 'Ver detalle',
          icono: Icons.attach_money,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const VentasPantalla()),
            );
          },
        );
      },
    );
  }

  Widget tarjetaClientesNuevosDashboard() {
    return StreamBuilder<int>(
      stream: viewModel.contarClientesConvertidos(),
      builder: (context, snapshot) {
        return KpiCard(
          titulo: 'Clientes',
          valor: '${snapshot.data ?? 0}',
          subtitulo: 'Convertidos',
          icono: Icons.person_add,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    const ClientesPantalla(mostrarClientes: true),
              ),
            );
          },
        );
      },
    );
  }

  Widget tarjetaSeguimientosDashboard() {
    return StreamBuilder<int>(
      stream: viewModel.contarSeguimientosPendientes(),
      builder: (context, snapshot) {
        return KpiCard(
          titulo: 'Seguimientos',
          valor: '${snapshot.data ?? 0}',
          subtitulo: 'Pendientes',
          icono: Icons.phone_in_talk,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SeguimientosPantalla(),
              ),
            );
          },
        );
      },
    );
  }

  Widget tarjetaEstadistica({
    required String titulo,
    required IconData icono,
    required Stream<int> stream,
    required List<Color> colores,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        final cantidad = snapshot.data ?? 0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colores,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colores.last.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icono, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                ),
              ),
              Text(
                '$cantidad',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget tarjetaDinero({
    required String titulo,
    required IconData icono,
    required Stream<double> stream,
    required List<Color> colores,
  }) {
    return StreamBuilder<double>(
      stream: stream,
      builder: (context, snapshot) {
        final total = snapshot.data ?? 0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colores),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icono, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              Text(
                'L.${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget tarjetaClienteDestacado() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: viewModel.clienteDestacado(),
      builder: (context, snapshot) {
        final data = snapshot.data;

        if (data == null) {
          return const SizedBox();
        }

        return Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFF3E0),
                child: Icon(Icons.emoji_events, color: Colors.orange),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente destacado',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      data['cliente'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'L. ${(data['total'] as double).toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget tarjetaNotificacionSeguimientos() {
    return StreamBuilder<int>(
      stream: viewModel.contarSeguimientosPendientes(),
      builder: (context, snapshot) {
        final pendientes = snapshot.data ?? 0;

        final hayPendientes = pendientes > 0;

        return Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hayPendientes
                ? const Color(0xFFFFF3E0)
                : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hayPendientes ? Colors.orange : Colors.green,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: hayPendientes ? Colors.orange : Colors.green,
                child: Icon(
                  hayPendientes ? Icons.notifications_active : Icons.check,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  hayPendientes
                      ? 'Tienes $pendientes seguimientos pendientes'
                      : 'No tienes seguimientos pendientes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hayPendientes
                        ? Colors.orange.shade900
                        : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget dashboardAdministrador() {
    return StreamBuilder<List<ResumenVendedorDashboard>>(
      stream: viewModel.resumenVendedoresDashboard(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final vendedores = snapshot.data ?? [];

        if (vendedores.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No hay actividad comercial registrada'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tituloSeccion('Top vendedores del mes'),
            const SizedBox(height: 10),
            ...vendedores
                .take(3)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => _tarjetaTopVendedor(entry.value, entry.key + 1),
                ),
            const SizedBox(height: 18),
            _tituloSeccion('Desempe\u00f1o del equipo'),
            const SizedBox(height: 10),
            ...vendedores.map(_tarjetaDesempenoVendedor),
          ],
        );
      },
    );
  }

  Widget _tituloSeccion(String titulo) {
    return Text(
      titulo,
      style: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1F2937),
      ),
    );
  }

  Widget _tarjetaTopVendedor(ResumenVendedorDashboard vendedor, int posicion) {
    final colores = [
      const Color(0xFFFFB300),
      const Color(0xFF78909C),
      const Color(0xFF8D6E63),
    ];
    final color = colores[(posicion - 1).clamp(0, colores.length - 1)];

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EAF2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Text(
              '$posicion',
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendedor.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${vendedor.ventasCerradas} ventas cerradas',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatoLempiras(vendedor.montoCerrado),
            style: GoogleFonts.poppins(
              color: const Color(0xFF1565C0),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaDesempenoVendedor(ResumenVendedorDashboard vendedor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vendedor.nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: const Color(0xFF0D47A1),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricaEquipo(
                'Ventas',
                '${vendedor.ventas}',
                Icons.attach_money_rounded,
                Colors.green,
              ),
              _metricaEquipo(
                'Pendientes',
                '${vendedor.seguimientosPendientes}',
                Icons.schedule_rounded,
                Colors.orange,
              ),
              _metricaEquipo(
                'Prospectos',
                '${vendedor.prospectos}',
                Icons.person_add_alt_1_rounded,
                const Color(0xFF1565C0),
              ),
              _metricaEquipo(
                'Convertidos',
                '${vendedor.convertidos}',
                Icons.verified_rounded,
                Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            'Ventas del mes: ${formatoLempiras(vendedor.montoVentas)}',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricaEquipo(
    String titulo,
    String valor,
    IconData icono,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, color: color, size: 20),
          const SizedBox(height: 3),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget graficosComerciales() {
    return StreamBuilder<GraficosComercialesData>(
      stream: viewModel.graficosComerciales(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;

        return Column(
          children: [
            graficoVentasPorQuincena(data.ventasQuincena),
            const SizedBox(height: 14),
            graficoVentasPorVendedor(data.vendedoresOrdenados.take(5).toList()),
            const SizedBox(height: 14),
            graficoOportunidadesPorEtapa(),
          ],
        );
      },
    );
  }

  Widget tarjetaGrafico({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF1565C0).withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: const Color(0xFF1565C0), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1F2937),
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget graficoVentasPorQuincena(Map<String, double> ventasQuincena) {
    final total = ventasQuincena.values.fold<double>(0, (a, b) => a + b);
    final maxY = valorMaximoGrafico(ventasQuincena.values);

    return tarjetaGrafico(
      titulo: 'Ventas por quincena',
      subtitulo: 'Monto vendido en el mes actual',
      icono: Icons.stacked_bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatoLempiras(total),
            style: GoogleFonts.poppins(
              color: const Color(0xFF1F2937),
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 170,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                barTouchData: tooltipBarras(),
                gridData: gridBarras(maxY),
                borderData: FlBorderData(show: false),
                titlesData: titulosBarras(['1-15', '16-fin']),
                barGroups: [
                  barraEstado(
                    0,
                    ventasQuincena['1-15']!,
                    const Color(0xFF1565C0),
                  ),
                  barraEstado(
                    1,
                    ventasQuincena['16-fin']!,
                    const Color(0xFF26A69A),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget graficoVentasPorVendedor(List<MapEntry<String, double>> vendedores) {
    final labels = vendedores
        .map((entry) => abreviarNombre(entry.key))
        .toList();
    final maxY = valorMaximoGrafico(vendedores.map((entry) => entry.value));

    return tarjetaGrafico(
      titulo: 'Ventas por vendedor',
      subtitulo: 'Ranking general por monto vendido',
      icono: Icons.groups_rounded,
      child: vendedores.isEmpty
          ? mensajeGraficoVacio('No hay ventas registradas')
          : SizedBox(
              height: 196,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  maxY: maxY,
                  barTouchData: tooltipBarras(),
                  gridData: gridBarras(maxY),
                  borderData: FlBorderData(show: false),
                  titlesData: titulosBarras(labels),
                  barGroups: vendedores.asMap().entries.map((entry) {
                    return barraEstado(
                      entry.key,
                      entry.value.value,
                      colorPorIndice(entry.key),
                    );
                  }).toList(),
                ),
              ),
            ),
    );
  }

  Widget graficoOportunidadesPorEtapa() {
    const etapas = [
      'Prospecto',
      'Contacto inicial',
      'Propuesta',
      'Negociacion',
      'Cierre',
    ];
    const colores = [
      Color(0xFF1565C0),
      Color(0xFF26A69A),
      Color(0xFF43A047),
      Color(0xFFFFA726),
      Color(0xFF6D4CDB),
    ];

    return StreamBuilder<Map<String, int>>(
      stream: viewModel.oportunidadesPorEtapa(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return tarjetaGrafico(
            titulo: 'Oportunidades por etapa',
            subtitulo: 'Prospectos, contactos, propuestas y cierres',
            icono: Icons.donut_large_rounded,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final conteo = snapshot.data ?? {for (final etapa in etapas) etapa: 0};

        final total = conteo.values.fold<int>(0, (a, b) => a + b);

        return tarjetaGrafico(
          titulo: 'Oportunidades por etapa',
          subtitulo: 'Prospectos, contactos, propuestas y cierres',
          icono: Icons.donut_large_rounded,
          child: total == 0
              ? mensajeGraficoVacio('No hay oportunidades registradas')
              : Row(
                  children: [
                    SizedBox(
                      width: 132,
                      height: 132,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 38,
                          sectionsSpace: 2,
                          sections: etapas.asMap().entries.map((entry) {
                            final valor = conteo[entry.value] ?? 0;

                            return PieChartSectionData(
                              value: valor.toDouble(),
                              color: colores[entry.key],
                              radius: 32,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: etapas.asMap().entries.map((entry) {
                          final valor = conteo[entry.value] ?? 0;
                          final porcentaje = total == 0
                              ? 0
                              : (valor * 100 / total);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: colores[entry.key],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$valor (${porcentaje.toStringAsFixed(1)}%)',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  BarTouchData tooltipBarras() {
    return BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        tooltipRoundedRadius: 12,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        getTooltipColor: (_) => const Color(0xFF1F2937),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            formatoLempiras(rod.toY),
            GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        },
      ),
    );
  }

  FlGridData gridBarras(double maxY) {
    return FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: maxY / 4,
      getDrawingHorizontalLine: (value) {
        return FlLine(
          color: const Color(0xFF1565C0).withValues(alpha: 0.08),
          strokeWidth: 1,
        );
      },
    );
  }

  FlTitlesData titulosBarras(List<String> labels) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= labels.length) return const Text('');

            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                labels[index],
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget mensajeGraficoVacio(String mensaje) {
    return Container(
      height: 132,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  double valorMaximoGrafico(Iterable<double> valores) {
    final maximo = valores.isEmpty
        ? 0.0
        : valores.reduce((a, b) => a > b ? a : b);

    if (maximo <= 0) return 100000;

    return maximo * 1.25;
  }

  String abreviarNombre(String nombre) {
    final limpio = nombre.trim();
    if (limpio.length <= 10) return limpio;

    return '${limpio.substring(0, 10)}...';
  }

  Color colorPorIndice(int index) {
    const colores = [
      Color(0xFF1565C0),
      Color(0xFF26A69A),
      Color(0xFFFFA726),
      Color(0xFF43A047),
      Color(0xFF6D4CDB),
    ];

    return colores[index % colores.length];
  }

  BarChartGroupData barraEstado(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 22,
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget moduloAcceso({
    required BuildContext context,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required Widget pantalla,
    required Color color,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => pantalla),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icono, color: color, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descripcion,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  String saludoSegunHora() {
    final hora = DateTime.now().hour;

    if (hora >= 5 && hora < 12) {
      return 'Buenos días';
    }

    if (hora >= 12 && hora < 19) {
      return 'Buenas tardes';
    }

    return 'Buenas noches';
  }

  String nombreUsuario(User? usuario) {
    final nombre = usuario?.displayName;

    if (nombre != null && nombre.trim().isNotEmpty) {
      return nombre.trim();
    }

    final email = usuario?.email;

    if (email != null && email.trim().isNotEmpty) {
      return email.split('@').first;
    }

    return 'Vendedor';
  }

  ImageProvider? fotoPerfilDesdeData(Map<String, dynamic>? data) {
    final fotoBase64 = data?['fotoBase64']?.toString();

    if (fotoBase64 != null && fotoBase64.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(fotoBase64));
      } catch (_) {
        return null;
      }
    }

    final fotoUrl = data?['foto']?.toString();

    if (fotoUrl != null && fotoUrl.isNotEmpty) {
      return NetworkImage(fotoUrl);
    }

    return null;
  }

  void navegarDesdeDrawer(BuildContext context, Widget pantalla) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => pantalla));
  }

  Widget itemDrawer({
    required BuildContext context,
    required String titulo,
    required IconData icono,
    required VoidCallback onTap,
    Color color = const Color(0xFF1565C0),
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icono, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                titulo,
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1F2937),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  Widget drawerDashboard(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final uid = viewModel.usuarioActualId;
    final ancho = MediaQuery.of(context).size.width;

    return Drawer(
      width: ancho < 420 ? ancho * 0.84 : 360,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (uid == null)
              const SizedBox.shrink()
            else
              StreamBuilder<Map<String, dynamic>?>(
                stream: viewModel.usuarioActualDataStream(),
                builder: (context, snapshot) {
                  final data = snapshot.data;
                  final nombre =
                      (data?['nombre']?.toString().isNotEmpty ?? false)
                      ? data!['nombre'].toString()
                      : nombreUsuario(usuario);
                  final rolUsuario = data?['rol']?.toString() ?? rol;
                  final rolTexto = rolUsuario.isEmpty
                      ? 'Vendedor'
                      : '${rolUsuario[0].toUpperCase()}${rolUsuario.substring(1)}';
                  final foto = fotoPerfilDesdeData(data);

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
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
                          ).withValues(alpha: 0.20),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          backgroundImage: foto,
                          child: foto == null
                              ? const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 34,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                rolTexto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  Text(
                    'Accesos rápidos',
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  itemDrawer(
                    context: context,
                    titulo: 'Inicio',
                    icono: Icons.home_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  itemDrawer(
                    context: context,
                    titulo: 'Seguimientos',
                    icono: Icons.phone_in_talk_rounded,
                    color: Colors.orange,
                    onTap: () => navegarDesdeDrawer(
                      context,
                      const SeguimientosPantalla(),
                    ),
                  ),
                  itemDrawer(
                    context: context,
                    titulo: 'Agenda',
                    icono: Icons.calendar_month_rounded,
                    color: Colors.teal,
                    onTap: () =>
                        navegarDesdeDrawer(context, const AgendaPantalla()),
                  ),
                  itemDrawer(
                    context: context,
                    titulo: 'Actualizaciones',
                    icono: Icons.system_update_alt_rounded,
                    color: const Color(0xFF1565C0),
                    onTap: () => navegarDesdeDrawer(
                      context,
                      const ActualizacionesPantalla(),
                    ),
                  ),
                  soloAdministrador(
                    itemDrawer(
                      context: context,
                      titulo: 'Centro de Control Comercial',
                      icono: Icons.monitor_heart_rounded,
                      color: Colors.teal,
                      onTap: () => navegarDesdeDrawer(
                        context,
                        const CentroControlComercialPantalla(),
                      ),
                    ),
                  ),
                  soloAdministrador(
                    itemDrawer(
                      context: context,
                      titulo: 'Servicios',
                      icono: Icons.build_circle_rounded,
                      color: const Color(0xFF1565C0),
                      onTap: () => navegarDesdeDrawer(
                        context,
                        const ServiciosPantalla(),
                      ),
                    ),
                  ),
                  soloAdministrador(
                    itemDrawer(
                      context: context,
                      titulo: 'Reportes',
                      icono: Icons.bar_chart_rounded,
                      color: Colors.purple,
                      onTap: () =>
                          navegarDesdeDrawer(context, const ReportesPantalla()),
                    ),
                  ),
                  soloAdministrador(
                    itemDrawer(
                      context: context,
                      titulo: 'Usuarios',
                      icono: Icons.manage_accounts_rounded,
                      color: Colors.indigo,
                      onTap: () =>
                          navegarDesdeDrawer(context, const UsuariosPantalla()),
                    ),
                  ),
                  itemDrawer(
                    context: context,
                    titulo: 'Clientes potenciales',
                    icono: Icons.person_add_alt_1_rounded,
                    color: Colors.indigo,
                    onTap: () =>
                        navegarDesdeDrawer(context, const ClientesPantalla()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: itemDrawer(
                context: context,
                titulo: 'Cerrar sesión',
                icono: Icons.logout_rounded,
                color: Colors.red,
                onTap: () => cerrarSesion(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usuario = FirebaseAuth.instance.currentUser;
    final saludo = saludoSegunHora();
    final nombre = nombreUsuario(usuario);

    if (rol.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: scaffoldKey,
      drawer: drawerDashboard(context),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(86),
        child: StreamBuilder<int>(
          stream: viewModel.contarNotificacionesPendientes(),
          builder: (context, snapshot) {
            final notificaciones = snapshot.data ?? 0;

            return DashboardHeader(
              titulo: 'Dashboard',
              notificaciones: notificaciones,
              onMenuTap: () => scaffoldKey.currentState?.openDrawer(),
              onNotificationTap: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Notificaciones',
                  barrierColor: Colors.black.withValues(alpha: 0.42),
                  transitionDuration: const Duration(milliseconds: 260),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return const NotificacionesPantalla();
                  },
                  transitionBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1, 0),
                            end: Offset.zero,
                          ).animate(curved),
                          child: child,
                        );
                      },
                );
              },
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.wb_sunny,
                      color: Color(0xFFFFD54F),
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$saludo, $nombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Aquí tienes un resumen de tu negocio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Resumen comercial',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.92,
              children: [
                tarjetaClientesDashboard(),
                tarjetaVentasMesDashboard(),
                tarjetaClientesNuevosDashboard(),
                tarjetaSeguimientosDashboard(),
              ],
            ),
            soloAdministrador(
              Column(
                children: [
                  const SizedBox(height: 18),
                  moduloAcceso(
                    context: context,
                    titulo: 'Centro de Control Comercial',
                    descripcion:
                        'Supervisa la operación del equipo en tiempo real',
                    icono: Icons.monitor_heart_rounded,
                    pantalla: const CentroControlComercialPantalla(),
                    color: Colors.teal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            moduloAcceso(
              context: context,
              titulo: 'Centro de actualizaciones',
              descripcion: 'Descarga, instala o recupera versiones del CRM',
              icono: Icons.system_update_alt_rounded,
              pantalla: const ActualizacionesPantalla(),
              color: const Color(0xFF1565C0),
            ),
            graficosComerciales(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
