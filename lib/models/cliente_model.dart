class ClienteModel {
  final String? id;
  final String nombre;
  final String estadoCliente;
  final String? vendedorId;

  const ClienteModel({
    this.id,
    required this.nombre,
    required this.estadoCliente,
    this.vendedorId,
  });

  factory ClienteModel.fromMap(Map<String, dynamic> data, {String? id}) {
    return ClienteModel(
      id: id,
      nombre: data['nombre']?.toString() ?? 'Sin nombre',
      estadoCliente: data['estadoCliente']?.toString() ?? 'Cliente potencial',
      vendedorId: data['vendedorId']?.toString(),
    );
  }
}
