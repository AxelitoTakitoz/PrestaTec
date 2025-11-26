// lib/app/features/admin/presentation/register_item_placeholder.dart

import 'package:flutter/material.dart';
import '../../../app/models/material_model.dart';
import '../../../app/services/firestore_service.dart';

class RegisterItemPlaceholder extends StatefulWidget {
  const RegisterItemPlaceholder({super.key});

  @override
  State<RegisterItemPlaceholder> createState() =>
      _RegisterItemPlaceholderState();
}

class _RegisterItemPlaceholderState extends State<RegisterItemPlaceholder> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  static const List<String> _columns = [
    '# Num',
    'Cantidad',
    'Descripción',
    'Marca',
    'Modelo',
    'Ubicación',
    'Carrera/Depto',
    'Clasificación',
    'Tipo bien',
    'Consecutivo',
  ];

  static const List<String> _requiredFields = [
    'Cantidad',
    'Descripción',
    'Ubicación',
    'Carrera/Depto',
    'Clasificación',
    'Tipo bien',
    'Consecutivo',
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

  void _addRow() {
    setState(() {
      _items.add({
        for (final col in _columns)
          col: col == '# Num'
              ? TextEditingController(text: 'Auto')
              : TextEditingController(),
        'isRegistered': false,
      });
    });
  }

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

  Future<void> _registerRow(int index) async {
    final row = _items[index];

    if (!_isRowValid(row)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campos obligatorios incompletos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔧 CORRECCIÓN: Convertir cantidad a int
      final cantidadText = row['Cantidad'].text.trim();
      final cantidad = int.tryParse(cantidadText) ?? 0;

      // Crear modelo
      final material = MaterialModel(
        numId: '', // Se generará automáticamente
        cantidad: cantidad, // ✅ Ahora es int
        descripcion: row['Descripción'].text.trim(),
        marca: row['Marca'].text.trim(),
        modelo: row['Modelo'].text.trim(),
        ubicacion: row['Ubicación'].text.trim(),
        carreraDepto: row['Carrera/Depto'].text.trim(),
        clasificacion: row['Clasificación'].text.trim(),
        tipoBien: row['Tipo bien'].text.trim(),
        consecutivo: row['Consecutivo'].text.trim(),
        fechaRegistro: DateTime.now(),
      );

      // Guardar en Firebase
      final generatedId = await _firestoreService.createMaterial(material);

      // Convertir controllers a texto
      final Map<String, dynamic> newRow = {};
      for (final col in _columns) {
        final value = row[col];
        if (value is TextEditingController) {
          if (col == '# Num') {
            newRow[col] = generatedId;
          } else {
            newRow[col] = value.text.trim();
          }
          value.dispose();
        } else {
          newRow[col] = value;
        }
      }
      newRow['isRegistered'] = true;

      setState(() {
        _items[index] = newRow;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material #$generatedId registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _registerAll() async {
    int count = 0;
    setState(() => _isLoading = true);

    for (int i = 0; i < _items.length; i++) {
      if (!_items[i]['isRegistered'] && _isRowValid(_items[i])) {
        await _registerRow(i);
        count++;
      }
    }

    setState(() => _isLoading = false);

    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay materiales nuevos válidos por registrar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A30),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
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
                          'Registrar material nuevo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _addRow,
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
                        'No hay materiales agregados.\nPresiona "Agregar fila".',
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
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
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
                  fontSize: 12,
                ),
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
                  item[col].toString(), // ✅ Convertir a String para mostrar
                  style: const TextStyle(color: Colors.white),
                ),
              )
                  : TextField(
                controller: item[col],
                enabled: col != '# Num', // Campo automático
                keyboardType:
                col == 'Cantidad' ? TextInputType.number : null,
                style: TextStyle(
                  color: col == '# Num'
                      ? Colors.white54
                      : Colors.white,
                  fontSize: 13,
                ),
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
              onPressed:
              isRegistered || _isLoading ? null : () => _registerRow(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterAllButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerAll,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2F6BFF),
        foregroundColor: Colors.white,
      ),
      child: const Text('Registrar todos los materiales'),
    );
  }
}