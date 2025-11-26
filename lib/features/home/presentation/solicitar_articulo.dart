import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../app/models/material_model.dart';
import '../../../app/services/firestore_service.dart';
import 'qr_scanner_screen.dart';

class SolicitarArticulo extends StatefulWidget {
  const SolicitarArticulo({super.key});

  @override
  State<SolicitarArticulo> createState() => _SolicitarArticuloState();
}

class _SolicitarArticuloState extends State<SolicitarArticulo> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? prestamoId;
  Map<String, dynamic>? prestamoData;

  @override
  void initState() {
    super.initState();
    _checkExistingPrestamo();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Revisa si ya existe préstamo activo para el usuario
  Future<void> _checkExistingPrestamo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final q = await FirebaseFirestore.instance
        .collection('prestamos')
        .where('userId', isEqualTo: user.uid)
        .where('estado', isEqualTo: 'activo')
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      setState(() {
        prestamoId = q.docs.first.id;
        prestamoData = q.docs.first.data();
      });
    }
  }

  /// Convierte dynamic a int de forma segura
  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Muestra diálogo de confirmación
  Future<void> _mostrarDialogoConfirmacion(MaterialModel material) async {
    // Validar cantidad disponible
    final docRef = FirebaseFirestore.instance
        .collection('materiales')
        .doc(material.numId);
    final snap = await docRef.get();

    if (!snap.exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El material no existe en la base de datos.')),
      );
      return;
    }

    final data = snap.data()!;
    final cantidad = _toInt(data['cantidad'] ?? 0);

    if (cantidad <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay stock disponible para este artículo.')),
      );
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text(
          "Confirmar solicitud",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Material: ${material.descripcion}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              "Marca: ${material.marca}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              "Ubicación: ${material.ubicacion}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Text(
              "Cantidad disponible: $cantidad",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Deberás escanear tu QR personal para confirmar',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
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
              "Continuar",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _abrirEscaner(material);
    }
  }

  /// Abre el escáner QR
  Future<void> _abrirEscaner(MaterialModel material) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QrScannerScreen(
          materialId: material.numId,
          materialDescripcion: material.descripcion,
        ),
      ),
    );

    if (result == true) {
      // Préstamo creado exitosamente
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Préstamo registrado correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      // Recargar datos
      await _checkExistingPrestamo();
      setState(() {});
    }
  }

  /// Filtrar lista de materiales
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

  /// Pantalla del préstamo activo
  Widget _buildPrestamoScreen() {
    if (prestamoData == null) return const SizedBox();

    String fechaStr = 'N/A';
    if (prestamoData!['fechaPrestamo'] != null) {
      try {
        final fecha = (prestamoData!['fechaPrestamo'] as Timestamp).toDate();
        fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        fechaStr = 'Fecha inválida';
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_turned_in,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 20),
            const Text(
              "Préstamo activo",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A2540).withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    'Material',
                    prestamoData!['materialDescripcion'] ?? 'N/A',
                    Icons.inventory_2,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildInfoRow(
                    'ID Material',
                    prestamoData!['materialId'] ?? 'N/A',
                    Icons.tag,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildInfoRow(
                    'Usuario',
                    prestamoData!['nombreCompleto'] ?? 'N/A',
                    Icons.person,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildInfoRow(
                    'Número de control',
                    prestamoData!['numeroControl'] ?? 'N/A',
                    Icons.badge,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildInfoRow(
                    'Fecha de préstamo',
                    fechaStr,
                    Icons.calendar_today,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildInfoRow(
                    'Estado',
                    (prestamoData!['estado'] ?? 'N/A').toUpperCase(),
                    Icons.info,
                    valueColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Para devolver el material, acude con el administrador',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text("Cancelar préstamo"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () => _cancelarPrestamo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _cancelarPrestamo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text(
          '¿Cancelar préstamo?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Se revertirá la cantidad del material y el préstamo será cancelado.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('No', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Sí', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final matRef = FirebaseFirestore.instance
            .collection('materiales')
            .doc(prestamoData!['materialId']);

        await FirebaseFirestore.instance.runTransaction((tx) async {
          // Actualizar préstamo
          final prestamoRef =
          FirebaseFirestore.instance.collection('prestamos').doc(prestamoId);
          tx.update(prestamoRef, {
            'estado': 'cancelado',
            'fechaDevolucion': FieldValue.serverTimestamp(),
          });

          // Aumentar cantidad
          final snap = await tx.get(matRef);
          if (snap.exists) {
            final cur = _toInt(snap.data()!['cantidad'] ?? 0);
            tx.update(matRef, {'cantidad': cur + 1});
          }
        });

        if (!mounted) return;
        setState(() {
          prestamoId = null;
          prestamoData = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préstamo cancelado correctamente')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cancelar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D3E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text('Solicitar artículo'),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: prestamoId != null
          ? _buildPrestamoScreen()
          : SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar material',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon:
                  const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor:
                  const Color(0xFF1A2540).withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<List<MaterialModel>>(
                  stream: _firestoreService.getAllMaterials(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white),
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
                              style:
                              const TextStyle(color: Colors.white70),
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
                                    final d = s.data!.data()
                                    as Map<String, dynamic>?;
                                    final cantidad = d != null
                                        ? _toInt(d['cantidad'] ?? 0)
                                        : 0;
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
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.greenAccent,
                                  ),
                                  onPressed: () =>
                                      _mostrarDialogoConfirmacion(material),
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
        ),
      ),
    );
  }
}