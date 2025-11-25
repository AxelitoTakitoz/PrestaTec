import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

// PDF & printing
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:barcode_widget/barcode_widget.dart' as barcode;

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

  String? ticketId;
  Map<String, dynamic>? ticketData;

  @override
  void initState() {
    super.initState();
    _checkExistingTicket();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Revisa si ya existe ticket pendiente para el usuario
  Future<void> _checkExistingTicket() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final q = await FirebaseFirestore.instance
        .collection('tickets')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pendiente')
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) {
      setState(() {
        ticketId = q.docs.first.id;
        ticketData = q.docs.first.data();
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

  /// Muestra diálogo de confirmación (ventana emergente)
  Future<void> _mostrarDialogoConfirmacion(MaterialModel material) async {
    // Validar cantidad disponible
    final docRef = FirebaseFirestore.instance.collection('materiales').doc(material.numId);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text("Confirmar solicitud", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Material: ${material.descripcion}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text("Marca: ${material.marca}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text("Ubicación: ${material.ubicacion}", style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            Text("Cantidad disponible: $cantidad", style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _crearTicket(material);
            },
            child: const Text("Aceptar", style: TextStyle(color: Colors.greenAccent)),
          ),
        ],
      ),
    );
  }

  /// Crear ticket + QR + disminuir cantidad
  Future<void> _crearTicket(MaterialModel material) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay usuario autenticado.')),
      );
      return;
    }

    // Evitar duplicados
    if (ticketId != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ya tienes un artículo solicitado.")),
      );
      return;
    }

    final materialRef = FirebaseFirestore.instance.collection('materiales').doc(material.numId);

    try {
      final ticketRef = await FirebaseFirestore.instance.runTransaction((tx) async {
        // Verificar nuevamente si hay un ticket pendiente
        final existingTickets = await FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 'pendiente')
            .limit(1)
            .get();

        if (existingTickets.docs.isNotEmpty) {
          throw Exception('Ya tienes un ticket pendiente.');
        }

        final matSnap = await tx.get(materialRef);

        if (!matSnap.exists) {
          throw Exception('Material no existe en la base de datos.');
        }

        final matData = matSnap.data()!;
        final int cantidadActual = _toInt(matData['cantidad'] ?? 0);

        if (cantidadActual <= 0) {
          throw Exception('No hay stock disponible.');
        }

        // Generar string único para QR
        final qrString = "${user.uid}_${material.numId}_${DateTime.now().millisecondsSinceEpoch}";

        // Crear ticket
        final newTicketRef = FirebaseFirestore.instance.collection('tickets').doc();
        tx.set(newTicketRef, {
          'userId': user.uid,
          'userEmail': user.email ?? 'Sin email',
          'materialId': material.numId,
          'materialDescripcion': material.descripcion,
          'fecha': FieldValue.serverTimestamp(),
          'status': 'pendiente',
          'qr': qrString,
        });

        // Decrementar cantidad
        tx.update(materialRef, {'cantidad': cantidadActual - 1});

        return newTicketRef;
      });

      // Esperar un momento para que serverTimestamp se escriba
      await Future.delayed(const Duration(milliseconds: 500));
      final snap = await ticketRef.get();

      if (!mounted) return;
      setState(() {
        ticketId = ticketRef.id;
        ticketData = snap.data();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud creada correctamente')),
      );

      _mostrarTicketDialog(ticketData!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  /// Ventana modal para mostrar el ticket
  Future<void> _mostrarTicketDialog(Map<String, dynamic> ticket) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text('Ticket generado', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: ticket['qr'] ?? '',
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            Text('Material: ${ticket['materialDescripcion']}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text('Usuario: ${ticket['userEmail']}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generarPdfYCompartir(ticket);
            },
            child: const Text('Descargar PDF',
                style: TextStyle(color: Colors.lightBlueAccent)),
          ),
        ],
      ),
    );
  }

  /// Genera PDF con el QR (usando pw.BarcodeWidget directamente)
  Future<void> _generarPdfYCompartir(Map<String, dynamic> ticket) async {
    try {
      // Crear PDF
      final doc = pw.Document();

      // Formatear fecha
      String fechaStr = 'N/A';
      if (ticket['fecha'] != null) {
        if (ticket['fecha'] is Timestamp) {
          fechaStr = (ticket['fecha'] as Timestamp).toDate().toString();
        } else {
          fechaStr = ticket['fecha'].toString();
        }
      }

      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Ticket de préstamo',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Usuario: ${ticket['userEmail'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Material: ${ticket['materialDescripcion'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Material ID: ${ticket['materialId'] ?? 'N/A'}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Fecha: $fechaStr',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 30),
              pw.Center(
                child: pw.BarcodeWidget(
                  data: ticket['qr'] ?? '',
                  barcode: pw.Barcode.qrCode(),
                  width: 250,
                  height: 250,
                ),
              ),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text('Escanea el QR para validar el ticket',
                    style: const pw.TextStyle(fontSize: 12)),
              ),
            ],
          );
        },
      ));

      final pdfBytes = await doc.save();

      // Compartir PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'ticket_${ticketId ?? DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
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

  /// Pantalla del ticket activo
  Widget _buildTicketScreen() {
    if (ticketData == null) return const SizedBox();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Tu ticket activo",
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: ticketData!['qr'] ?? '',
                size: 240,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text("Material: ${ticketData!['materialDescripcion']}",
                style: const TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 10),
            Text("ID: ${ticketData!['materialId']}",
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text("Cancelar solicitud"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    backgroundColor: const Color(0xFF1A2540),
                    title: const Text('¿Cancelar solicitud?',
                        style: TextStyle(color: Colors.white)),
                    content: const Text(
                      'Se revertirá la cantidad del material y el ticket será cancelado.',
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
                        .doc(ticketData!['materialId']);

                    await FirebaseFirestore.instance.runTransaction((tx) async {
                      // Actualizar ticket
                      final ticketRef = FirebaseFirestore.instance
                          .collection('tickets')
                          .doc(ticketId);
                      tx.update(ticketRef, {'status': 'cancelado'});

                      // Aumentar cantidad
                      final snap = await tx.get(matRef);
                      if (snap.exists) {
                        final cur = _toInt(snap.data()!['cantidad'] ?? 0);
                        tx.update(matRef, {'cantidad': cur + 1});
                      }
                    });

                    if (!mounted) return;
                    setState(() {
                      ticketId = null;
                      ticketData = null;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Solicitud cancelada correctamente')),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al cancelar: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
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
      body: ticketId != null
          ? _buildTicketScreen()
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
              const SizedBox(height: 24),
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
                                    final d = s.data!.data() as Map<String, dynamic>?;
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
                                  onPressed: () => _mostrarDialogoConfirmacion(material),
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