import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GenerarReporteAdmin extends StatefulWidget {
  const GenerarReporteAdmin({super.key});

  @override
  State<GenerarReporteAdmin> createState() => _GenerarReporteAdminState();
}

class _GenerarReporteAdminState extends State<GenerarReporteAdmin> {
  int _selectedOption = 1; // 0 = última semana, 1 = fecha personalizada
  DateTime? _selectedDate;
  bool _isGenerating = false;

  // -------------------------------------------
  // 🔥 OBTENER PRÉSTAMOS DESDE FIREBASE
  // -------------------------------------------
  Future<List<Map<String, dynamic>>> _getPrestamosData() async {
    QuerySnapshot snapshot;

    if (_selectedOption == 0) {
      // Última semana
      final now = DateTime.now();
      final hace7dias = now.subtract(const Duration(days: 7));

      snapshot = await FirebaseFirestore.instance
          .collection("prestamos")
          .where("fecha_prestamo", isGreaterThanOrEqualTo: hace7dias)
          .get();
    } else {
      // Fecha personalizada
      final inicio = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final fin = inicio.add(const Duration(days: 1));

      snapshot = await FirebaseFirestore.instance
          .collection("prestamos")
          .where("fecha_prestamo", isGreaterThanOrEqualTo: inicio)
          .where("fecha_prestamo", isLessThan: fin)
          .get();
    }

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return {
        "id": doc.id,
        "usuario": data["usuario"] ?? "N/A",
        "articulo": data["material"] ?? "N/A",
        "fecha_prestamo": data["fecha_prestamo"] != null
            ? "${data["fecha_prestamo"].day}/${data["fecha_prestamo"].month}/${data["fecha_prestamo"].year}"
            : "N/A",
        "fecha_devolucion": data["fecha_devolucion"] != null
            ? "${data["fecha_devolucion"].day}/${data["fecha_devolucion"].month}/${data["fecha_devolucion"].year}"
            : "Sin devolver",
        "estado": data["estado"] ?? "N/A",
      };
    }).toList();
  }

  // -------------------------------------------
  // 🔥 GENERAR PDF
  // -------------------------------------------
  Future<void> _generarYDescargarPDF() async {
    setState(() => _isGenerating = true);

    try {
      final prestamos = await _getPrestamosData();

      final pdf = pw.Document();

      String periodo;

      if (_selectedOption == 0) {
        final now = DateTime.now();
        final hace7dias = now.subtract(const Duration(days: 7));
        periodo = "${hace7dias.day}/${hace7dias.month}/${hace7dias.year} - "
            "${now.day}/${now.month}/${now.year}";
      } else {
        periodo = "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("REPORTE DE PRÉSTAMOS",
                      style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text("Período: $periodo", style: const pw.TextStyle(fontSize: 14)),
                  pw.Text(
                    "Fecha de generación: "
                        "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // Resumen
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    "RESUMEN",
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text("Total de préstamos: ${prestamos.length}"),
                  pw.Text(
                    "Préstamos activos: "
                        "${prestamos.where((p) => p["estado"] == "En préstamo").length}",
                  ),
                  pw.Text(
                    "Préstamos devueltos: "
                        "${prestamos.where((p) => p["estado"] == "Devuelto").length}",
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 25),

            pw.Text("DETALLE DE PRÉSTAMOS",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
              cellStyle: const pw.TextStyle(fontSize: 10),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
              border: pw.TableBorder.all(color: PdfColors.grey400),
              headers: ["ID", "Usuario", "Artículo", "F. Préstamo", "F. Devolución", "Estado"],
              data: prestamos.map((p) {
                return [
                  p["id"],
                  p["usuario"],
                  p["articulo"],
                  p["fecha_prestamo"],
                  p["fecha_devolucion"],
                  p["estado"],
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 40),
            pw.Divider(),
            pw.Text("Instituto Tecnológico Superior de Uruapan",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
            pw.Text("Sistema de Gestión de Préstamos",
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          ],
        ),
      );

      // Guardar y compartir
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: "reporte_prestamos_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reporte generado correctamente"),
          backgroundColor: Color(0xFF6C8BD7),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isGenerating = false);
  }

  // -------------------------------------------
  // UI
  // -------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D3E),
      appBar: AppBar(
        title: const Text("Generar Reporte"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Reporte",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "Periodo de consulta",
                  style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.8)),
                ),
                const SizedBox(height: 30),

                // TARJETA OPCIONES
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2540).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      RadioListTile<int>(
                        value: 0,
                        groupValue: _selectedOption,
                        onChanged: (v) => setState(() {
                          _selectedOption = v!;
                          _selectedDate = null;
                        }),
                        title: const Text("Última semana de préstamos", style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        activeColor: const Color(0xFF6C8BD7),
                      ),

                      const Divider(color: Colors.white10),

                      RadioListTile<int>(
                        value: 1,
                        groupValue: _selectedOption,
                        onChanged: (v) => setState(() => _selectedOption = v!),
                        title: const Text("Otros registros", style: TextStyle(color: Colors.white)),
                        subtitle: const Text("Selecciona una fecha para consultar.", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        activeColor: const Color(0xFF6C8BD7),
                      ),

                      if (_selectedOption == 1)
                        Column(
                          children: [
                            const SizedBox(height: 16),
                            TextFormField(
                              readOnly: true,
                              controller: TextEditingController(
                                text: _selectedDate == null
                                    ? "Seleccionar fecha"
                                    : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                              ),
                              decoration: InputDecoration(
                                labelText: "Selecciona una fecha",
                                labelStyle: const TextStyle(color: Colors.white70),
                                filled: true,
                                fillColor: const Color(0xFF1A2540),
                                suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF6C8BD7)),
                                border: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white30),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: Colors.white),
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setState(() => _selectedDate = date);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // BOTÓN GENERAR
                Center(
                  child: ElevatedButton(
                    onPressed: _isGenerating
                        ? null
                        : () {
                      if (_selectedOption == 1 && _selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Selecciona una fecha"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _generarYDescargarPDF();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C8BD7),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: _isGenerating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf),
                        SizedBox(width: 10),
                        Text("Generar Reporte", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
