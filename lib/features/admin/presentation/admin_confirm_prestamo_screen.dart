// lib/features/admin/presentation/admin_confirm_prestamo_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/models/material_model.dart';
import '../../../app/services/firestore_service.dart';

class AdminConfirmPrestamoScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const AdminConfirmPrestamoScreen({
    super.key,
    required this.userData,
  });

  @override
  State<AdminConfirmPrestamoScreen> createState() =>
      _AdminConfirmPrestamoScreenState();
}

class _AdminConfirmPrestamoScreenState
    extends State<AdminConfirmPrestamoScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

  Future<void> _confirmarPrestamo(MaterialModel material) async {
    final docRef =
    FirebaseFirestore.instance.collection('materiales').doc(material.numId);

    final snap = await docRef.get();

    if (!snap.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El material no existe en la base de datos.')),
      );
      return;
    }

    final data = snap.data()!;
    final cantidad = _toInt(data['cantidad'] ?? 0);

    if (cantidad <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No hay stock disponible para este artículo.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text(
          "Confirmar préstamo",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usuario:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              widget.userData['nombreCompleto'] ?? 'N/A',
              style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Núm. Control:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              widget.userData['numeroControl'] ?? 'N/A',
              style: const TextStyle(color: Colors.white),
            ),
            const Divider(color: Colors.white24, height: 24),
            const Text(
              'Material:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              material.descripcion,
              style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Marca: ${material.marca}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 4),
            Text(
              "Ubicación: ${material.ubicacion}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              "Cantidad disponible: $cantidad",
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Confirmar préstamo",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final materialRef = FirebaseFirestore.instance
            .collection('materiales')
            .doc(material.numId);

        final matSnap = await transaction.get(materialRef);
        if (!matSnap.exists) {
          throw Exception('Material no encontrado');
        }

        final currentCantidad = _toInt(matSnap.data()!['cantidad'] ?? 0);
        if (currentCantidad <= 0) {
          throw Exception('Material sin stock');
        }

        final prestamoRef =
        FirebaseFirestore.instance.collection('prestamos').doc();
        transaction.set(prestamoRef, {
          'userId': widget.userData['userId'],
          'nombreCompleto': widget.userData['nombreCompleto'],
          'numeroControl': widget.userData['numeroControl'],
          'correo': widget.userData['correo'],
          'materialId': material.numId,
          'materialDescripcion': material.descripcion,
          'materialMarca': material.marca,
          'materialModelo': material.modelo,
          'materialUbicacion': material.ubicacion,
          'fechaPrestamo': FieldValue.serverTimestamp(),
          'fechaDevolucion': null,
          'estado': 'activo',
          'qrUsuario': widget.userData['qrData'],
        });

        transaction.update(materialRef, {
          'cantidad': currentCantidad - 1,
        });
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Préstamo registrado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear préstamo: $e'),
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
        title: const Text('Seleccionar material'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.redAccent),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2540),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Usuario validado',
                      style:
                      TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                _buildUserInfoRow('Nombre', widget.userData['nombreCompleto']),
                const SizedBox(height: 8),
                _buildUserInfoRow(
                    'Núm. Control', widget.userData['numeroControl']),
                const SizedBox(height: 8),
                _buildUserInfoRow('Correo', widget.userData['correo']),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
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
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          const SizedBox(height: 16),

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
                      "Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      "No hay materiales disponibles",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final materials = _filterMaterials(snapshot.data!);

                if (materials.isEmpty) {
                  return const Center(
                    child: Text(
                      "No se encontraron materiales",
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: materials.length,
                  itemBuilder: (context, index) {
                    final material = materials[index];
                    return Card(
                      color: const Color(0xFF1A2540),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          material.descripcion,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          "Marca: ${material.marca}  |  Ubicación: ${material.ubicacion}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('materiales')
                                  .doc(material.numId)
                                  .snapshots(),
                              builder: (c, s) {
                                if (!s.hasData) {
                                  return const Text(
                                    'Disp: ...',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  );
                                }
                                final d =
                                s.data!.data() as Map<String, dynamic>?;
                                final cantidad =
                                d != null ? _toInt(d['cantidad'] ?? 0) : 0;
                                return Text(
                                  'Disp: $cantidad',
                                  style: TextStyle(
                                    color: cantidad > 0
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 8),

                            /// BOTÓN NUEVO
                            IconButton(
                              icon: const Icon(
                                Icons.cancel,
                                color: Colors.redAccent,
                              ),
                              tooltip: "Cancelar y volver",
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),

                            const SizedBox(width: 8),

                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.greenAccent,
                              ),
                              onPressed: () => _confirmarPrestamo(material),
                            ),
                          ],
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
    );
  }

  Widget _buildUserInfoRow(String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
