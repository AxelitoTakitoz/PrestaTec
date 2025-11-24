import 'package:flutter/material.dart';
import '../../../app/models/material_model.dart';
import '../../../app/services/firestore_service.dart';

class SolicitarArticulo extends StatefulWidget {
  const SolicitarArticulo({super.key});

  @override
  State<SolicitarArticulo> createState() => _SolicitarArticuloState();
}

class _SolicitarArticuloState extends State<SolicitarArticulo> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MaterialModel> _filterMaterials(List<MaterialModel> materials) {
    if (_searchQuery.isEmpty) return materials;

    final q = _searchQuery.toLowerCase();
    return materials.where((m) {
      return m.numId.toLowerCase().contains(q) ||
          m.descripcion.toLowerCase().contains(q) ||
          m.marca.toLowerCase().contains(q) ||
          m.modelo.toLowerCase().contains(q) ||
          m.ubicacion.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D3E),
      appBar: AppBar(
        title: const Text('Solicitar artículo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔎 Barra de búsqueda
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar material',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1A2540).withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // 📌 LISTA REAL DE MATERIALES
              Expanded(
                child: StreamBuilder<List<MaterialModel>>(
                  stream: _firestoreService.getAllMaterials(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aún no hay materiales disponibles',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      );
                    }

                    final filtered = _filterMaterials(snapshot.data!);

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No se encontraron resultados',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final material = filtered[index];

                        return Card(
                          color: const Color(0xFF1A2540),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            title: Text(
                              material.descripcion,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Marca: ${material.marca}   Ubicación: ${material.ubicacion}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
                              onPressed: () {
                                // Aquí abrirás pantalla para generar ticket o QR
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Seleccionaste: ${material.descripcion}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
