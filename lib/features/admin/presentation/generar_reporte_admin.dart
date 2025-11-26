import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class GenerarReporteAdmin extends StatefulWidget {
  const GenerarReporteAdmin({super.key});

  @override
  State<GenerarReporteAdmin> createState() => _GenerarReporteAdminState();
}

class _GenerarReporteAdminState extends State<GenerarReporteAdmin> {
  int _selectedOption = 1; // 0 = última semana, 1 = otros registros
  DateTime? _selectedDate;
  bool _isGenerating = false;

  // Datos de prestamos
  List<Map<String, dynamic>> _getPrestamosData() {
    // Datos reales desde la base de datos
    return [
      {
      },
    ];
  }

  Future<void> _generarYDescargarPDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // Obtener datos
      final prestamos = _getPrestamosData();

      // Crear el documento PDF
      final pdf = pw.Document();

      // Definir período del reporte
      String periodo;
      if (_selectedOption == 0) {
        final now = DateTime.now();
        final hace7dias = now.subtract(Duration(days: 7));
        periodo = '${hace7dias.day}/${hace7dias.month}/${hace7dias.year} - ${now.day}/${now.month}/${now.year}';
      } else {
        periodo = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
      }

      // Agregar página al PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // Encabezado
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'REPORTE DE PRÉSTAMOS',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Período: $periodo',
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Fecha de generación: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                    ),
                    pw.Divider(thickness: 2),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Resumen
              pw.Container(
                padding: pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RESUMEN',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Total de préstamos: ${prestamos.length}'),
                    pw.Text('Préstamos activos: ${prestamos.where((p) => p['estado'] == 'En préstamo').length}'),
                    pw.Text('Préstamos devueltos: ${prestamos.where((p) => p['estado'] == 'Devuelto').length}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Tabla de préstamos
              pw.Text(
                'DETALLE DE PRÉSTAMOS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue700,
                ),
                cellStyle: pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                headerAlignment: pw.Alignment.centerLeft,
                cellPadding: pw.EdgeInsets.all(8),
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headers: ['ID', 'Usuario', 'Artículo', 'F. Préstamo', 'F. Devolución', 'Estado'],
                data: prestamos.map((prestamo) {
                  return [
                    prestamo['id'],
                    prestamo['usuario'],
                    prestamo['articulo'],
                    prestamo['fecha_prestamo'],
                    prestamo['fecha_devolucion'],
                    prestamo['estado'],
                  ];
                }).toList(),
              ),

              // Pie de página
              pw.SizedBox(height: 40),
              pw.Divider(),
              pw.Text(
                'Instituto Tecnológico Superior de Uruapan',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                'Sistema de Gestión de Préstamos',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            ];
          },
        ),
      );

      // Guardar y compartir el PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'reporte_prestamos_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte generado exitosamente'),
            backgroundColor: Color(0xFF6C8BD7),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar el reporte: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F1D3E),
      appBar: AppBar(
        title: const Text('Generar Reporte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  'Reporte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Periodo de consulta',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),

                // Tarjeta de opciones
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1A2540).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Opción 1: Última semana
                      Theme(
                        data: Theme.of(context).copyWith(
                          radioTheme: RadioThemeData(
                            fillColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.white;
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: 0,
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value!;
                              if (value == 0) _selectedDate = null;
                            });
                          },
                          title: Text(
                            'Última semana de préstamos',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          activeColor: Color(0xFF6C8BD7),
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 16, thickness: 1),

                      // Opción 2: Otros registros
                      Theme(
                        data: Theme.of(context).copyWith(
                          radioTheme: RadioThemeData(
                            fillColor: MaterialStateProperty.resolveWith<Color?>(
                                  (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.white;
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        child: RadioListTile<int>(
                          value: 1,
                          groupValue: _selectedOption,
                          onChanged: (value) {
                            setState(() {
                              _selectedOption = value!;
                            });
                          },
                          title: Text(
                            'Otros registros',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Puedes ver otros registros hechos.',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          activeColor: Color(0xFF6C8BD7),
                        ),
                      ),

                      // Campo de fecha
                      if (_selectedOption == 1) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _selectedDate != null
                                ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                                : "Seleccionar fecha",
                          ),
                          decoration: InputDecoration(
                            labelText: 'Selecciona una fecha',
                            labelStyle: TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF1A2540).withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                            ),
                            suffixIcon: Icon(Icons.calendar_month, color: Color(0xFF6C8BD7)),
                          ),
                          style: TextStyle(color: Colors.white),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Color(0xFF6C8BD7),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFF1A2540),
                                      onSurface: Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _selectedDate = date;
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Botón Generar Reporte
                Center(
                  child: ElevatedButton(
                    onPressed: _isGenerating
                        ? null
                        : () {
                      if (_selectedOption == 1 && _selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Selecciona una fecha'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _generarYDescargarPDF();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6C8BD7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isGenerating
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Generando...', style: TextStyle(fontSize: 18)),
                      ],
                    )
                        : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf),
                        SizedBox(width: 8),
                        Text('Generar Reporte', style: TextStyle(fontSize: 18)),
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