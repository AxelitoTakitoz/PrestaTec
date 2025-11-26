// lib/features/home/presentation/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:async';

class QrScannerScreen extends StatefulWidget {
  final String materialId;
  final String materialDescripcion;

  const QrScannerScreen({
    super.key,
    required this.materialId,
    required this.materialDescripcion,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final TextEditingController _qrController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isProcessing = false;
  String _statusMessage = 'Esperando lectura del QR...';
  Color _statusColor = Colors.white70;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    // Auto-focus para recibir input del lector QR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _qrController.dispose();
    _focusNode.dispose();
    _resetTimer?.cancel();
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Obtener datos del usuario desde Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      final userData = userDoc.data()!;
      final storedQrData = userData['qrData'] as String?;

      if (storedQrData == null || storedQrData.isEmpty) {
        throw Exception('El usuario no tiene QR registrado');
      }

      // Validar que el QR escaneado coincida con el QR del usuario
      if (qrData.trim() != storedQrData.trim()) {
        throw Exception('El QR escaneado no pertenece a este usuario');
      }

      // QR válido - Parsear datos
      Map<String, dynamic> qrPayload;
      try {
        qrPayload = jsonDecode(storedQrData);
      } catch (e) {
        throw Exception('Formato de QR inválido');
      }

      // Verificar disponibilidad del material
      final materialDoc = await FirebaseFirestore.instance
          .collection('materiales')
          .doc(widget.materialId)
          .get();

      if (!materialDoc.exists) {
        throw Exception('Material no encontrado');
      }

      final materialData = materialDoc.data()!;
      final cantidad = _toInt(materialData['cantidad'] ?? 0);

      if (cantidad <= 0) {
        throw Exception('Material sin stock disponible');
      }

      // Verificar si el usuario ya tiene un préstamo activo
      final prestamosActivos = await FirebaseFirestore.instance
          .collection('prestamos')
          .where('userId', isEqualTo: user.uid)
          .where('estado', isEqualTo: 'activo')
          .get();

      if (prestamosActivos.docs.isNotEmpty) {
        throw Exception('Ya tienes un préstamo activo');
      }

      // Crear préstamo en una transacción
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final materialRef = FirebaseFirestore.instance
            .collection('materiales')
            .doc(widget.materialId);

        final matSnap = await transaction.get(materialRef);
        if (!matSnap.exists) {
          throw Exception('Material no encontrado');
        }

        final currentCantidad = _toInt(matSnap.data()!['cantidad'] ?? 0);
        if (currentCantidad <= 0) {
          throw Exception('Material sin stock');
        }

        // Crear préstamo
        final prestamoRef = FirebaseFirestore.instance.collection('prestamos').doc();
        transaction.set(prestamoRef, {
          'userId': user.uid,
          'nombreCompleto': '${userData['nombre'] ?? ''} ${userData['apellidos'] ?? ''}'.trim(),
          'numeroControl': userData['numeroControl'] ?? 'N/A',
          'correo': userData['correo'] ?? user.email ?? 'N/A',
          'materialId': widget.materialId,
          'materialDescripcion': widget.materialDescripcion,
          'materialMarca': materialData['marca'] ?? '',
          'materialModelo': materialData['modelo'] ?? '',
          'materialUbicacion': materialData['ubicacion'] ?? '',
          'fechaPrestamo': FieldValue.serverTimestamp(),
          'fechaDevolucion': null,
          'estado': 'activo',
          'qrUsuario': storedQrData,
        });

        // Decrementar cantidad del material
        transaction.update(materialRef, {
          'cantidad': currentCantidad - 1,
        });
      });

      if (!mounted) return;

      setState(() {
        _statusMessage = '✓ Préstamo registrado exitosamente';
        _statusColor = Colors.green;
      });

      // Esperar un momento y regresar con éxito
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = '✗ Error: ${e.toString()}';
        _statusColor = Colors.red;
        _isProcessing = false;
      });

      // Limpiar y volver a intentar después de 3 segundos
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _statusMessage = 'Esperando lectura del QR...';
            _statusColor = Colors.white70;
            _qrController.clear();
          });
          _focusNode.requestFocus();
        }
      });
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !_isProcessing;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1D3E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A2540),
          title: const Text('Escanear QR de Usuario'),
          foregroundColor: Colors.white,
          leading: _isProcessing
              ? null
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícono animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor.withOpacity(0.2),
                        border: Border.all(
                          color: _statusColor,
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isProcessing
                            ? Icons.hourglass_empty
                            : _statusColor == Colors.green
                            ? Icons.check_circle
                            : _statusColor == Colors.red
                            ? Icons.error
                            : Icons.qr_code_scanner,
                        size: 80,
                        color: _statusColor,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // Información del material
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2540).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Material a solicitar:',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.materialDescripcion,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.materialId}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Mensaje de estado
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Indicador de carga
              if (_isProcessing)
                const CircularProgressIndicator(
                  color: Colors.blue,
                ),

              const SizedBox(height: 40),

              // Campo oculto para recibir input del lector QR
              SizedBox(
                height: 0,
                child: TextField(
                  controller: _qrController,
                  focusNode: _focusNode,
                  autofocus: true,
                  enableInteractiveSelection: false,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty && !_isProcessing) {
                      _processQrData(value);
                    }
                  },
                ),
              ),

              // Instrucciones
              const Text(
                'Escanea tu código QR personal con el lector externo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}