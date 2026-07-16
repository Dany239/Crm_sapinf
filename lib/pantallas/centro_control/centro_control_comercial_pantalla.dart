import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../viewmodels/centro_control_comercial_viewmodel.dart';

class CentroControlComercialPantalla extends StatefulWidget {
  const CentroControlComercialPantalla({super.key});

  @override
  State<CentroControlComercialPantalla> createState() =>
      _CentroControlComercialPantallaState();
}

class _CentroControlComercialPantallaState
    extends State<CentroControlComercialPantalla> {
  final CentroControlComercialViewModel viewModel =
      CentroControlComercialViewModel();

  @override
  void initState() {
    super.initState();
    viewModel.addListener(_actualizar);
    viewModel.inicializar();
  }

  @override
  void dispose() {
    viewModel.removeListener(_actualizar);
    viewModel.dispose();
    super.dispose();
  }

  void _actualizar() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (viewModel.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!viewModel.accesoPermitido) {
      return Scaffold(
        appBar: AppBar(title: const Text('Centro de Control Comercial')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Este módulo está disponible únicamente para administradores.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(
          'Centro de Control Comercial',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: viewModel.recargar,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _encabezado(),
            const SizedBox(height: 18),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.04,
              children: [
                _tarjetaMetrica(
                  titulo: 'Conectados',
                  valor: '${viewModel.vendedoresConectados.length}',
                  detalle: 'Vendedores activos',
                  icono: Icons.circle,
                  color: Colors.green,
                ),
                _tarjetaMetrica(
                  titulo: 'Seguimientos',
                  valor: '${viewModel.seguimientosDeHoy.length}',
                  detalle: 'Realizados hoy',
                  icono: Icons.phone_in_talk_rounded,
                  color: Colors.orange,
                ),
                _tarjetaMetrica(
                  titulo: 'Ventas del día',
                  valor: '${viewModel.ventasDeHoy.length}',
                  detalle: viewModel.formatoLempiras(viewModel.totalVentasHoy),
                  icono: Icons.trending_up_rounded,
                  color: Colors.teal,
                ),
                _tarjetaMetrica(
                  titulo: 'Sin seguimiento',
                  valor: '${viewModel.clientesSinSeguimiento.length}',
                  detalle: 'Clientes por atender',
                  icono: Icons.schedule_rounded,
                  color: Colors.deepOrange,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _tituloSeccion(
              'Vendedores conectados',
              Icons.people_alt_rounded,
              Colors.green,
            ),
            const SizedBox(height: 10),
            _listaVendedoresConectados(),
            const SizedBox(height: 22),
            _tituloSeccion(
              'Ranking del mes',
              Icons.emoji_events_rounded,
              const Color(0xFFFFA000),
            ),
            const SizedBox(height: 10),
            _listaRanking(),
            const SizedBox(height: 22),
            _tituloSeccion(
              'Clientes sin seguimiento',
              Icons.timer_off_outlined,
              Colors.deepOrange,
            ),
            const SizedBox(height: 10),
            _listaClientesSinSeguimiento(),
            const SizedBox(height: 22),
            _tituloSeccion(
              'Alertas importantes',
              Icons.warning_amber_rounded,
              Colors.red,
            ),
            const SizedBox(height: 10),
            _listaAlertas(),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.monitor_heart_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            'Operación comercial en vivo',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Información actualizada automáticamente desde Firebase.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tarjetaMetrica({
    required String titulo,
    required String valor,
    required String detalle,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, color: color, size: 26),
          const Spacer(),
          Text(
            valor,
            style: GoogleFonts.poppins(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            detalle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tituloSeccion(String titulo, IconData icono, Color color) {
    return Row(
      children: [
        Icon(icono, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            titulo,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _listaVendedoresConectados() {
    final vendedores = viewModel.vendedoresConectados;
    if (vendedores.isEmpty) {
      return _estadoVacio('No hay vendedores conectados en este momento.');
    }

    return Column(
      children: vendedores.map((doc) {
        final data = doc.data;
        return _fila(
          icono: Icons.person_rounded,
          color: Colors.green,
          titulo: data['nombre']?.toString() ?? 'Vendedor',
          subtitulo: 'Activo ahora',
          indicador: true,
        );
      }).toList(),
    );
  }

  Widget _listaRanking() {
    final ranking = viewModel.rankingMensual.take(5).toList();
    if (ranking.isEmpty) {
      return _estadoVacio('Todavía no hay ventas registradas este mes.');
    }

    return Column(
      children: ranking.asMap().entries.map((entry) {
        final posicion = entry.key + 1;
        return _fila(
          icono: posicion == 1
              ? Icons.emoji_events_rounded
              : Icons.workspace_premium_rounded,
          color: posicion == 1 ? const Color(0xFFFFA000) : Colors.blueGrey,
          titulo: '$posicion. ${entry.value.nombre}',
          subtitulo: '${entry.value.ventas} ventas',
          valor: viewModel.formatoLempiras(entry.value.monto),
        );
      }).toList(),
    );
  }

  Widget _listaClientesSinSeguimiento() {
    final pendientes = viewModel.clientesSinSeguimiento.take(5).toList();
    if (pendientes.isEmpty) {
      return _estadoVacio('Todos los clientes tienen seguimiento registrado.');
    }

    return Column(
      children: [
        ...pendientes.map((doc) {
          final data = doc.data;
          return _fila(
            icono: Icons.person_search_rounded,
            color: Colors.deepOrange,
            titulo: data['nombre']?.toString() ?? 'Cliente sin nombre',
            subtitulo:
                data['vendedorNombre']?.toString() ?? 'Sin vendedor asignado',
          );
        }),
        if (viewModel.clientesSinSeguimiento.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+ ${viewModel.clientesSinSeguimiento.length - 5} clientes más',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _listaAlertas() {
    final alertas = viewModel.alertasPendientes.take(5).toList();
    if (alertas.isEmpty) {
      return _estadoVacio('No hay alertas pendientes. Todo está bajo control.');
    }

    return Column(
      children: alertas.map((doc) {
        final data = doc.data;
        return _fila(
          icono: Icons.notification_important_rounded,
          color: Colors.red,
          titulo: data['titulo']?.toString() ?? 'Alerta',
          subtitulo: data['descripcion']?.toString() ?? 'Requiere atención',
        );
      }).toList(),
    );
  }

  Widget _fila({
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    String? valor,
    bool indicador = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icono, color: color, size: 22),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (indicador)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          if (valor != null)
            Text(
              valor,
              style: GoogleFonts.poppins(
                color: const Color(0xFF1565C0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  Widget _estadoVacio(String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5EAF1)),
      ),
      child: Text(
        mensaje,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
      ),
    );
  }
}
