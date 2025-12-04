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

  // ----------------------------------------------------------
  // FUNCIÓN EXTRA: Ventana emergente para verificar correo
  // ----------------------------------------------------------
  Future<void> _mostrarPopupVerificacion(String email) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text("Verifica tu correo"),
        content: Text(
          "Te enviamos un enlace de verificación a:\n\n$email\n\n"
              "Debes verificar tu cuenta antes de usar PrestaTec.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text("Entendido"),
          )
        ],
      ),
    );
  }

  // ---------------------------
  // Función para generar PNG (bytes) del QR y devolver Base64
  // ---------------------------
  Future<String> _generarQrBase64(String data, {int size = 400}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
    );

    final uiImage = await painter.toImage(size.toDouble());
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception("No se pudo generar imagen QR");

    final bytes = byteData.buffer.asUint8List();
    final base64String = base64Encode(bytes);
    return base64String;
  }

  // ---------------------------
  // Mostrar QR en diálogo
  // ---------------------------
  Future<void> _mostrarDialogQr(String qrBase64) async {
    final bytes = base64Decode(qrBase64);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Código QR generado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(bytes, width: 250, height: 250),
              SizedBox(height: 12),
              Text(
                'Escanea este QR para solicitar y devolver objetos.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
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
      backgroundColor: Color(0xFF0F1D3E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // --- TÍTULOS ---
                    Text(
                      'PrestaTec',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Regístrate',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                    SizedBox(height: 40),

                    // --- CAMPOS ---
                    _buildCampo(_nombreController, 'Nombre(s)'),
                    SizedBox(height: 16),
                    _buildCampo(_apellidosController, 'Apellidos'),
                    SizedBox(height: 16),
                    _buildCampo(_numeroControlController, 'Número de control / Nómina'),
                    SizedBox(height: 16),
                    _buildCampoCorreo(),
                    SizedBox(height: 16),
                    _buildCampoContrasena(_contrasenaController, 'Crear contraseña'),
                    SizedBox(height: 16),
                    _buildCampoConfirmarContrasena(),
                    SizedBox(height: 20),

                    // --- Aceptar términos ---
                    Row(
                      children: [
                        Checkbox(
                          value: _aceptaTerminos,
                          onChanged: (v) => setState(() => _aceptaTerminos = v!),
                          checkColor: Colors.white,
                          activeColor: Color(0xFF6C8BD7),
                        ),
                        Expanded(
                          child: Text(
                            'Acepto los términos y condiciones',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 20),

                    // -----------------------------------------------------
                    // BOTÓN REGISTRAR (AQUÍ VA LO QUE TE AGREGUÉ)
                    // -----------------------------------------------------
                    ElevatedButton(
                      onPressed: _isLoading ? null : _registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1A2540),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text("Registrar", style: TextStyle(fontSize: 18)),
                    ),

                    SizedBox(height: 16),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        '¿Ya tienes cuenta? Inicia sesión',
                        style: TextStyle(color: Color(0xFF6C8BD7), decoration: TextDecoration.underline),
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

  // ===========================================================
  // FUNCIÓN COMPLETA DE REGISTRO MODIFICADA CON VERIFICACIÓN
  // ===========================================================
  Future<void> _registrarUsuario() async {
    if (_formKey.currentState!.validate() == false || !_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Completa todos los campos y acepta los términos.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Crear usuario en Firebase
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _correoController.text.trim(),
        password: _contrasenaController.text,
      );

      // 2️⃣ Enviar verificación de correo
      await cred.user!.sendEmailVerification();

      // 3️⃣ Mostrar popup informativo
      await _mostrarPopupVerificacion(_correoController.text.trim());

      final uid = cred.user!.uid;

      // 4️⃣ Datos del QR
      final payload = {
        'uid': uid,
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'numeroControl': _numeroControlController.text.trim(),
      };

      final qrString = jsonEncode(payload);

      // 5️⃣ Guardar datos en Firestore
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).set({
        'nombre': _nombreController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'numeroControl': _numeroControlController.text.trim(),
        'correo': _correoController.text.trim(),
        'rol': 'estudiante',
        'emailVerificado': false,      // 🔥 NUEVO
        'createdAt': FieldValue.serverTimestamp(),
        'qrData': qrString,
      });

      // 6️⃣ Generar QR Base64
      final qrBase64 = await _generarQrBase64(qrString);

      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'qrBase64': qrBase64,
      });

      // Mostrar QR
      await _mostrarDialogQr(qrBase64);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registro exitoso 🎉"), backgroundColor: Color(0xFF6C8BD7)),
      );

      await Future.delayed(Duration(seconds: 1));
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }

    setState(() => _isLoading = false);
  }

  // -------------------------------------------------------------
  // WIDGETS AUXILIARES (NO LOS MODIFIQUÉ)
  // -------------------------------------------------------------
  Widget _buildCampo(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      style: TextStyle(color: Colors.white),
      decoration: _decor(label),
      validator: (v) => v == null || v.isEmpty ? "Requerido" : null,
    );
  }

  Widget _buildCampoCorreo() {
    return TextFormField(
      controller: _correoController,
      style: TextStyle(color: Colors.white),
      decoration: _decor("Correo institucional (@itsuruapan.edu.mx)"),
      validator: (value) {
        if (value == null || value.isEmpty) return "Requerido";
        if (!value.endsWith("@itsuruapan.edu.mx")) {
          return "Debe ser un correo institucional válido";
        }
        return null;
      },
    );
  }

  Widget _buildCampoContrasena(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      obscureText: true,
      style: TextStyle(color: Colors.white),
      decoration: _decor(label),
      validator: (v) => v != null && v.length >= 6 ? null : "Mínimo 6 caracteres",
    );
  }

  Widget _buildCampoConfirmarContrasena() {
    return TextFormField(
      controller: _confirmarContrasenaController,
      obscureText: true,
      style: TextStyle(color: Colors.white),
      decoration: _decor("Confirmar contraseña"),
      validator: (v) {
        if (v != _contrasenaController.text) return "Las contraseñas no coinciden";
        return null;
      },
    );
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Color(0xFF1A2540).withOpacity(0.3),
      border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF6C8BD7))),
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
