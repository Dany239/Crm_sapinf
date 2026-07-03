import 'package:excel/excel.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class DatosReporteExportacion {
  final List<Map<String, dynamic>> ventas;
  final List<Map<String, dynamic>> seguimientos;
  final List<Map<String, dynamic>> clientes;
  final String periodo;
  final String vendedor;

  const DatosReporteExportacion({
    required this.ventas,
    required this.seguimientos,
    required this.clientes,
    required this.periodo,
    required this.vendedor,
  });
}

class ExportacionReportesServicio {
  static final DateFormat _formatoFecha = DateFormat('dd/MM/yyyy');
  static final NumberFormat _formatoDinero = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'L. ',
    decimalDigits: 2,
  );

  static String _fecha(dynamic valor) {
    if (valor == null) return 'Sin fecha';
    try {
      return _formatoFecha.format(valor.toDate());
    } catch (_) {
      return 'Sin fecha';
    }
  }

  static double _monto(dynamic valor) {
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static Map<String, Map<String, dynamic>> _ranking(
    DatosReporteExportacion datos,
  ) {
    final ranking = <String, Map<String, dynamic>>{};
    for (final venta in datos.ventas) {
      final id = venta['vendedorId']?.toString() ?? 'sin-asignar';
      final fila = ranking.putIfAbsent(
        id,
        () => {
          'nombre':
              venta['vendedorNombre']?.toString() ?? 'Sin vendedor asignado',
          'ventas': 0,
          'monto': 0.0,
        },
      );
      fila['ventas'] = (fila['ventas'] as int) + 1;
      fila['monto'] = (fila['monto'] as double) + _monto(venta['monto']);
    }
    return ranking;
  }

  static Future<Uint8List> generarPdf(
    DatosReporteExportacion datos, {
    bool ejecutivo = false,
  }) async {
    final documento = pw.Document(
      title: ejecutivo ? 'Reporte Ejecutivo SAPINF' : 'Reporte Comercial SAPINF',
      author: 'SAPINF CRM',
    );
    final logoData = await rootBundle.load('assets/images/logo_sapinf.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final totalVentas = datos.ventas.fold<double>(
      0,
      (total, venta) => total + _monto(venta['monto']),
    );
    final seguimientosRealizados = datos.seguimientos
        .where((item) => item['estado'] == 'Realizado')
        .length;
    final ranking = _ranking(datos).values.toList()
      ..sort(
        (a, b) =>
            (b['monto'] as double).compareTo(a['monto'] as double),
      );

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        header: (context) => _encabezadoPdf(logo, datos, ejecutivo),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.blueGrey200),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'SAPINF CRM - Documento confidencial',
                style: const pw.TextStyle(
                  color: PdfColors.blueGrey600,
                  fontSize: 8,
                ),
              ),
              pw.Text(
                'Pagina ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  color: PdfColors.blueGrey600,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _kpiPdf('Ventas', '${datos.ventas.length}', PdfColors.green700),
              _kpiPdf(
                'Monto vendido',
                _formatoDinero.format(totalVentas),
                PdfColors.blue700,
              ),
              _kpiPdf(
                'Seguimientos',
                '${datos.seguimientos.length}',
                PdfColors.orange700,
              ),
              _kpiPdf(
                'Realizados',
                '$seguimientosRealizados',
                PdfColors.purple700,
              ),
              _kpiPdf(
                'Clientes',
                '${datos.clientes.length}',
                PdfColors.teal700,
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          _tituloPdf('Ranking comercial'),
          pw.SizedBox(height: 8),
          _tablaPdf(
            encabezados: const ['Pos.', 'Vendedor', 'Ventas', 'Monto'],
            filas: ranking.take(ejecutivo ? 5 : 10).toList().asMap().entries.map(
              (entry) {
                final item = entry.value;
                return [
                  '${entry.key + 1}',
                  item['nombre'].toString(),
                  item['ventas'].toString(),
                  _formatoDinero.format(item['monto']),
                ];
              },
            ).toList(),
          ),
          if (!ejecutivo) ...[
            pw.SizedBox(height: 22),
            _tituloPdf('Detalle de ventas'),
            pw.SizedBox(height: 8),
            _tablaPdf(
              encabezados: const [
                'Fecha',
                'Cliente',
                'Vendedor',
                'Servicio',
                'Estado',
                'Monto',
              ],
              filas: datos.ventas.map((venta) {
                return [
                  _fecha(venta['fechaRegistro']),
                  venta['cliente']?.toString() ?? 'Sin cliente',
                  venta['vendedorNombre']?.toString() ?? 'Sin vendedor',
                  venta['servicio']?.toString() ?? 'Sin servicio',
                  venta['estado']?.toString() ?? 'Sin estado',
                  _formatoDinero.format(_monto(venta['monto'])),
                ];
              }).toList(),
              tamanoFuente: 7,
            ),
            pw.SizedBox(height: 22),
            _tituloPdf('Seguimientos'),
            pw.SizedBox(height: 8),
            _tablaPdf(
              encabezados: const [
                'Fecha',
                'Cliente',
                'Vendedor',
                'Tipo',
                'Estado',
              ],
              filas: datos.seguimientos.map((seguimiento) {
                return [
                  _fecha(seguimiento['fechaRegistro']),
                  seguimiento['cliente']?.toString() ?? 'Sin cliente',
                  seguimiento['vendedorNombre']?.toString() ?? 'Sin vendedor',
                  seguimiento['tipo']?.toString() ?? 'Seguimiento',
                  seguimiento['estado']?.toString() ?? 'Sin estado',
                ];
              }).toList(),
              tamanoFuente: 7,
            ),
          ],
          if (ejecutivo) ...[
            pw.SizedBox(height: 22),
            _tituloPdf('Lectura ejecutiva'),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue100),
              ),
              child: pw.Text(
                _conclusionEjecutiva(
                  datos,
                  totalVentas,
                  seguimientosRealizados,
                  ranking,
                ),
                style: const pw.TextStyle(
                  fontSize: 10,
                  lineSpacing: 4,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return documento.save();
  }

  static pw.Widget _encabezadoPdf(
    pw.MemoryImage logo,
    DatosReporteExportacion datos,
    bool ejecutivo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue700, width: 2),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 62,
            height: 62,
            padding: const pw.EdgeInsets.all(3),
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  ejecutivo ? 'REPORTE EJECUTIVO' : 'REPORTE COMERCIAL',
                  style: pw.TextStyle(
                    color: PdfColors.blue800,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Periodo: ${datos.periodo}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Vendedor: ${datos.vendedor}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.blueGrey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _kpiPdf(String titulo, String valor, PdfColor color) {
    return pw.Container(
      width: 145,
      padding: const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(7),
        border: pw.Border.all(color: color.shade(0.75)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.blueGrey600,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tituloPdf(String texto) {
    return pw.Text(
      texto,
      style: pw.TextStyle(
        color: PdfColors.blue800,
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
      ),
    );
  }

  static pw.Widget _tablaPdf({
    required List<String> encabezados,
    required List<List<String>> filas,
    double tamanoFuente = 8,
  }) {
    if (filas.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(12),
        color: PdfColors.grey100,
        child: pw.Text(
          'No hay datos para los filtros seleccionados.',
          style: const pw.TextStyle(fontSize: 9),
        ),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: encabezados,
      data: filas,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: tamanoFuente,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: pw.TextStyle(fontSize: tamanoFuente),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
      border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
    );
  }

  static String _conclusionEjecutiva(
    DatosReporteExportacion datos,
    double totalVentas,
    int seguimientosRealizados,
    List<Map<String, dynamic>> ranking,
  ) {
    final lider = ranking.isEmpty
        ? 'No hay vendedor lider en el periodo'
        : 'El mejor resultado corresponde a ${ranking.first['nombre']} con '
            '${_formatoDinero.format(ranking.first['monto'])}';
    final cumplimiento = datos.seguimientos.isEmpty
        ? 0
        : (seguimientosRealizados * 100 / datos.seguimientos.length).round();

    return 'Durante ${datos.periodo} se registraron ${datos.ventas.length} '
        'ventas por un total de ${_formatoDinero.format(totalVentas)}. '
        'El equipo completo $seguimientosRealizados de '
        '${datos.seguimientos.length} seguimientos ($cumplimiento%). '
        '$lider. La cartera incluida en este reporte contiene '
        '${datos.clientes.length} clientes.';
  }

  static Uint8List generarExcel(DatosReporteExportacion datos) {
    final libro = Excel.createExcel();
    libro.rename('Sheet1', 'Resumen');
    final resumen = libro['Resumen'];
    final ventas = libro['Ventas'];
    final seguimientos = libro['Seguimientos'];
    final clientes = libro['Clientes'];

    final estiloTitulo = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.white,
      backgroundColorHex: ExcelColor.blue800,
      horizontalAlign: HorizontalAlign.Center,
    );

    resumen.appendRow([TextCellValue('REPORTE COMERCIAL SAPINF')]);
    resumen.appendRow([
      TextCellValue('Periodo'),
      TextCellValue(datos.periodo),
    ]);
    resumen.appendRow([
      TextCellValue('Vendedor'),
      TextCellValue(datos.vendedor),
    ]);
    resumen.appendRow([
      TextCellValue('Ventas'),
      IntCellValue(datos.ventas.length),
    ]);
    resumen.appendRow([
      TextCellValue('Monto total'),
      DoubleCellValue(
        datos.ventas.fold<double>(
          0,
          (total, venta) => total + _monto(venta['monto']),
        ),
      ),
    ]);
    resumen.appendRow([
      TextCellValue('Seguimientos'),
      IntCellValue(datos.seguimientos.length),
    ]);
    resumen.appendRow([
      TextCellValue('Clientes'),
      IntCellValue(datos.clientes.length),
    ]);

    _agregarHoja(
      ventas,
      const ['Fecha', 'Cliente', 'Vendedor', 'Servicio', 'Estado', 'Monto'],
      datos.ventas.map((venta) {
        return [
          _fecha(venta['fechaRegistro']),
          venta['cliente']?.toString() ?? '',
          venta['vendedorNombre']?.toString() ?? '',
          venta['servicio']?.toString() ?? '',
          venta['estado']?.toString() ?? '',
          _monto(venta['monto']),
        ];
      }).toList(),
      estiloTitulo,
    );
    _agregarHoja(
      seguimientos,
      const ['Fecha', 'Cliente', 'Vendedor', 'Tipo', 'Estado', 'Comentario'],
      datos.seguimientos.map((seguimiento) {
        return [
          _fecha(seguimiento['fechaRegistro']),
          seguimiento['cliente']?.toString() ?? '',
          seguimiento['vendedorNombre']?.toString() ?? '',
          seguimiento['tipo']?.toString() ?? '',
          seguimiento['estado']?.toString() ?? '',
          seguimiento['comentario']?.toString() ?? '',
        ];
      }).toList(),
      estiloTitulo,
    );
    _agregarHoja(
      clientes,
      const ['Fecha', 'Cliente', 'Vendedor', 'Correo', 'Telefono', 'Estado'],
      datos.clientes.map((cliente) {
        return [
          _fecha(cliente['fechaRegistro']),
          cliente['nombre']?.toString() ?? '',
          cliente['vendedorNombre']?.toString() ?? '',
          cliente['correo']?.toString() ?? '',
          cliente['telefono']?.toString() ?? '',
          cliente['estadoCliente']?.toString() ?? '',
        ];
      }).toList(),
      estiloTitulo,
    );

    for (var columna = 0; columna < 6; columna++) {
      ventas.setColumnWidth(columna, columna == 1 ? 24 : 18);
      seguimientos.setColumnWidth(columna, columna == 5 ? 32 : 18);
      clientes.setColumnWidth(columna, columna == 1 ? 24 : 18);
    }
    resumen.setColumnWidth(0, 22);
    resumen.setColumnWidth(1, 30);

    final bytes = libro.save();
    if (bytes == null) {
      throw StateError('No se pudo generar el archivo Excel.');
    }
    return Uint8List.fromList(bytes);
  }

  static void _agregarHoja(
    Sheet hoja,
    List<String> encabezados,
    List<List<dynamic>> filas,
    CellStyle estiloTitulo,
  ) {
    hoja.appendRow(encabezados.map(TextCellValue.new).toList());
    for (var columna = 0; columna < encabezados.length; columna++) {
      hoja
          .cell(
            CellIndex.indexByColumnRow(
              columnIndex: columna,
              rowIndex: 0,
            ),
          )
          .cellStyle = estiloTitulo;
    }

    for (final fila in filas) {
      hoja.appendRow(
        fila.map<CellValue>((valor) {
          if (valor is int) return IntCellValue(valor);
          if (valor is double) return DoubleCellValue(valor);
          return TextCellValue(valor.toString());
        }).toList(),
      );
    }
  }

  static Future<void> compartir({
    required Uint8List bytes,
    required String nombreArchivo,
    required String mimeType,
    required String periodo,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: mimeType,
          ),
        ],
        fileNameOverrides: [nombreArchivo],
        title: 'Reporte comercial SAPINF',
        subject: 'Reporte comercial SAPINF - $periodo',
        text:
            'Adjunto el reporte comercial de SAPINF correspondiente a $periodo.',
      ),
    );
  }
}
