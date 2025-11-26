// lib/features/admin/presentation/historial_prestamos_admin.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHistorialPrestamosScreen extends StatefulWidget {
  const AdminHistorialPrestamosScreen({super.key});

  @override
  State<AdminHistorialPrestamosScreen> createState() =>
      _AdminHistorialPrestamosScreenState();
}

class _AdminHistorialPrestamosScreenState
    extends State<AdminHistorialPrestamosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filtroEstado = 'todos';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getPrestamosStream() {
    Query query = FirebaseFirestore.instance.collection('prestamos');

    if (_filtroEstado != 'todos') {
      query = query.where('estado', isEqualTo: _filtroEstado);
    }

    return query.orderBy('fechaPrestamo', descending: true).snapshots();
  }

  List<Map<String, dynamic>> _filterPrestamos(
      List<Map<String, dynamic>> prestamos) {
    if (_searchQuery.isEmpty) return prestamos;

    final q = _searchQuery.toLowerCase();

    return prestamos.where((p) {
      return (p['nombreCompleto'] ?? '').toString().toLowerCase().contains(q) ||
          (p['numeroControl'] ?? '').toString().toLowerCase().contains(q) ||
          (p['materialDescripcion'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q);
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
      final d = (timestamp as Timestamp).toDate();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}'
          ' ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Fecha inválida';
    }
  }

  Future<void> _marcarComoDevuelto(
      String id, Map<String, dynamic> data) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text('¿Marcar como devuelto?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Esto incrementará la cantidad del material.',
          style: const TextStyle(color: Colors.white70),
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

    if (confirmar != true) return;

    try {
      final matRef = FirebaseFirestore.instance
          .collection('materiales')
          .doc(data['materialId']);

      await FirebaseFirestore.instance.runTransaction((tx) async {
        tx.update(
          FirebaseFirestore.instance.collection('prestamos').doc(id),
          {
            'estado': 'devuelto',
            'fechaDevolucion': FieldValue.serverTimestamp(),
          },
        );

        final snap = await tx.get(matRef);
        final cantidadActual =
            int.tryParse(snap.data()?['cantidad'].toString() ?? '0') ?? 0;

        tx.update(matRef, {'cantidad': cantidadActual + 1});
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
          // Buscador
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
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Filtros
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

          // Lista
          Expanded(
            child: StreamBuilder(
              stream: _getPrestamosStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.white));
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay préstamos registrados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final prestamos = docs
                    .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
                    .toList();

                final filtrados = _filterPrestamos(prestamos);

                if (filtrados.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron resultados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtrados.length,
                  itemBuilder: (c, i) =>
                      _buildPrestamoCard(filtrados[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String value) {
    final selected = _filtroEstado == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filtroEstado = value),
      backgroundColor: const Color(0xFF1A2540),
      selectedColor: const Color(0xFF2F6BFF),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF2F6BFF) : Colors.white24,
      ),
    );
  }

  Widget _buildPrestamoCard(Map<String, dynamic> p) {
    final estado = p['estado'] ?? 'desconocido';

    return Card(
      color: const Color(0xFF1A2540),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Etiqueta de estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(estado).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                    Border.all(color: _getEstadoColor(estado)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getEstadoIcon(estado),
                          size: 16, color: _getEstadoColor(estado)),
                      const SizedBox(width: 6),
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                            color: _getEstadoColor(estado),
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (estado == 'activo')
                  IconButton(
                    icon: const Icon(Icons.check_circle,
                        color: Colors.green),
                    onPressed: () =>
                        _marcarComoDevuelto(p['id'], p),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            _buildInfoRow(Icons.person, 'Usuario',
                p['nombreCompleto'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.badge, 'Núm. Control',
                p['numeroControl'] ?? 'N/A'),

            const Divider(color: Colors.white24, height: 24),

            _buildInfoRow(Icons.inventory_2, 'Material',
                p['materialDescripcion'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.tag, 'ID Material',
                p['materialId'] ?? 'N/A'),

            const Divider(color: Colors.white24, height: 24),

            _buildInfoRow(Icons.calendar_today, 'Fecha préstamo',
                _formatDate(p['fechaPrestamo'])),

            if (p['fechaDevolucion'] != null)
              Column(
                children: [
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.event_available,
                      'Fecha devolución',
                      _formatDate(p['fechaDevolucion'])),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                  const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value,
                  style:
                  const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        )
      ],
    );
  }
}
