import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../ventas/editar_venta_pantalla.dart';
import '../ventas/ventas_pantalla.dart';
import '../clientes/clientes_pantalla.dart';
import '../seguimientos/seguimientos_pantalla.dart';
import '../../servicios/servicios_pantalla.dart';

class ReportesPantalla extends StatefulWidget {
  const ReportesPantalla({super.key});

  @override
  State<ReportesPantalla> createState() => _ReportesPantallaState();
}

class _ReportesPantallaState extends State<ReportesPantalla> {
  DateTimeRange? rangoSeleccionado;

  bool perteneceAlRango(
    Map<String, dynamic> data,
    DateTimeRange rango, {
    String campoFecha = 'fechaRegistro',
  }) {
    final valor = data[campoFecha];
    if (valor is! Timestamp) return false;
    final fecha = valor.toDate();
    final inicio = DateTime(
      rango.start.year,
      rango.start.month,
      rango.start.day,
    );
    final finExclusivo = DateTime(
      rango.end.year,
      rango.end.month,
      rango.end.day + 1,
    );
    return !fecha.isBefore(inicio) && fecha.isBefore(finExclusivo);
  }

  DateTimeRange rangoMesActual() {
    final ahora = DateTime.now();
    return DateTimeRange(
      start: DateTime(ahora.year, ahora.month),
      end: DateTime(ahora.year, ahora.month + 1, 0),
    );
  }

  DateTimeRange rangoAnterior(DateTimeRange rango) {
    final dias = rango.end.difference(rango.start).inDays + 1;
    final fin = rango.start.subtract(const Duration(days: 1));
    return DateTimeRange(
      start: fin.subtract(Duration(days: dias - 1)),
      end: fin,
    );
  }

  bool mostrarEnFiltro(Map<String, dynamic> data) {
    final rango = rangoSeleccionado;
    return rango == null || perteneceAlRango(data, rango);
  }

  double? calcularVariacion(num actual, num anterior) {
    if (anterior == 0) return actual == 0 ? 0 : null;
    return ((actual - anterior) / anterior) * 100;
  }

