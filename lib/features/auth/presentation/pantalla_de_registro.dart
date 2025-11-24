import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert'; // <-- agregado para base64

class RegistroScreen extends StatefulWidget {
  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _numeroControlController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarContrasenaController = TextEditingController();

  bool _aceptaTerminos = false;
  bool _isLoading = false;

  // ---------------------------
  // Función para generar PNG (bytes) del QR y devolver Base64
  // ---------------------------
  Future<String> _generarQrBase64(String data, {int size = 400}) async {
    // Usamos QrPainter para crear la imagen
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    // Convertir a ui.Image
    final uiImage = await painter.toImage(size as double);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception("No se pudo generar imagen QR");

    final bytes = byteData.buffer.asUint8List();
    final base64String = base64Encode(bytes);
    return base64String;
  }

  // ---------------------------
  // Método que muestra un diálogo con el QR (persistente hasta cerrar)
  // ---------------------------
  Future<void> _mostrarDialogQr(String qrBase64) async {
    // Decodificamos la imagen base64 a bytes para mostrar
    final bytes = base64Decode(qrBase64);

    await showDialog(
      context: context,
      barrierDismissible: false, // evita que se cierre tocando fuera
      builder: (ctx) {
        return AlertDialog(
          title: Text('Código QR generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(bytes, width: 250, height: 250),
              SizedBox(height: 12),
              Text(
                'Escanea este QR para solicitar y devolver objetos. Guarda o captura la pantalla si lo deseas.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // cierra el diálogo
              },
              child: Text('Cerrar y volver al inicio'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F1D3E), // Fondo azul oscuro
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      'PrestaTec',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Regístrate',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40),

                    // Campo: Nombre(s)
                    TextFormField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre(s)',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1A2540).withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    // Campo: Apellidos
                    TextFormField(
                      controller: _apellidosController,
                      decoration: InputDecoration(
                        labelText: 'Apellidos',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1A2540).withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa tus apellidos';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    // Campo: Número de control/Nómina
                    TextFormField(
                      controller: _numeroControlController,
                      decoration: InputDecoration(
                        labelText: 'Número de control / Nómina',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1A2540).withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    // Campo: Correo institucional
                    TextFormField(
                      controller: _correoController,
                      decoration: InputDecoration(
                        labelText: 'Correo institucional (@itsuruapan.edu.mx)',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1A2540).withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Requerido';
                        }
                        if (!value.endsWith('@itsuruapan.edu.mx')) {
                          return 'Debe ser un correo institucional válido "@itsuruapan.edu.mx"';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    // Campo: Contraseña
                    TextFormField(
                      controller: _contrasenaController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Crear contraseña',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1A2540).withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 16),

                    // Campo: Confirmar contraseña
                    TextFormField(
                      controller: _confirmarContrasenaController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña',
                        labelStyle: TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Color(0xFF1A2540).withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF6C8BD7)),
                        ),
                      ),
                      validator: (value) {
                        if (value != _contrasenaController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 24),

                    // Checkbox: Aceptar términos
                    Row(
                      children: [
                        Checkbox(
                          value: _aceptaTerminos,
                          onChanged: (bool? value) {
                            setState(() {
                              _aceptaTerminos = value!;
                            });
                          },
                          checkColor: Colors.white,
                          activeColor: Color(0xFF6C8BD7),
                        ),
                        Expanded(
                          child: Text(
                            'Acepto los términos y condiciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),

                    // Botón Registrar
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                        if (_formKey.currentState!.validate() && _aceptaTerminos) {
                          setState(() => _isLoading = true);

                          try {
                            // ✅ Paso 1: Registrar en Firebase Auth
                            final credential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: _correoController.text.trim(),
                              password: _contrasenaController.text,
                            );

                            final uid = credential.user!.uid;

                            // 🔸 Preparamos el payload que queremos almacenar en el QR
                            final Map<String, dynamic> qrPayload = {
                              'uid': uid,
                              'nombre': _nombreController.text.trim(),
                              'apellidos': _apellidosController.text.trim(),
                              'numeroControl': _numeroControlController.text.trim(),
                            };

                            final String qrString = jsonEncode(qrPayload);

                            // ✅ Paso 2: Guardar datos en Firestore + qr
                            await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
                              'nombre': _nombreController.text.trim(),
                              'apellidos': _apellidosController.text.trim(),
                              'numeroControl': _numeroControlController.text.trim(),
                              'correo': _correoController.text.trim(),
                              'rol': 'estudiante', // o 'docente', según tu lógica
                              'createdAt': FieldValue.serverTimestamp(),
                              // Campo con contenido legible del QR (JSON)
                              'qrData': qrString,
                            }, SetOptions(merge: true));

                            // 🔸 Generar imagen QR y guardarla como base64 (opcional, útil para mostrar rápido)
                            try {
                              final String qrBase64 = await _generarQrBase64(qrString);
                              // Guardamos el base64 en Firestore en un campo separado
                              await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
                                'qrBase64': qrBase64,
                              });

                              // Mostrar diálogo con el QR (persistente hasta que el usuario lo cierre)
                              await _mostrarDialogQr(qrBase64);
                            } catch (qrErr) {
                              // Si falla la generación/guardado del PNG, no bloqueamos el registro
                              print('Error generando/guardando QR: $qrErr');
                            }

                            // ✅ Éxito
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡Registro exitoso! 🎉 Bienvenido a PrestaTec'),
                                backgroundColor: Color(0xFF6C8BD7),
                              ),
                            );

                            // Opcional: esperar para que se vea el SnackBar
                            await Future.delayed(Duration(seconds: 1));
                            Navigator.pop(context); // Vuelve a login (mantuvimos tu comportamiento)

                          } on FirebaseAuthException catch (e) {
                            String mensaje;
                            switch (e.code) {
                              case 'email-already-in-use':
                                mensaje = 'Este correo ya está registrado. ¿Olvidaste tu contraseña?';
                                break;
                              case 'invalid-email':
                                mensaje = 'El formato del correo no es válido.';
                                break;
                              case 'weak-password':
                                mensaje = 'La contraseña debe tener al menos 6 caracteres.';
                                break;
                              case 'operation-not-allowed':
                                mensaje = 'El registro está deshabilitado temporalmente.';
                                break;
                              default:
                                mensaje = 'No se pudo crear la cuenta. Inténtalo de nuevo.';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            setState(() => _isLoading = false);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Por favor, acepta los términos y completa todos los campos.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A2540),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Registrar', style: TextStyle(fontSize: 18)),
                    ),

                    SizedBox(height: 16),

                    // Botón "¿Ya tienes cuenta?"
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(
                          color: Color(0xFF6C8BD7),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _numeroControlController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _confirmarContrasenaController.dispose();
    super.dispose();
  }
}
