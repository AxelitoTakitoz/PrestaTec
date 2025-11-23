import 'package:flutter/material.dart';
import 'historial_prestamos_usuario.dart';
import 'solicitar_articulo.dart';
import '../../../app/routes.dart';

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  // Función para confirmar y cerrar sesión
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Está seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
                // Navega al login y elimina el historial
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interfaz del usuario'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _confirmLogout(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'logout',
                child: const Text('Cerrar sesión'),
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
      bottomNavigationBar: _CurvedActionsBarUser(
        primary: cs.primary,
        surface: cs.surface,
        onSurface: cs.onSurface,
        onPrimary: cs.onPrimary,
        onHistory: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HistorialPrestamosUsuarios(),
            ),
          );
        },
        onRequest: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SolicitarArticulo(),
            ),
          );
        },
      ),
    );
  }
}

class _CurvedActionsBarUser extends StatelessWidget {
  final Color primary;
  final Color surface;
  final Color onSurface;
  final Color onPrimary;
  final VoidCallback onHistory;
  final VoidCallback onRequest;

  const _CurvedActionsBarUser({
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.onPrimary,
    required this.onHistory,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 160,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: CustomPaint(painter: _ArcPainter(color: primary))),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ActionBubble(
                    icon: Icons.history,
                    label: 'Historial\nde prestamos',
                    surface: surface,
                    onSurface: onSurface,
                    textColor: onPrimary,
                    onTap: onHistory,
                  ),
                  _ActionBubble(
                    icon: Icons.add_shopping_cart_outlined,
                    label: 'Solicitar\narticulo',
                    surface: surface,
                    onSurface: onSurface,
                    textColor: onPrimary,
                    onTap: onRequest,
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
      ..moveTo(0, 50)
      ..quadraticBezierTo(size.width / 2, -60, size.width, 50)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.color != color;
}