// lib/features/auth/presentation/role_gate_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart';
import 'package:prestatec01/app/auth_service.dart';

// tus pantallas reales
import '../../home/presentation/admin_home_screen.dart';
import '../../home/presentation/user_home_screen.dart';

class RoleGateScreen extends StatelessWidget {
  const RoleGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
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

        return FutureBuilder<bool>(
          future: authService.isAdmin(),
          builder: (context, adminSnap) {
            if (adminSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final isAdmin = adminSnap.data ?? false;

            // DEBUG consola
            // ignore: avoid_print
            print("DEBUG RoleGate -> email=${user.email} isAdmin=$isAdmin");

            if (isAdmin) {
              return AdminHomeScreen();
            }

            // 👇 TEMPORAL: si NO es admin, mostramos debug
            return _NotAdminDebugScreen(currentEmail: user.email ?? '');
          },
        );
      },
    );
  }
}

class _NotAdminDebugScreen extends StatefulWidget {
  final String currentEmail;
  const _NotAdminDebugScreen({required this.currentEmail});

  @override
  State<_NotAdminDebugScreen> createState() => _NotAdminDebugScreenState();
}

class _NotAdminDebugScreenState extends State<_NotAdminDebugScreen> {
  bool loading = true;
  String? error;
  List<String> adminDocIds = [];

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  Future<void> _loadAdmins() async {
    setState(() {
      loading = true;
      error = null;
      adminDocIds = [];
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('admins')
          .limit(50)
          .get();

      adminDocIds = snap.docs.map((d) => d.id).toList();
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final emailLower = widget.currentEmail.trim().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG: no eres admin'),
        actions: [
          IconButton(
            onPressed: _loadAdmins,
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📌 Email con el que te logueaste:",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            SelectableText(widget.currentEmail),

            const SizedBox(height: 12),
            Text("📌 Email normalizado (lo que busca tu app):",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            SelectableText(emailLower),

            const Divider(height: 24),

            if (error != null) ...[
              Text("❌ Error leyendo admins:",
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 6),
              SelectableText(error!),
              const SizedBox(height: 12),
              const Text(
                "Si aquí sale permission-denied, tus reglas NO permiten listar admins.",
                style: TextStyle(color: Colors.orange),
              ),
            ] else ...[
              Text("📌 Docs que tu app ve en /admins:",
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Expanded(
                child: adminDocIds.isEmpty
                    ? const Text("No hay documentos visibles en admins.")
                    : ListView.builder(
                  itemCount: adminDocIds.length,
                  itemBuilder: (context, i) {
                    final id = adminDocIds[i];
                    final match = id.toLowerCase() == emailLower;
                    return ListTile(
                      title: Text(id),
                      trailing: match
                          ? const Icon(Icons.check_circle,
                          color: Colors.green)
                          : null,
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => UserHomeScreen()),
                  );
                },
                child: const Text("Continuar como usuario (debug)"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
