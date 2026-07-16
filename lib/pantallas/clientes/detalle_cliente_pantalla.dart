import 'package:flutter/material.dart';

import '../seguimientos/agregar_seguimiento_pantalla.dart';
import '../ventas/agregar_venta_pantalla.dart';
import '../../viewmodels/detalle_cliente_viewmodel.dart';

class DetalleClientePantalla extends StatefulWidget {
  final String clienteId;
  final Map<String, dynamic> cliente;

  const DetalleClientePantalla({
    super.key,
    required this.clienteId,
    required this.cliente,
  });

  @override
  State<DetalleClientePantalla> createState() => _DetalleClientePantallaState();
}

class _DetalleClientePantallaState extends State<DetalleClientePantalla> {
  late final DetalleClienteViewModel viewModel;

  String get clienteId => widget.clienteId;
  Map<String, dynamic> get cliente => widget.cliente;

  @override
  void initState() {
    super.initState();
    viewModel = DetalleClienteViewModel(
      clienteId: widget.clienteId,
      datosCliente: widget.cliente,
    );
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Widget tarjetaResumen({
    required String titulo,
    required String valor,
    required IconData icono,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icono, color: color, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> convertirEnCliente(BuildContext context) async {
    final convertido = await viewModel.convertirEnCliente();

    if (!context.mounted) return;

    if (!convertido) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.mensajeError ?? 'No se pudo convertir el cliente',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cliente potencial convertido en cliente')),
    );

    Navigator.pop(context);
  }

  Future<void> abrirTelefono(BuildContext context, String telefono) async {
    final mensaje = await viewModel.abrirTelefono(telefono);

    if (!context.mounted) return;

    if (mensaje != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> abrirWhatsApp(BuildContext context, String telefono) async {
    final mensaje = await viewModel.abrirWhatsApp(telefono);

    if (!context.mounted) return;

    if (mensaje != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  Future<void> abrirCorreo(BuildContext context, String correo) async {
    final mensaje = await viewModel.abrirCorreo(correo);

    if (!context.mounted) return;

    if (mensaje != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(mensaje)));
    }
  }

  void abrirNuevoSeguimiento(BuildContext context, String nombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarSeguimientoPantalla(
          clienteIdInicial: clienteId,
          clienteNombreInicial: nombre,
        ),
      ),
    );
  }

  void abrirNuevaVenta(BuildContext context, String nombre) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarVentaPantalla(
          clienteIdInicial: clienteId,
          clienteNombreInicial: nombre,
        ),
      ),
    );
  }

  Future<void> eliminarCliente(BuildContext context, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar registro'),
          content: Text(
            '\u00bfSeguro que deseas eliminar a $nombre? Esta acci\u00f3n no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    final eliminado = await viewModel.eliminarCliente();

    if (!context.mounted) return;

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
      SnackBar(content: Text('$nombre fue eliminado correctamente')),
    );
    Navigator.pop(context);
  }

  Widget timelineCliente(String nombre, {required bool incluirVentas}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: viewModel.ventasStream,
      builder: (context, ventasSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: viewModel.seguimientosStream,
          builder: (context, seguimientosSnapshot) {
            if (!ventasSnapshot.hasData || !seguimientosSnapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final actividades = viewModel.crearTimeline(
              ventas: ventasSnapshot.data ?? [],
              seguimientos: seguimientosSnapshot.data ?? [],
              incluirVentas: incluirVentas,
            );

            if (actividades.isEmpty) {
              return const Card(
                child: ListTile(title: Text('No hay historial registrado')),
              );
            }

            return Column(
              children: actividades.map((actividad) {
                final esVenta = actividad['tipo'] == 'venta';
                final fecha = actividad['fecha'] as DateTime;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: esVenta
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      child: Icon(
                        esVenta ? Icons.attach_money : Icons.phone,
                        color: esVenta ? Colors.green : Colors.orange,
                      ),
                    ),
                    title: Text(
                      actividad['titulo'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${actividad['detalle']}\n${fecha.day}/${fecha.month}/${fecha.year}',
                    ),
                    trailing: esVenta
                        ? Text(
                            viewModel.formatoLempiras(actividad['monto']),
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : Text(
                            actividad['estado'],
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombre = cliente['nombre'] ?? 'Sin nombre';
    final empresa = cliente['empresa'] ?? 'Sin empresa';
    final telefono = cliente['telefono'] ?? 'Sin teléfono';
    final correo = cliente['correo'] ?? 'Sin correo';
    final direccion = cliente['direccion']?.toString() ?? '';
    final estadoCliente =
        cliente['estadoCliente']?.toString() ?? 'Cliente potencial';
    final esCliente = estadoCliente == 'Cliente';
    final colorEstado = esCliente ? Colors.green : Colors.orange;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: const Color(0xFF1F2937),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Perfil comercial',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              estadoCliente,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            onPressed: () => eliminarCliente(context, nombre),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_seguimiento_$clienteId',
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
            onPressed: () => abrirNuevoSeguimiento(context, nombre),
            icon: const Icon(Icons.add_task),
            label: const Text('Seguimiento'),
          ),
          if (esCliente) ...[
            const SizedBox(height: 10),
            FloatingActionButton.extended(
              heroTag: 'fab_venta_$clienteId',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              onPressed: () => abrirNuevaVenta(context, nombre),
              icon: const Icon(Icons.attach_money),
              label: const Text('Venta'),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 120),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF29B6F6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          esCliente ? Icons.verified_user : Icons.person_add,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              empresa,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.84),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            esCliente ? Icons.verified : Icons.person_add,
                            size: 17,
                            color: colorEstado,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            estadoCliente,
                            style: TextStyle(
                              color: colorEstado.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => abrirTelefono(context, telefono),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Teléfono',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  telefono,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => abrirWhatsApp(context, telefono),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.chat_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'WhatsApp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => abrirCorreo(context, correo),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.email,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Correo',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  correo,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (direccion.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  direccion,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (estadoCliente != 'Cliente') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () => convertirEnCliente(context),
                  icon: const Icon(Icons.verified),
                  label: const Text('Convertir en cliente'),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (esCliente) ...[
              const SizedBox(height: 25),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resumen del cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: viewModel.ventasStream,
                builder: (context, ventasSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: viewModel.seguimientosStream,
                    builder: (context, seguimientosSnapshot) {
                      if (!ventasSnapshot.hasData ||
                          !seguimientosSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final resumen = viewModel.calcularResumen(
                        ventas: ventasSnapshot.data ?? [],
                        seguimientos: seguimientosSnapshot.data ?? [],
                      );

                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.05,
                        children: [
                          tarjetaResumen(
                            titulo: 'Total comprado',
                            valor: viewModel.formatoLempiras(
                              resumen.totalComprado,
                            ),
                            icono: Icons.payments,
                            color: Colors.green,
                          ),
                          tarjetaResumen(
                            titulo: 'Ventas',
                            valor: '${resumen.cantidadVentas}',
                            icono: Icons.shopping_cart,
                            color: const Color(0xFF1565C0),
                          ),
                          tarjetaResumen(
                            titulo: 'Seguimientos',
                            valor: '${resumen.cantidadSeguimientos}',
                            icono: Icons.phone_in_talk,
                            color: Colors.orange,
                          ),
                          tarjetaResumen(
                            titulo: 'Última venta',
                            valor: viewModel.formatearFecha(
                              resumen.ultimaVentaFecha,
                            ),
                            icono: Icons.calendar_month,
                            color: Colors.purple,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                'Historial',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            timelineCliente(nombre, incluirVentas: esCliente),
            if (esCliente) ...[
              const SizedBox(height: 25),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ventas del cliente',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: viewModel.ventasStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    );
                  }

                  final ventas = snapshot.data ?? [];

                  if (ventas.isEmpty) {
                    return const Card(
                      child: ListTile(title: Text('No hay ventas registradas')),
                    );
                  }

                  return Column(
                    children: ventas.map((venta) {
                      final montoVenta =
                          double.tryParse(venta['monto'].toString()) ?? 0;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.green.shade50,
                                child: const Icon(
                                  Icons.attach_money,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  venta['servicio'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                viewModel.formatoLempiras(montoVenta),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                esCliente ? 'Seguimientos del cliente' : 'Seguimiento',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: viewModel.seguimientosStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  );
                }

                final seguimientos = snapshot.data ?? [];

                if (seguimientos.isEmpty) {
                  return const Card(
                    child: ListTile(
                      title: Text('No hay seguimientos registrados'),
                    ),
                  );
                }

                return Column(
                  children: seguimientos.map((seguimiento) {
                    IconData icono;
                    Color colorEstado;

                    switch (seguimiento['tipo']) {
                      case 'Correo':
                        icono = Icons.email;
                        break;

                      case 'Llamada':
                        icono = Icons.phone;
                        break;

                      case 'WhatsApp':
                      case 'Mensaje':
                        icono = Icons.chat;
                        break;

                      case 'Visita':
                        icono = Icons.location_on;
                        break;

                      default:
                        icono = Icons.notifications;
                    }

                    switch (seguimiento['estado']) {
                      case 'Pendiente':
                        colorEstado = Colors.green;
                        break;

                      case 'En proceso':
                        colorEstado = Colors.orange;
                        break;

                      case 'Realizado':
                        colorEstado = const Color(0xFF1565C0);
                        break;

                      case 'Cancelado':
                        colorEstado = Colors.red;
                        break;

                      default:
                        colorEstado = Colors.grey;
                    }

                    final fechaActividad = seguimiento['estado'] == 'Realizado'
                        ? seguimiento['fechaRealizacion']
                        : seguimiento['fechaProxima'];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.orange.shade100,
                                child: Icon(icono, color: Colors.orange),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        icono,
                                        color: Colors.orange,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        seguimiento['tipo'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    seguimiento['comentario'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Estado',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorEstado.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      seguimiento['estado'] ?? '',
                                      style: TextStyle(
                                        color: colorEstado,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Próxima gestión',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        viewModel.formatearFechaHora(
                                          fechaActividad,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
