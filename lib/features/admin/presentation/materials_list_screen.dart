// lib/app/features/admin/presentation/materials_list_screen.dart

import 'package:flutter/material.dart';
import '../../../app/models/material_model.dart';
import '../../../app/services/firestore_service.dart';
import 'edit_material_screen.dart';

class MaterialsListScreen extends StatefulWidget {
  const MaterialsListScreen({super.key});

  @override
  State<MaterialsListScreen> createState() => _MaterialsListScreenState();
}

class _MaterialsListScreenState extends State<MaterialsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteMaterial(String numId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text(
          'Confirmar eliminación',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Estás seguro de eliminar el material #$numId?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteMaterial(numId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Material eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _navigateToEdit(String numId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditMaterialScreen(numId: numId),
      ),
    );
  }

  List<MaterialModel> _filterMaterials(List<MaterialModel> materials) {
    if (_searchQuery.isEmpty) return materials;

    return materials.where((material) {
      final query = _searchQuery.toLowerCase();
      return material.numId.toLowerCase().contains(query) ||
          material.descripcion.toLowerCase().contains(query) ||
          material.marca.toLowerCase().contains(query) ||
          material.modelo.toLowerCase().contains(query) ||
          material.ubicacion.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A30),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text('Lista de Materiales'),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por # Num, descripción, marca...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF2F6BFF)),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<MaterialModel>>(
              stream: _firestoreService.getAllMaterials(),
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

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay materiales registrados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final filteredMaterials = _filterMaterials(snapshot.data!);

                if (filteredMaterials.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron resultados',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredMaterials.length,
                  itemBuilder: (context, index) {
                    final material = filteredMaterials[index];
                    return _buildMaterialCard(material);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(MaterialModel material) {
    return Card(
      color: const Color(0xFF1A2540),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _navigateToEdit(material.numId),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6BFF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '# ${material.numId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _navigateToEdit(material.numId),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteMaterial(material.numId),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Descripción', material.descripcion),
              if (material.marca.isNotEmpty)
                _buildInfoRow('Marca', material.marca),
              if (material.modelo.isNotEmpty)
                _buildInfoRow('Modelo', material.modelo),
              _buildInfoRow('Ubicación', material.ubicacion),
              _buildInfoRow('Cantidad', material.cantidad),
              const SizedBox(height: 8),
              Text(
                'Registrado: ${_formatDate(material.fechaRegistro)}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              if (material.fechaModificacion != null)
                Text(
                  'Modificado: ${_formatDate(material.fechaModificacion!)} por ${material.modificadoPor ?? "N/A"}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}