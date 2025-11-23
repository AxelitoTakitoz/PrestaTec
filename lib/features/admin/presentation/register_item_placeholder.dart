// lib/app/features/admin/presentation/register_item_placeholder.dart

import 'package:flutter/material.dart';

class RegisterItemPlaceholder extends StatefulWidget {
  const RegisterItemPlaceholder({super.key});

  @override
  State<RegisterItemPlaceholder> createState() =>
      _RegisterItemPlaceholderState();
}

class _RegisterItemPlaceholderState extends State<RegisterItemPlaceholder> {
  // Lista de bienes (cada bien puede ser controllers o texto si ya está registrado)
  List<Map<String, dynamic>> _items = [];

  // Columnas de la tabla (ACTUALIZADAS)
  static const List<String> _columns = [
    'Cantidad',
    'Descripción',
    'Marca',
    'Modelo',
    'Ubicación',
    'Carrera/Depto',
    'Clasificación',
    'Tipo bien',
    '# Num.',           // <---- NUEVO CAMPO
    'Consecutivo',
    'No Inventario',    // <---- NUEVO CAMPO AL FINAL
  ];

  // Campos obligatorios (ACTUALIZADOS)
  static const List<String> _requiredFields = [
    'Cantidad',
    'Descripción',
    'Ubicación',
    'Carrera/Depto',
    'Clasificación',
    'Tipo bien',
    '# Num.',
    'Consecutivo',
    'No Inventario',
  ];

  @override
  void dispose() {
    _disposeAllControllers();
    super.dispose();
  }

  void _disposeAllControllers() {
    for (var item in _items) {
      item.forEach((key, value) {
        if (value is TextEditingController) {
          value.dispose();
        }
      });
    }
  }

  // Crear nueva fila
  void _addRow() {
    setState(() {
      _items.add({
        for (final col in _columns) col: TextEditingController(),
        'isRegistered': false,
      });
    });
  }

  // Validar fila
  bool _isRowValid(Map<String, dynamic> row) {
    for (final field in _requiredFields) {
      final value = row[field];

      if (value is TextEditingController) {
        if (value.text.trim().isEmpty) return false;
      } else if (value is String) {
        if (value.trim().isEmpty) return false;
      } else {
        return false;
      }

      if (field == 'Cantidad' &&
          int.tryParse(value is String ? value : value.text) == null) {
        return false;
      }
    }
    return true;
  }

  // Registrar una fila
  void _registerRow(int index) {
    final row = _items[index];

    if (!_isRowValid(row)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos obligatorios incompletos')),
      );
      return;
    }

    // Convertir controllers a texto final
    final Map<String, dynamic> newRow = {};

    for (final col in _columns) {
      final value = row[col];
      if (value is TextEditingController) {
        newRow[col] = value.text.trim();
        value.dispose();
      } else {
        newRow[col] = value;
      }
    }

    newRow['isRegistered'] = true;

    setState(() {
      _items[index] = newRow;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bien #${index + 1} registrado correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A30),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Registrar producto nuevo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 16),

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar fila'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F6BFF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: _items.isEmpty
                    ? const Center(
                  child: Text(
                    'No hay bienes agregados.\nPresiona "Agregar fila".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                    : _buildTable(),
              ),

              const SizedBox(height: 16),

              _buildRegisterAllButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            for (int i = 0; i < _items.length; i++) _buildRow(_items[i], i),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF1A2540),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          for (final col in _columns)
            SizedBox(
              width: col == 'Descripción' ? 200 : 120,
              child: Text(
                col,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item, int index) {
    final isRegistered = item['isRegistered'] as bool;

    return Container(
      color: isRegistered
          ? Colors.green.withOpacity(0.15)
          : Colors.white.withOpacity(0.05),
      padding: const EdgeInsets.symmetric(vertical: 8),
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          for (final col in _columns)
            SizedBox(
              width: col == 'Descripción' ? 200 : 120,
              child: isRegistered
                  ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  item[col],
                  style: const TextStyle(color: Colors.white),
                ),
              )
                  : TextField(
                controller: item[col],
                keyboardType:
                col == 'Cantidad' ? TextInputType.number : null,
                style:
                const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  contentPadding: const EdgeInsets.all(6),
                ),
              ),
            ),

          SizedBox(
            width: 60,
            child: IconButton(
              icon: Icon(
                isRegistered ? Icons.check_circle : Icons.check_circle_outline,
                color: Colors.green,
              ),
              onPressed: isRegistered ? null : () => _registerRow(index),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRegisterAllButton() {
    return ElevatedButton(
      onPressed: () {
        int count = 0;

        for (int i = 0; i < _items.length; i++) {
          if (!_items[i]['isRegistered'] && _isRowValid(_items[i])) {
            _registerRow(i);
            count++;
          }
        }

        if (count == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No hay bienes nuevos válidos por registrar')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F6BFF),
        foregroundColor: Colors.white,
      ),
      child: const Text('Registrar todos los bienes'),
    );
  }
}
