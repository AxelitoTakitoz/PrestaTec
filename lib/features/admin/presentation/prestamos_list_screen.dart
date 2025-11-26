// lib/features/admin/presentation/prestamos_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrestamosListScreen extends StatefulWidget {
  const PrestamosListScreen({super.key});

  @override
  State<PrestamosListScreen> createState() => _PrestamosListScreenState();
}

class _PrestamosListScreenState extends State<PrestamosListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroEstado = 'todos'; // todos, activo, devuelto, cancelado

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getPrestamosStream() {
    Query query = FirebaseFirestore.instance.collection('prestamos');

    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      query = query.where('estado', isEqualTo: _filtroEstado);
    }

    // Ordenar por fecha más reciente
    query = query.orderBy('fechaPrestamo', descending: true);

    return query.snapshots();
  }

  List<Map<String, dynamic>> _filterPrestamos(
      List<Map<String, dynamic>> prestamos) {
    if (_searchQuery.isEmpty) return prestamos;

    final q = _searchQuery.toLowerCase();
    return prestamos.where((p) {
      final nombre = (p['nombreCompleto'] ?? '').toString().toLowerCase();
      final numeroControl =
      (p['numeroControl'] ?? '').toString().toLowerCase();
      final material =
      (p['materialDescripcion'] ?? '').toString().toLowerCase();

      return nombre.contains(q) ||
          numeroControl.contains(q) ||
          material.contains(q);
    }).toList();
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Colors.green;
      case 'devuelto':
        return Colors.blue;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return Icons.pending_actions;
      case 'devuelto':
        return Icons.check_circle;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  Future<void> _marcarComoDevuelto(
      String prestamoId, Map<String, dynamic> prestamoData) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text(
          '¿Marcar como devuelto?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Usuario: ${prestamoData['nombreCompleto']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Material: ${prestamoData['materialDescripcion']}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Se incrementará la cantidad del material en el inventario.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final materialRef = FirebaseFirestore.instance
          .collection('materiales')
          .doc(prestamoData['materialId']);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        // Actualizar préstamo
        final prestamoRef =
        FirebaseFirestore.instance.collection('prestamos').doc(prestamoId);
        tx.update(prestamoRef, {
          'estado': 'devuelto',
          'fechaDevolucion': FieldValue.serverTimestamp(),
        });

        // Incrementar cantidad del material
        final matSnap = await tx.get(materialRef);
        if (matSnap.exists) {
          final data = matSnap.data()!;
          final cantidadActual = _toInt(data['cantidad'] ?? 0);
          tx.update(materialRef, {'cantidad': cantidadActual + 1});
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material marcado como devuelto'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D3E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text('Gestión de Préstamos'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, control o material...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1A2540).withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filtros de estado
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFiltroChip('Todos', 'todos'),
                const SizedBox(width: 8),
                _buildFiltroChip('Activos', 'activo'),
                const SizedBox(width: 8),
                _buildFiltroChip('Devueltos', 'devuelto'),
                const SizedBox(width: 8),
                _buildFiltroChip('Cancelados', 'cancelado'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de préstamos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getPrestamosStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay préstamos registrados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final prestamos = snapshot.data!.docs
                    .map((doc) => {
                  'id': doc.id,
                  ...doc.data() as Map<String, dynamic>,
                })
                    .toList();

                final filteredPrestamos = _filterPrestamos(prestamos);

                if (filteredPrestamos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron resultados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPrestamos.length,
                  itemBuilder: (context, index) {
                    final prestamo = filteredPrestamos[index];
                    return _buildPrestamoCard(prestamo);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String value) {
    final isSelected = _filtroEstado == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filtroEstado = value);
      },
      backgroundColor: const Color(0xFF1A2540),
      selectedColor: const Color(0xFF2F6BFF),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2F6BFF) : Colors.white24,
      ),
    );
  }

  Widget _buildPrestamoCard(Map<String, dynamic> prestamo) {
    final estado = prestamo['estado'] ?? 'desconocido';
    final estadoColor = _getEstadoColor(estado);
    final estadoIcon = _getEstadoIcon(estado);

    return Card(
      color: const Color(0xFF1A2540),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, size: 16, color: estadoColor),
                      const SizedBox(width: 6),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          color: estadoColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (estado == 'activo')
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    tooltip: 'Marcar como devuelto',
                    onPressed: () =>
                        _marcarComoDevuelto(prestamo['id'], prestamo),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Información del usuario
            _buildInfoRow(
              Icons.person,
              'Usuario',
              prestamo['nombreCompleto'] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.badge,
              'Núm. Control',
              prestamo['numeroControl'] ?? 'N/A',
            ),

            const Divider(color: Colors.white24, height: 24),

            // Información del material
            _buildInfoRow(
              Icons.inventory_2,
              'Material',
              prestamo['materialDescripcion'] ?? 'N/A',
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.tag,
              'ID Material',
              prestamo['materialId'] ?? 'N/A',
            ),

            const Divider(color: Colors.white24, height: 24),

            // Fechas
            _buildInfoRow(
              Icons.calendar_today,
              'Fecha préstamo',
              _formatDate(prestamo['fechaPrestamo']),
            ),
            if (prestamo['fechaDevolucion'] != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.event_available,
                'Fecha devolución',
                _formatDate(prestamo['fechaDevolucion']),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}