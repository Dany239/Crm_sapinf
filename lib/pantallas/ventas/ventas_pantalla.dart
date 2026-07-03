import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'agregar_venta_pantalla.dart';
import 'editar_venta_pantalla.dart';
import '../../servicios/sesion_usuario.dart';

class VentasPantalla extends StatefulWidget {
  final String? estadoInicial;

  const VentasPantalla({
    super.key,
    this.estadoInicial,
  });

  @override
  State<VentasPantalla> createState() => _VentasPantallaState();
}

class _VentasPantallaState extends State<VentasPantalla> {
  final buscarController = TextEditingController();
  String textoBusqueda = '';
  late Future<SesionUsuario> sesionFuture;

  @override
  void initState() {
    super.initState();
    sesionFuture = obtenerSesionUsuario();
  }

  @override
  void dispose() {
    buscarController.dispose();
    super.dispose();
  }

  String formatoLempiras(dynamic valor) {
    final monto = num.tryParse(valor?.toString() ?? '0') ?? 0;
    final formato = NumberFormat.currency(
      locale: 'en_US',
      symbol: 'L. ',
      decimalDigits: 0,
    );

    return formato.format(monto);
  }

  String fechaCorta(dynamic valor) {
    if (valor is! Timestamp) return 'Sin fecha';
    return DateFormat('dd/MM/yyyy').format(valor.toDate());
  }

  Color colorEstado(String estado) {
    switch (estado) {
      case 'Cerrada':
        return Colors.green;
      case 'En proceso':
        return const Color(0xFF1565C0);
      case 'Cancelada':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData iconoEstado(String estado) {
    switch (estado) {
      case 'Cerrada':
        return Icons.check_circle;
      case 'En proceso':
        return Icons.sync;
      case 'Cancelada':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  void abrirAgregarVenta() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AgregarVentaPantalla(),
      ),
    );
  }

  Widget encabezadoVentas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1565C0),
            Color(0xFF29B6F6),
          ],
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
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.point_of_sale,
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
                  'Ventas',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consulta y administra tus oportunidades',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget buscadorVentas() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: TextField(
        controller: buscarController,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar venta...',
          hintStyle: GoogleFonts.poppins(
            color: Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF1565C0),
          ),
          suffixIcon: textoBusqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    buscarController.clear();
                    setState(() {
                      textoBusqueda = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (valor) {
          setState(() {
            textoBusqueda = valor.toLowerCase();
          });
        },
      ),
    );
  }

  Widget tarjetaVenta({
    required String ventaId,
    required Map<String, dynamic> venta,
  }) {
    final cliente = venta['cliente']?.toString() ?? 'Sin cliente';
    final servicio = venta['servicio']?.toString() ?? 'Sin servicio';
    final estado = venta['estado']?.toString() ?? 'Pendiente';
    final vendedor =
        venta['vendedorNombre']?.toString() ?? 'Sin vendedor asignado';
    final color = colorEstado(estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
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
              builder: (context) => EditarVentaPantalla(
                ventaId: ventaId,
                venta: venta,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: color,
                  size: 27,
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
                            cliente,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                iconoEstado(estado),
                                size: 13,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                estado,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      servicio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$vendedor \u00b7 ${fechaCorta(venta['fechaRegistro'])}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF1565C0),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          formatoLempiras(venta['monto']),
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.grey.shade400,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: Color(0xFF1565C0),
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'No se encontraron ventas',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Prueba con otro cliente, servicio o estado.',
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

  List<QueryDocumentSnapshot> filtrarVentas(
    List<QueryDocumentSnapshot> docs,
    SesionUsuario sesion,
  ) {
    return docs.where((doc) {
      final venta = doc.data() as Map<String, dynamic>;

      if (!sesion.esAdministrador && venta['vendedorId'] != sesion.uid) {
        return false;
      }
      if (widget.estadoInicial != null &&
          venta['estado'] != widget.estadoInicial) {
        return false;
      }

      final cliente = (venta['cliente'] ?? '').toString().toLowerCase();
      final servicio = (venta['servicio'] ?? '').toString().toLowerCase();
      final estado = (venta['estado'] ?? '').toString().toLowerCase();
      final monto = (venta['monto'] ?? '').toString().toLowerCase();

      return cliente.contains(textoBusqueda) ||
          servicio.contains(textoBusqueda) ||
          estado.contains(textoBusqueda) ||
          monto.contains(textoBusqueda);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Venta',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        onPressed: abrirAgregarVenta,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Column(
                children: [
                  encabezadoVentas(),
                  buscadorVentas(),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<SesionUsuario>(
                future: sesionFuture,
                builder: (context, sesionSnapshot) {
                  if (!sesionSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sesion = sesionSnapshot.data!;

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('ventas')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final ventas = filtrarVentas(snapshot.data!.docs, sesion);

                      if (ventas.isEmpty) {
                        return estadoVacio();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
                        itemCount: ventas.length,
                        itemBuilder: (context, index) {
                          final venta =
                              ventas[index].data() as Map<String, dynamic>;

                          return tarjetaVenta(
                            ventaId: ventas[index].id,
                            venta: venta,
                          );
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
  }
}
