// lib/app/features/home/presentation/historial_prestamos_usuarios.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialPrestamosUsuarios extends StatefulWidget {
  const HistorialPrestamosUsuarios({super.key});

  @override
  State<HistorialPrestamosUsuarios> createState() =>
      _HistorialPrestamosUsuariosState();
}

class _HistorialPrestamosUsuariosState
    extends State<HistorialPrestamosUsuarios> {
  String _filter = 'todos';

  // ------------------------------------------------------------
  // 🔥 Función para formatear el Timestamp de Firestore
  // ------------------------------------------------------------
  String formatearFecha(Timestamp timestamp) {
    final DateTime fecha = timestamp.toDate();
    return "${fecha.day.toString().padLeft(2, '0')}/"
        "${fecha.month.toString().padLeft(2, '0')}/"
        "${fecha.year} "
        "${fecha.hour.toString().padLeft(2, '0')}:"
        "${fecha.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1D3E),
      appBar: AppBar(
        title: const Text('Historial de préstamos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'todos', child: Text("Mostrar todos")),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'activos', child: Text("Activos")),
              const PopupMenuItem(value: 'vencidos', child: Text("Vencidos")),
              const PopupMenuItem(value: 'devueltos', child: Text("Devueltos")),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historial de préstamos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Filtrado: $_filter',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('prestamos')
                      .where('correo', isEqualTo: user?.email ?? "")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "Aún no se han hecho préstamos",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    }

                    final prestamos = snapshot.data!.docs.where((doc) {
                      String estado = doc['estado'] ?? "";

                      switch (_filter) {
                        case 'activos':
                          return estado == 'activo';
                        case 'vencidos':
                          return estado == 'vencido';
                        case 'devueltos':
                          return estado == 'devuelto';
                        default:
                          return true;
                      }
                    }).toList();

                    if (prestamos.isEmpty) {
                      return const Center(
                        child: Text(
                          "No hay datos con este filtro.",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: prestamos.length,
                      itemBuilder: (context, index) {
                        final p = prestamos[index];
                        String estado = p['estado'] ?? "desconocido";

                        // ----------------------------
                        // ICONOS POR ESTADO
                        // ----------------------------
                        IconData icono;
                        Color colorIcono;

                        if (estado == 'activo') {
                          icono = Icons.check_circle_outline;
                          colorIcono = Colors.green;
                        } else if (estado == 'vencido') {
                          icono = Icons.warning_amber_outlined;
                          colorIcono = Colors.orange;
                        } else {
                          icono = Icons.done_all;
                          colorIcono = Colors.blue;
                        }

                        // ----------------------------
                        // FORMATEO DE FECHA
                        // ----------------------------
                        final fechaRaw = p['fechaPrestamo'];
                        final fechaFormateada =
                        fechaRaw is Timestamp ? formatearFecha(fechaRaw) : "-";

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          color: const Color(0xFF1A2540).withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            title: Text(
                              p['materialDescripcion'] ?? "Material",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "Prestado: $fechaFormateada\n"
                                  "Estado: $estado",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Icon(icono, color: colorIcono),
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
