// lib/app/features/home/presentation/historial_prestamos_usuarios.dart

import 'package:flutter/material.dart';

class HistorialPrestamosUsuarios extends StatefulWidget {
  const HistorialPrestamosUsuarios({super.key});

  @override
  State<HistorialPrestamosUsuarios> createState() => _HistorialPrestamosUsuariosState();
}

class _HistorialPrestamosUsuariosState extends State<HistorialPrestamosUsuarios> {
  String _filter = 'todos'; // Por defecto: mostrar todos
  bool _hasLoans = false; // Cambia a true cuando haya datos reales

  @override
  Widget build(BuildContext context) {
    // ... (AppBar con PopupMenuButton como arriba)

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
            onSelected: (value) {
              setState(() {
                _filter = value;
              });
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'todos',
                child: Text(_filter == 'todos' ? '✓ Mostrar todos' : 'Mostrar todos'),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'activos',
                child: Text(_filter == 'activos' ? '✓ Activos' : 'Activos'),
              ),
              PopupMenuItem<String>(
                value: 'vencidos',
                child: Text(_filter == 'vencidos' ? '✓ Vencidos' : 'Vencidos'),
              ),
              PopupMenuItem<String>(
                value: 'devueltos',
                child: Text(_filter == 'devueltos' ? '✓ Devueltos' : 'Devueltos'),
              ),
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
              Text(
                'Historial de préstamos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Filtrado por: ${_filter == 'todos' ? 'Todos' : _filter == 'activos' ? 'Activos' : _filter == 'vencidos' ? 'Vencidos' : 'Devueltos'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: _hasLoans
                      ? ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      // Simulación de estado según filtro
                      String estado;
                      IconData icono;
                      Color colorIcono;

                      if (_filter == 'todos') {
                        estado = index % 3 == 0 ? 'Activo' : index % 3 == 1 ? 'Vencido' : 'Devuelto';
                      } else {
                        estado = _filter == 'activos' ? 'Activo' : _filter == 'vencidos' ? 'Vencido' : 'Devuelto';
                      }

                      if (estado == 'Activo') {
                        icono = Icons.check_circle_outline;
                        colorIcono = Colors.green;
                      } else if (estado == 'Vencido') {
                        icono = Icons.warning_amber_outlined;
                        colorIcono = Colors.orange;
                      } else {
                        icono = Icons.done_all;
                        colorIcono = Colors.blue;
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: const Color(0xFF1A2540).withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            'Préstamo #${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            'Fecha: 2025-06-15 | Estado: $estado',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Icon(icono, color: colorIcono),
                        ),
                      );
                    },
                  )
                      : Text(
                    'Aún no se han hecho préstamos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}