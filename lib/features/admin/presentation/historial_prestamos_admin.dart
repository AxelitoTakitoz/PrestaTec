import 'package:flutter/material.dart';

// Modelo de préstamo (deberías tenerlo en una carpeta models)
class Prestamo {
  final int id;
  final String nombreUsuario;
  final String nombreMaterial;
  final DateTime fechaPrestamo;
  final DateTime? fechaDevolucion;
  final String estado; // "Pendiente", "Activo", "Devuelto", etc.

  Prestamo({
    required this.id,
    required this.nombreUsuario,
    required this.nombreMaterial,
    required this.fechaPrestamo,
    this.fechaDevolucion,
    required this.estado,
  });
}

class AdminHistorialPrestamosScreen extends StatefulWidget {
  const AdminHistorialPrestamosScreen({super.key});

  @override
  State<AdminHistorialPrestamosScreen> createState() => _AdminHistorialPrestamosScreenState();
}

class _AdminHistorialPrestamosScreenState extends State<AdminHistorialPrestamosScreen> {
  List<Prestamo> listaPrestamos = []; // Inicialmente vacía

  @override
  void initState() {
    super.initState();
    // ❌ Comentamos o eliminamos la carga inicial de datos simulados
    // _cargarHistorial();
  }

  // ❌ Opcional: puedes eliminar este método si no lo vas a usar ahora
  // void _cargarHistorial() {
  //   setState(() {
  //     listaPrestamos = [
  //       Prestamo(
  //         id: 1,
  //         nombreUsuario: "Juan Pérez",
  //         nombreMaterial: "Laptop Dell XPS 15",
  //         fechaPrestamo: DateTime(2025, 10, 15),
  //         fechaDevolucion: DateTime(2025, 10, 20),
  //         estado: "Devuelto",
  //       ),
  //       // ... otros datos
  //     ];
  //   });
  // }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case "Devuelto":
        return Colors.green.shade600;
      case "Activo":
        return Colors.orange.shade600;
      case "Pendiente":
        return Colors.grey.shade600;
      default:
        return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Préstamos"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Opcional: Filtros (por estado, fechas, etc.)
            Container(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: "Buscar por usuario o material",
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.filter_list),
                    onSelected: (String value) {
                      // Aquí puedes aplicar el filtro
                      setState(() {
                        if (value == "todos") {
                          // _cargarHistorial(); // Si decides dejar esta funcionalidad, aquí puedes recargar
                        } else {
                          listaPrestamos = listaPrestamos.where((p) => p.estado == value).toList();
                        }
                      });
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem(value: "todos", child: Text("Todos")),
                      const PopupMenuItem(value: "Activo", child: Text("Activos")),
                      const PopupMenuItem(value: "Devuelto", child: Text("Devueltos")),
                      const PopupMenuItem(value: "Pendiente", child: Text("Pendientes")),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: listaPrestamos.isEmpty
                  ? const Center(
                child: Text(
                  "No hay préstamos registrados",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: listaPrestamos.length,
                itemBuilder: (context, index) {
                  final prestamo = listaPrestamos[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorEstado(prestamo.estado),
                        child: Icon(
                          prestamo.estado == "Activo" ? Icons.inventory_outlined : Icons.check_circle,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(prestamo.nombreMaterial),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Usuario: ${prestamo.nombreUsuario}"),
                          Text("Fecha préstamo: ${prestamo.fechaPrestamo.day}/${prestamo.fechaPrestamo.month}/${prestamo.fechaPrestamo.year}"),
                          if (prestamo.fechaDevolucion != null)
                            Text("Fecha devolución: ${prestamo.fechaDevolucion!.day}/${prestamo.fechaDevolucion!.month}/${prestamo.fechaDevolucion!.year}"),
                          Text("Estado: ${prestamo.estado}"),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: Colors.grey[600],
                      ),
                      onTap: () {
                        // Aquí puedes navegar a una pantalla de detalles
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetallePrestamoScreen(prestamo: prestamo),
                          ),
                        );
                      },
                    ),
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

// ✅ Pantalla de detalles del préstamo (ahora está definida fuera del State)
class DetallePrestamoScreen extends StatelessWidget {
  final Prestamo prestamo;

  const DetallePrestamoScreen({super.key, required this.prestamo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalles del préstamo"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailItem("ID:", prestamo.id.toString()),
            _buildDetailItem("Usuario:", prestamo.nombreUsuario),
            _buildDetailItem("Material:", prestamo.nombreMaterial),
            _buildDetailItem("Fecha préstamo:", "${prestamo.fechaPrestamo.day}/${prestamo.fechaPrestamo.month}/${prestamo.fechaPrestamo.year}"),
            _buildDetailItem("Fecha devolución:", prestamo.fechaDevolucion != null
                ? "${prestamo.fechaDevolucion!.day}/${prestamo.fechaDevolucion!.month}/${prestamo.fechaDevolucion!.year}"
                : "No devuelto"),
            _buildDetailItem("Estado:", prestamo.estado),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}