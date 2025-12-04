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

        // ================================
        // 🔥 AGREGADO: validar verificación
        // ================================
        if (!user.emailVerified) {
          return Scaffold(
            body: Center(
              child: AlertDialog(
                title: Text("Correo no verificado"),
                content: Text(
                  "Debes verificar tu correo institucional para continuar.\n\n"
                      "Revisa tu bandeja de entrada.",
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      await user.sendEmailVerification();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );
                    },
                    child: Text("Reenviar correo"),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<bool>(
          future: authService.isAdminEmail(user.email ?? ''),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isAdmin = adminSnap.data == true;
            return isAdmin ? const AdminHomeScreen() : const UserHomeScreen();
          },
        );
      },
    );
  }
}
