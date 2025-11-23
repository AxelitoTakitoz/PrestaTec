import 'package:flutter/material.dart';

class SolicitarArticulo extends StatefulWidget {
  const SolicitarArticulo({super.key});

  @override
  State<SolicitarArticulo> createState() => _SolicitarArticuloState();
}

class _SolicitarArticuloState extends State<SolicitarArticulo> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasMaterials = false; // Cambia a true cuando haya materiales disponibles

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              // 👇 Barra de búsqueda
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  // Aquí irá la lógica de búsqueda cuando haya materiales
                  // Ejemplo: _filterMaterials(value);
                },
              ),
              const SizedBox(height: 32),

              // 👇 Mensaje central si no hay materiales
              Expanded(
                child: Center(
                  child: _hasMaterials
                      ? const Text(
                    'Lista de materiales disponibles\n(se mostrará cuando el administrador agregue items)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  )
                      : const Text(
                    'Aún no hay materiales disponibles',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}