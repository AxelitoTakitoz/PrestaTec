// lib/features/home/presentation/admin_home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../app/routes.dart';
import '../../admin/presentation/historial_prestamos_admin.dart';
import '../../admin/presentation/generar_reporte_admin.dart';
import '../../admin/presentation/materials_list_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interfaz de administrador'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),
            ],
            icon: const Icon(Icons.more_horiz),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topLeft,
          child: Text('Sin prestamos activos'),
        ),
      ),
      bottomNavigationBar: _CurvedActionsBar(
        primary: cs.primary,
        surface: cs.surface,
        onSurface: cs.onSurface,
        onPrimary: cs.onPrimary,
        onRegister: () =>
            Navigator.of(context).pushNamed(AppRoutes.registerItem),
        onHistory: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AdminHistorialPrestamosScreen(),
          ),
        ),
        onReport: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const GenerarReporteAdmin(),
          ),
        ),
        onMaterialsList: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const MaterialsListScreen(),
          ),
        ),
      ),
    );
  }
}

class _CurvedActionsBar extends StatelessWidget {
  final Color primary;
  final Color surface;
  final Color onSurface;
  final Color onPrimary;
  final VoidCallback onRegister;
  final VoidCallback onHistory;
  final VoidCallback onReport;
  final VoidCallback onMaterialsList;

  const _CurvedActionsBar({
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.onPrimary,
    required this.onRegister,
    required this.onHistory,
    required this.onReport,
    required this.onMaterialsList,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 240,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: CustomPaint(painter: _ArcPainter(color: primary))),
            Positioned(
              top: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    elevation: 10,
                    color: surface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRegister,
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Icon(Icons.qr_code_2, size: 44, color: onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Registrar\narticulo\nnuevo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: onPrimary,
                      fontSize: 12,
                      height: 1.05,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionBubble(
                        icon: Icons.history,
                        label: 'Historial\nde prestamos',
                        surface: surface,
                        onSurface: onSurface,
                        textColor: onPrimary,
                        onTap: onHistory,
                      ),
                      const SizedBox(height: 16),
                      _ActionBubble(
                        icon: Icons.list_alt,
                        label: 'Ver lista de\nmateriales',
                        surface: surface,
                        onSurface: onSurface,
                        textColor: onPrimary,
                        onTap: onMaterialsList,
                      ),
                    ],
                  ),
                  _ActionBubble(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'Generar\nreporte',
                    surface: surface,
                    onSurface: onSurface,
                    textColor: onPrimary,
                    onTap: onReport,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBubble extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color surface;
  final Color onSurface;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionBubble({
    required this.icon,
    required this.label,
    required this.surface,
    required this.onSurface,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 8,
          color: surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Icon(icon, color: onSurface, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontSize: 12, height: 1.15),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final Color color;
  _ArcPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 60)
      ..quadraticBezierTo(size.width / 2, -80, size.width, 60)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.color != color;
}
