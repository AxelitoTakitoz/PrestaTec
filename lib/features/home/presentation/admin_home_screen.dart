import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../app/routes.dart';
import '../../admin/presentation/historial_prestamos_admin.dart';
import '../../admin/presentation/generar_reporte_admin.dart';
import '../../admin/presentation/materials_list_screen.dart';
import '../../admin/presentation/ver_perfil_admin.dart';
import '../../admin/presentation/prestamos_list_screen.dart';
import '../../admin/presentation/admin_scan_qr_screen.dart';
import '../../admin/presentation/admin_confirm_prestamo_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  // FORMATEAR TIMESTAMP A FECHA/HORA
  String _formatTimestamp(dynamic ts) {
    if (ts == null) return "No disponible";

    if (ts is Timestamp) {
      final d = ts.toDate();
      final fecha =
          "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
      final hora =
          "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

      return "$fecha  |  $hora";
    }

    return ts.toString();
  }

  // LOGOUT
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
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

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
            (_) => false,
      );
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VerPerfilAdmin()),
    );
  }

  void _navigateToScanQr(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const AdminScanQrScreen()),
    );

    if (result != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminConfirmPrestamoScreen(userData: result),
        ),
      );
    }
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
              if (value == 'profile') {
                _navigateToProfile(context);
              } else if (value == 'logout') {
                _confirmLogout(context);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, size: 20),
                    SizedBox(width: 12),
                    Text('Ver perfil'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 12),
                    Text('Cerrar sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      // -------------------------------
      // LISTA DE PRÉSTAMOS ACTIVOS
      // -------------------------------
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('prestamos')
              .where('estado', isEqualTo: 'activo')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Cargando préstamos...");
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Sin préstamos activos",
                  style: TextStyle(fontSize: 18),
                ),
              );
            }

            final prestamos = snapshot.data!.docs;

            return ListView.builder(
              itemCount: prestamos.length,
              itemBuilder: (context, index) {
                final p = prestamos[index].data() as Map<String, dynamic>;

                // 🔥 CORREGIDO AQUÍ 🔥
                final nombre = p["nombreCompleto"] ?? "Desconocido";
                final tipo = p["rol"] ?? "N/A";
                final articulo = p["materialDescripcion"] ?? "N/A";
                final fecha = _formatTimestamp(p["fechaPrestamo"]);

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(bottom: 14),
                  child: ListTile(
                    leading: const Icon(Icons.person, size: 32),
                    title: Text(
                      nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Tipo: $tipo"),
                        Text("Artículo: $articulo"),
                        Text("Fecha y hora: $fecha"),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),

      bottomNavigationBar: _CurvedActionsBar(
        primary: cs.primary,
        surface: cs.surface,
        onSurface: cs.onSurface,
        onPrimary: cs.onPrimary,
        onScanQr: () => _navigateToScanQr(context),
        onRegister: () => Navigator.of(context).pushNamed(AppRoutes.registerItem),
        onHistory: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AdminHistorialPrestamosScreen()),
        ),
        onReport: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GenerarReporteAdmin()),
        ),
        onMaterialsList: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MaterialsListScreen()),
        ),
        onPrestamosList: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PrestamosListScreen()),
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
  final VoidCallback onScanQr;
  final VoidCallback onRegister;
  final VoidCallback onHistory;
  final VoidCallback onReport;
  final VoidCallback onMaterialsList;
  final VoidCallback onPrestamosList;

  const _CurvedActionsBar({
    required this.primary,
    required this.surface,
    required this.onSurface,
    required this.onPrimary,
    required this.onScanQr,
    required this.onRegister,
    required this.onHistory,
    required this.onReport,
    required this.onMaterialsList,
    required this.onPrestamosList,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: 270,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ArcPainter(color: primary)),
            ),

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
                      onTap: onScanQr,
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Icon(Icons.qr_code_scanner,
                            size: 44, color: onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escanear\nQR de\nusuario',
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
                        icon: Icons.add_box,
                        label: 'Registrar\nartículo',
                        surface: surface,
                        onSurface: onSurface,
                        textColor: onPrimary,
                        onTap: onRegister,
                      ),
                      const SizedBox(height: 16),
                      _ActionBubble(
                        icon: Icons.list_alt,
                        label: 'Lista de\nmateriales',
                        surface: surface,
                        onSurface: onSurface,
                        textColor: onPrimary,
                        onTap: onMaterialsList,
                      ),
                    ],
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ActionBubble(
                        icon: Icons.assignment_turned_in,
                        label: 'Gestión de\npréstamos',
                        surface: surface,
                        onSurface: onSurface,
                        textColor: onPrimary,
                        onTap: onPrestamosList,
                      ),
                      const SizedBox(height: 16),
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
      ..moveTo(0, 0)
      ..quadraticBezierTo(size.width / 2, -120, size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.color != color;
}
