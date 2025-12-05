// lib/features/auth/presentation/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/auth_service.dart';
import 'pantalla_de_registro.dart';
import 'role_gate_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;

  bool _verPass = false; // 👁️ para mostrar/ocultar contraseña

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------
  // 🔹 Recuperar contraseña
  // -----------------------------------------------------------
  Future<void> _recuperarContrasena() async {
    final correo = _email.text.trim();
    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingresa tu correo para recuperar contraseña")),
      );
      return;
    }

    final enviar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Recuperar contraseña"),
        content: Text(
            "Se enviará un enlace de recuperación a:\n\n$correo\n\n¿Deseas continuar?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Enviar")),
        ],
      ),
    );

    if (enviar != true) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: correo);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Correo enviado. Revisa tu bandeja.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo enviar: $e")),
      );
    }
  }

  // -----------------------------------------------------------
  // 🔹 INICIAR SESIÓN
  // -----------------------------------------------------------
  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      await _authService.signIn(_email.text, _pass.text);

      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();

      // *** CORRECCIÓN IMPORTANTE ***
      // Ahora valida si el correo del usuario actual es admin
      final esAdmin = await _authService.isAdminEmail(user?.email ?? "");

      // -----------------------------------------------------------
      // 🔥 ADMIN NO NECESITA VERIFICAR CORREO
      // -----------------------------------------------------------
      if (!esAdmin) {
        // Usuarios normales sí deben verificar correo
        if (user != null && !user.emailVerified) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Correo no verificado"),
              content: const Text(
                  "Tu correo institucional aún no ha sido verificado.\n\n"
                      "Debes abrir el enlace que te enviamos para poder ingresar.\n\n"
                      "¿Quieres reenviar el correo de verificación?"
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () async {
                    await user.sendEmailVerification();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Correo reenviado")),
                    );
                  },
                  child: const Text("Reenviar"),
                ),
              ],
            ),
          );

          await FirebaseAuth.instance.signOut();
          setState(() => _loading = false);
          return;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleGateScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String mensaje;
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          mensaje = 'Correo o contraseña incorrectos.';
          break;
        default:
          mensaje = 'No se pudo iniciar sesión.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // -----------------------------------------------------------
  // UI
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'PrestaTec',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Bienvenido'),
                  const SizedBox(height: 16),

                  CircleAvatar(
                    radius: 36,
                    backgroundColor: cs.primary.withOpacity(0.1),
                    child: Icon(Icons.person, color: cs.primary, size: 36),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    'Ingresa tu correo institucional y contraseña',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Correo institucional',
                            hintText: 'ejemplo@itsuruapan.edu.mx',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // -----------------------------------------------------------
                        // 🔹 Campo contraseña con OJITO
                        // -----------------------------------------------------------
                        TextFormField(
                          controller: _pass,
                          obscureText: !_verPass,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(_verPass
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() => _verPass = !_verPass);
                              },
                            ),
                          ),
                          validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: _recuperarContrasena,
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _loading ? null : _signIn,
                                child: _loading
                                    ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                                    : const Text('Iniciar sesión'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => RegistroScreen()),
                                  );
                                },
                                child: const Text('Registrarse'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