  Stream<_MetricaReporte> contarDocumentos(
    String coleccion, {
    String? estado,
  }) {
    return FirebaseFirestore.instance
        .collection(coleccion)
        .snapshots()
        .map((snapshot) {
      final rangoActual = rangoSeleccionado ?? rangoMesActual();
      final anteriorRango = rangoAnterior(rangoActual);
      var totalMostrado = 0;
      var actual = 0;
      var anterior = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (estado != null && data['estado'] != estado) continue;

        if (mostrarEnFiltro(data)) totalMostrado++;
        if (perteneceAlRango(data, rangoActual)) actual++;
        if (perteneceAlRango(data, anteriorRango)) anterior++;
      }

      return _MetricaReporte(
        valor: totalMostrado,
        variacion: calcularVariacion(actual, anterior),
      );
    });
  }

  Stream<_MetricaReporte> calcularMontoTotal() {
    return FirebaseFirestore.instance.collection('ventas').snapshots().map(
      (snapshot) {
        final rangoActual = rangoSeleccionado ?? rangoMesActual();
        final anteriorRango = rangoAnterior(rangoActual);
        var totalMostrado = 0.0;
        var actual = 0.0;
        var anterior = 0.0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final monto = double.tryParse(data['monto'].toString()) ?? 0;

          if (mostrarEnFiltro(data)) totalMostrado += monto;
          if (perteneceAlRango(data, rangoActual)) actual += monto;
          if (perteneceAlRango(data, anteriorRango)) anterior += monto;
        }

        return _MetricaReporte(
          valor: totalMostrado,
          variacion: calcularVariacion(actual, anterior),
        );
      },
    );
  }

  String formatoLempiras(dynamic valor) {
    final monto = num.tryParse(valor?.toString() ?? '0') ?? 0;
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 2,
    ).format(monto);
  }

  String fechaCorta(dynamic valor) {
    if (valor is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(valor.toDate());
  }

  String iniciales(String nombre) {
    final partes =
        nombre.trim().split(' ').where((parte) => parte.isNotEmpty).toList();
    if (partes.isEmpty) return 'SV';
    if (partes.length == 1) {
      return partes.first
          .substring(0, partes.first.length.clamp(0, 2))
          .toUpperCase();
    }
    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'Cerrada':
      case 'Completada':
        return const Color(0xFF16A34A);
      case 'Cancelada':
        return const Color(0xFFDC2626);
      case 'En proceso':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  void abrirVentas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VentasPantalla()),
    );
  }

  void _abrirPantalla(Widget pantalla) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => pantalla),
    );
  }

  String textoFiltroActual() {
    final rango = rangoSeleccionado;
    if (rango == null) return 'Todos los datos';
    final formato = DateFormat('dd MMM yyyy', 'es');
    if (rango.start.year == rango.end.year &&
        rango.start.month == rango.end.month &&
        rango.start.day == rango.end.day) {
      return formato.format(rango.start);
    }
    return '${formato.format(rango.start)} - ${formato.format(rango.end)}';
  }

  Future<void> abrirFiltroFechas() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        final ahora = DateTime.now();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar reportes',
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  textoFiltroActual(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                _opcionFiltro(context, 'Todos los datos', 'todos'),
                _opcionFiltro(context, 'Hoy', 'hoy'),
                _opcionFiltro(context, 'Este mes', 'mes'),
                _opcionFiltro(context, 'Este a\u00f1o', 'anio'),
                ListTile(
                  leading: const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF1565C0),
                  ),
                  title: const Text('Elegir fechas'),
                  subtitle: Text(
                    '${DateFormat.MMMM('es').format(ahora)} ${ahora.year}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, 'personalizado'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || opcion == null) return;
    final ahora = DateTime.now();

    if (opcion == 'todos') {
      setState(() => rangoSeleccionado = null);
      return;
    }
    if (opcion == 'hoy') {
      setState(() {
        rangoSeleccionado = DateTimeRange(start: ahora, end: ahora);
      });
      return;
    }
    if (opcion == 'mes') {
      setState(() => rangoSeleccionado = rangoMesActual());
      return;
    }
    if (opcion == 'anio') {
      setState(() {
        rangoSeleccionado = DateTimeRange(
          start: DateTime(ahora.year),
          end: DateTime(ahora.year, 12, 31),
        );
      });
      return;
    }

    final rango = await showDateRangePicker(
      context: context,
      initialDateRange: rangoSeleccionado,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: ahora,
      helpText: 'Selecciona el periodo',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF1565C0),
                  secondary: const Color(0xFF29B6F6),
                ),
            datePickerTheme: const DatePickerThemeData(
              headerBackgroundColor: Color(0xFF1565C0),
              headerForegroundColor: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (rango != null && mounted) {
      setState(() => rangoSeleccionado = rango);
    }
  }

  Widget _opcionFiltro(
    BuildContext context,
    String titulo,
    String valor,
  ) {
    return ListTile(
      leading: const Icon(
        Icons.date_range_rounded,
        color: Color(0xFF1565C0),
      ),
      title: Text(titulo),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.pop(context, valor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _encabezado()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Resumen general',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                _resumen(),
                const SizedBox(height: 20),
                _montoTotal(),
                const SizedBox(height: 24),
                Text(
                  'Rendimiento por vendedor',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _rendimientoVendedores(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '\u00daltimas ventas',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: abrirVentas,
                      child: const Text('Ver todas'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ultimasVentas(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encabezado() {
    return ClipPath(
      clipper: _CurvaEncabezado(),
      child: Container(
        height: 245,
        padding: const EdgeInsets.fromLTRB(28, 0, 22, 36),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportes',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rangoSeleccionado == null
                          ? 'Resumen general de tu gesti\u00f3n comercial'
                          : textoFiltroActual(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: abrirFiltroFechas,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumen() {
    final tarjetas = [
      _DatoResumen(
        titulo: 'Clientes',
        icono: Icons.people_rounded,
        color: const Color(0xFF1557D6),
        fondo: const Color(0xFFEAF0FF),
        stream: contarDocumentos('clientes'),
        onTap: () => _abrirPantalla(const ClientesPantalla()),
      ),
      _DatoResumen(
        titulo: 'Ventas',
        icono: Icons.attach_money_rounded,
        color: const Color(0xFF16A34A),
        fondo: const Color(0xFFE8F8EF),
        stream: contarDocumentos('ventas'),
        onTap: () => _abrirPantalla(const VentasPantalla()),
      ),
      _DatoResumen(
        titulo: 'Seguimientos',
        icono: Icons.phone_rounded,
        color: const Color(0xFFF28C18),
        fondo: const Color(0xFFFFF2E3),
        stream: contarDocumentos('seguimientos'),
        onTap: () => _abrirPantalla(const SeguimientosPantalla()),
      ),
      _DatoResumen(
        titulo: 'Servicios',
        icono: Icons.build_rounded,
        color: const Color(0xFF7138D8),
        fondo: const Color(0xFFF2EAFE),
        stream: contarDocumentos('servicios'),
        onTap: () => _abrirPantalla(const ServiciosPantalla()),
      ),
      _DatoResumen(
        titulo: 'Cerradas',
        icono: Icons.check_circle_rounded,
        color: const Color(0xFF16A34A),
        fondo: const Color(0xFFE8F8EF),
        stream: contarDocumentos('ventas', estado: 'Cerrada'),
        onTap: () => _abrirPantalla(
          const VentasPantalla(estadoInicial: 'Cerrada'),
        ),
      ),
      _DatoResumen(
        titulo: 'Pendientes',
        icono: Icons.pending_actions_rounded,
        color: const Color(0xFFF28C18),
        fondo: const Color(0xFFFFF2E3),
        stream: contarDocumentos('ventas', estado: 'Pendiente'),
        invertirColor: true,
        onTap: () => _abrirPantalla(
          const VentasPantalla(estadoInicial: 'Pendiente'),
        ),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = (constraints.maxWidth - 20) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 12,
          children: tarjetas
              .map((tarjeta) => SizedBox(
                    width: ancho,
                    height: 166,
                    child: _tarjetaResumen(tarjeta),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _tarjetaResumen(_DatoResumen dato) {
    return StreamBuilder<_MetricaReporte>(
      stream: dato.stream,
      builder: (context, snapshot) {
        final metrica = snapshot.data ?? const _MetricaReporte(valor: 0);
        return InkWell(
          onTap: dato.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D255F).withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: dato.fondo,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(dato.icono, color: dato.color, size: 24),
                ),
                const Spacer(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    dato.titulo,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${metrica.valor.toInt()}',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _variacion(
                  metrica.variacion,
                  invertirColor: dato.invertirColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _variacion(
    double? porcentaje, {
    bool invertirColor = false,
  }) {
    final esNuevo = porcentaje == null;
    final valor = porcentaje ?? 0;
    final esPositivo = valor > 0;
    final esNegativo = valor < 0;
    final esFavorable = invertirColor ? esNegativo : esPositivo;
    final esDesfavorable = invertirColor ? esPositivo : esNegativo;
    final color = esNuevo || esFavorable
        ? const Color(0xFF16A34A)
        : esDesfavorable
            ? const Color(0xFFDC2626)
            : const Color(0xFF64748B);
    final icono = esNuevo || esPositivo
        ? Icons.arrow_upward_rounded
        : esNegativo
            ? Icons.arrow_downward_rounded
            : Icons.arrow_forward_rounded;
    final texto = esNuevo
        ? 'Nuevo vs mes anterior'
        : '${valor.abs().toStringAsFixed(1)}% vs mes anterior';

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          children: [
            Icon(icono, size: 12, color: color),
            const SizedBox(width: 2),
            Text(
              texto,
              style: GoogleFonts.poppins(
                color: const Color(0xFF53617E),
                fontSize: 8.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _montoTotal() {
    return StreamBuilder<_MetricaReporte>(
      stream: calcularMontoTotal(),
      builder: (context, snapshot) {
        final metrica = snapshot.data ?? const _MetricaReporte(valor: 0);
        final porcentaje = metrica.variacion;
        final esNuevo = porcentaje == null;
        final variacion = porcentaje ?? 0;
        final colorVariacion = esNuevo || variacion > 0
            ? const Color(0xFF7CFF9D)
            : variacion < 0
                ? const Color(0xFFFFB4B4)
                : Colors.white70;
        final iconoVariacion = esNuevo || variacion > 0
            ? '\u2191'
            : variacion < 0
                ? '\u2193'
                : '\u2192';
        final textoVariacion = esNuevo
            ? 'Nuevo vs mes anterior'
            : '${variacion.abs().toStringAsFixed(1)}% vs mes anterior';

        return Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A4AD8), Color(0xFF1968ED)],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1565C0).withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              const Positioned(
                right: 0,
                bottom: 16,
                child: _GraficoDecorativo(),
              ),
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto total vendido',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatoLempiras(metrica.valor),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$iconoVariacion $textoVariacion',
                          style: GoogleFonts.poppins(
                            color: colorVariacion,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ultimasVentas() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final ventas = [...?snapshot.data?.docs]
            .where((doc) => mostrarEnFiltro(doc.data()))
            .toList();
        ventas.sort((a, b) {
          final fechaA = a.data()['fechaRegistro'] as Timestamp?;
          final fechaB = b.data()['fechaRegistro'] as Timestamp?;
          return (fechaB?.millisecondsSinceEpoch ?? 0)
              .compareTo(fechaA?.millisecondsSinceEpoch ?? 0);
        });
        final recientes = ventas.take(3).toList();

        if (recientes.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Text('No hay ventas registradas')),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D255F).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            children: List.generate(recientes.length, (index) {
              final doc = recientes[index];
              final venta = doc.data();
              final nombre = venta['cliente']?.toString() ?? 'Sin cliente';
              final estado = venta['estado']?.toString() ?? 'Pendiente';
              final colores = [
                const Color(0xFF16A34A),
                const Color(0xFF1565C0),
                const Color(0xFF7138D8),
              ];
              final color = colores[index % colores.length];

              return Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarVentaPantalla(
                            ventaId: doc.id,
                            venta: venta,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 27,
                            backgroundColor: color.withValues(alpha: 0.10),
                            child: Text(
                              iniciales(nombre),
                              style: GoogleFonts.poppins(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  venta['servicio']?.toString() ??
                                      'Sin servicio',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF687693),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${venta['vendedorNombre'] ?? 'Sin vendedor'} \u00b7 ${fechaCorta(venta['fechaRegistro'])}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1565C0),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    formatoLempiras(venta['monto']),
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  estado,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: colorEstado(estado),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF71809D),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (index != recientes.length - 1)
                    const Divider(height: 1, indent: 14, endIndent: 14),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _rendimientoVendedores() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('ventas').snapshots(),
      builder: (context, ventasSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              FirebaseFirestore.instance.collection('seguimientos').snapshots(),
          builder: (context, seguimientosSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  FirebaseFirestore.instance.collection('clientes').snapshots(),
              builder: (context, clientesSnapshot) {
                if (!ventasSnapshot.hasData ||
                    !seguimientosSnapshot.hasData ||
                    !clientesSnapshot.hasData) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final vendedores = <String, Map<String, dynamic>>{};

                Map<String, dynamic> vendedorDe(Map<String, dynamic> data) {
                  final id = data['vendedorId']?.toString() ?? 'sin-asignar';
                  return vendedores.putIfAbsent(id, () {
                    return {
                      'nombre': data['vendedorNombre']?.toString() ??
                          'Sin vendedor asignado',
                      'ventas': 0,
                      'cerradas': 0,
                      'seguimientos': 0,
                      'realizados': 0,
                      'prospectos': 0,
                    };
                  });
                }

                for (final doc in ventasSnapshot.data!.docs) {
                  final data = doc.data();
                  if (!mostrarEnFiltro(data)) continue;
                  final vendedor = vendedorDe(data);
                  vendedor['ventas'] = (vendedor['ventas'] as int) + 1;
                  if (data['estado'] == 'Cerrada') {
                    vendedor['cerradas'] = (vendedor['cerradas'] as int) + 1;
                  }
                }

                for (final doc in seguimientosSnapshot.data!.docs) {
                  final data = doc.data();
                  if (!mostrarEnFiltro(data)) continue;
                  final vendedor = vendedorDe(data);
                  vendedor['seguimientos'] =
                      (vendedor['seguimientos'] as int) + 1;
                  if (data['estado'] == 'Realizado' &&
                      data['fechaRealizacion'] is Timestamp) {
                    vendedor['realizados'] =
                        (vendedor['realizados'] as int) + 1;
                  }
                }

                for (final doc in clientesSnapshot.data!.docs) {
                  final data = doc.data();
                  if (!mostrarEnFiltro(data)) continue;
                  if (data['estadoCliente'] == 'Cliente') continue;
                  final vendedor = vendedorDe(data);
                  vendedor['prospectos'] = (vendedor['prospectos'] as int) + 1;
                }

                final lista = vendedores.values.toList()
                  ..sort(
                    (a, b) =>
                        (b['ventas'] as int).compareTo(a['ventas'] as int),
                  );

                if (lista.isEmpty) {
                  return _mensajeVacio('No hay actividad de vendedores');
                }

                return Column(
                  children: lista.map(_tarjetaRendimiento).toList(),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _tarjetaRendimiento(Map<String, dynamic> vendedor) {
    final seguimientos = vendedor['seguimientos'] as int;
    final realizados = vendedor['realizados'] as int;
    final cumplimiento =
        seguimientos == 0 ? 0 : ((realizados / seguimientos) * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEAF0FF),
                child: Icon(Icons.badge_outlined, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  vendedor['nombre'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$cumplimiento% cumplido',
                style: GoogleFonts.poppins(
                  color: cumplimiento >= 80
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFF59E0B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricaVendedor('Ventas', vendedor['ventas']),
              _metricaVendedor('Cerradas', vendedor['cerradas']),
              _metricaVendedor('Seguimientos', '$realizados/$seguimientos'),
              _metricaVendedor('Prospectos', vendedor['prospectos']),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricaVendedor(String titulo, Object valor) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$valor',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              titulo,
              style: GoogleFonts.poppins(
                color: const Color(0xFF687693),
                fontSize: 9.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mensajeVacio(String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(texto, textAlign: TextAlign.center),
    );
  }
}

class _DatoResumen {
  final String titulo;
  final IconData icono;
  final Color color;
  final Color fondo;
  final Stream<_MetricaReporte> stream;
  final bool invertirColor;
  final VoidCallback onTap;

  const _DatoResumen({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.fondo,
    required this.stream,
    required this.onTap,
    this.invertirColor = false,
  });
}

class _MetricaReporte {
  final num valor;
  final double? variacion;

  const _MetricaReporte({
    required this.valor,
    this.variacion,
  });
}

class _CurvaEncabezado extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 30)
      ..cubicTo(
        size.width * 0.20,
        size.height - 72,
        size.width * 0.52,
        size.height,
        size.width,
        size.height - 45,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _GraficoDecorativo extends StatelessWidget {
  const _GraficoDecorativo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      height: 92,
      child: CustomPaint(painter: _GraficoDecorativoPainter()),
    );
  }
}

class _GraficoDecorativoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final barras = Paint()..color = Colors.white.withValues(alpha: 0.12);
    const alturas = [24.0, 38.0, 32.0, 55.0, 64.0, 78.0];

    for (var i = 0; i < alturas.length; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * 21.0,
            size.height - alturas[i],
            14,
            alturas[i],
          ),
          const Radius.circular(2),
        ),
        barras,
      );
    }

    final linea = Path()
      ..moveTo(0, 56)
      ..lineTo(26, 36)
      ..lineTo(52, 42)
      ..lineTo(78, 17)
      ..lineTo(101, 30)
      ..lineTo(132, 2);
    canvas.drawPath(
      linea,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
