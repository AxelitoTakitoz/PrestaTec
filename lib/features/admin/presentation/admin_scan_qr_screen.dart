// lib/features/admin/presentation/admin_scan_qr_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class AdminScanQrScreen extends StatefulWidget {
  const AdminScanQrScreen({super.key});

  @override
  State<AdminScanQrScreen> createState() => _AdminScanQrScreenState();
}

class _AdminScanQrScreenState extends State<AdminScanQrScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  bool _isProcessing = false;
  String _statusMessage = 'Escanea el código QR del usuario';
  Color _statusColor = Colors.white;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processQrData(String qrData) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Validando QR...';
      _statusColor = Colors.blue;
    });

    try {
      // Parsear datos del QR
      Map<String, dynamic> qrPayload;
      try {
        qrPayload = jsonDecode(qrData);
      } catch (e) {
        throw Exception('QR inválido: formato incorrecto');
      }

      final userId = qrPayload['uid'] as String?;
      if (userId == null || userId.isEmpty) {
        throw Exception('QR inválido: falta identificador de usuario');
      }

      // Verificar que el usuario existe en Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      final userData = userDoc.data()!;

      // Verificar que el QR coincide con el del usuario
      final storedQrData = userData['qrData'] as String?;
      if (storedQrData == null || storedQrData.trim() != qrData.trim()) {
        throw Exception('QR no coincide con el registrado');
      }

      // Verificar si el usuario ya tiene un préstamo activo
      final prestamosActivos = await FirebaseFirestore.instance
          .collection('prestamos')
          .where('userId', isEqualTo: userId)
          .where('estado', isEqualTo: 'activo')
          .get();

      if (prestamosActivos.docs.isNotEmpty) {
        throw Exception('Este usuario ya tiene un préstamo activo');
      }

      // QR válido - Devolver datos del usuario
      if (!mounted) return;

      setState(() {
        _statusMessage = '✓ QR válido';
        _statusColor = Colors.green;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pop(context, {
        'userId': userId,
        'nombreCompleto': '${userData['nombre'] ?? ''} ${userData['apellidos'] ?? ''}'.trim(),
        'numeroControl': userData['numeroControl'] ?? 'N/A',
        'correo': userData['correo'] ?? 'N/A',
        'qrData': qrData,
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '✗ ${e.toString()}';
        _statusColor = Colors.red;
        _isProcessing = false;
      });

      // Reintentar después de 3 segundos
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _statusMessage = 'Escanea el código QR del usuario';
          _statusColor = Colors.white;
        });
        _controller.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1D3E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2540),
        title: const Text('Escanear QR de Usuario'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_controller.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && !_isProcessing) {
                  _controller.stop();
                  _processQrData(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Overlay con marco
          CustomPaint(
            painter: ScannerOverlay(),
            child: Container(),
          ),

          // Mensaje de estado en la parte superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _statusColor),
              ),
              child: Row(
                children: [
                  if (_isProcessing)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    )
                  else
                    Icon(
                      _statusColor == Colors.green
                          ? Icons.check_circle
                          : _statusColor == Colors.red
                          ? Icons.error
                          : Icons.qr_code_scanner,
                      color: _statusColor,
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Instrucciones en la parte inferior
          if (!_isProcessing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Enfoca la cámara al código QR que el usuario muestre en su pantalla',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Overlay personalizado para el escáner
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Dibujar fondo oscuro
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      paint,
    );

    // Área transparente para el QR
    final double scanSize = size.width * 0.7;
    final double left = (size.width - scanSize) / 2;
    final double top = (size.height - scanSize) / 2;

    canvas.drawRect(
      Rect.fromLTWH(left, top, scanSize, scanSize),
      Paint()..blendMode = BlendMode.clear,
    );

    // Esquinas del marco
    final cornerPaint = Paint()
      ..color = const Color(0xFF2F6BFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cornerLength = 30.0;

    // Esquina superior izquierda
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left, top + cornerLength), cornerPaint);

    // Esquina superior derecha
    canvas.drawLine(Offset(left + scanSize, top), Offset(left + scanSize - cornerLength, top), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top), Offset(left + scanSize, top + cornerLength), cornerPaint);

    // Esquina inferior izquierda
    canvas.drawLine(Offset(left, top + scanSize), Offset(left + cornerLength, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left, top + scanSize), Offset(left, top + scanSize - cornerLength), cornerPaint);

    // Esquina inferior derecha
    canvas.drawLine(Offset(left + scanSize, top + scanSize), Offset(left + scanSize - cornerLength, top + scanSize), cornerPaint);
    canvas.drawLine(Offset(left + scanSize, top + scanSize), Offset(left + scanSize, top + scanSize - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}