// lib/features/auth/presentation/role_gate_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../app/auth_service.dart';
import 'login_screen.dart';
import '../../home/presentation/admin_home_screen.dart';
import '../../home/presentation/user_home_screen.dart';

class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) {
          return const LoginScreen();
        }

        // ============================
        //   🔥 Primero: ¿Es admin?
        // ============================
        return FutureBuilder<bool>(
          future: authService.isAdminEmail(user.email ?? ''),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final bool isAdmin = adminSnap.data == true;

            // ===============================
            // 🔥 ADMIN → entra directo
            // ===============================
            if (isAdmin) {
              return const AdminHomeScreen();
            }

            // =======================================
            // 🔥 Usuario NORMAL → debe estar verificado
            // =======================================
            if (!user.emailVerified) {
              return Scaffold(
                body: Center(
                  child: AlertDialog(
                    title: const Text("Correo no verificado"),
                    content: const Text(
                      "Debes verificar tu correo institucional para continuar.\n\n"
                          "Revisa tu bandeja de entrada.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await user.sendEmailVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Correo de verificación reenviado."),
                            ),
                          );
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text("Reenviar correo"),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ======================
            // 🔥 Usuario normal ok
            // ======================
            return const UserHomeScreen();
          },
        );
      },
    );
  }
}
