// lib/app/features/admin/presentation/edit_material_screen.dart

import 'package:flutter/material.dart';
import '../../../app/models/material_model.dart';
import '../../../app/services/firestore_service.dart';

class EditMaterialScreen extends StatefulWidget {
  final String numId;

  const EditMaterialScreen({
    super.key,
    required this.numId,
  });

  @override
  State<EditMaterialScreen> createState() => _EditMaterialScreenState();
}

class _EditMaterialScreenState extends State<EditMaterialScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _cantidadController;
  late TextEditingController _descripcionController;
  late TextEditingController _marcaController;
  late TextEditingController _modeloController;
  late TextEditingController _ubicacionController;
  late TextEditingController _carreraDeptoController;
  late TextEditingController _clasificacionController;
  late TextEditingController _tipoBienController;
  late TextEditingController _consecutivoController;
  late TextEditingController _modificadoPorController;

  MaterialModel? _originalMaterial;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadMaterial();
  }

  void _initializeControllers() {
    _cantidadController = TextEditingController();
    _descripcionController = TextEditingController();
    _marcaController = TextEditingController();
    _modeloController = TextEditingController();
    _ubicacionController = TextEditingController();
    _carreraDeptoController = TextEditingController();
    _clasificacionController = TextEditingController();
    _tipoBienController = TextEditingController();
    _consecutivoController = TextEditingController();
    _modificadoPorController = TextEditingController();
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _descripcionController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _ubicacionController.dispose();
    _carreraDeptoController.dispose();
    _clasificacionController.dispose();
    _tipoBienController.dispose();
    _consecutivoController.dispose();
    _modificadoPorController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterial() async {
    try {
      final material = await _firestoreService.getMaterial(widget.numId);

      if (material == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Material no encontrado')),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() {
        _originalMaterial = material;

        // 🔥 CORREGIDO: cantidad es int → convertir a string
        _cantidadController.text = material.cantidad.toString();

        _descripcionController.text = material.descripcion;
        _marcaController.text = material.marca;
        _modeloController.text = material.modelo;
        _ubicacionController.text = material.ubicacion;
        _carreraDeptoController.text = material.carreraDepto;
        _clasificacionController.text = material.clasificacion;
        _tipoBienController.text = material.tipoBien;
        _consecutivoController.text = material.consecutivo;

        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar material: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;

    if (_modificadoPorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa quién está modificando'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedMaterial = MaterialModel(
        numId: widget.numId,

        // 🔥 CORREGIDO: convertir a int
        cantidad: int.parse(_cantidadController.text.trim()),

        descripcion: _descripcionController.text.trim(),
        marca: _marcaController.text.trim(),
        modelo: _modeloController.text.trim(),
        ubicacion: _ubicacionController.text.trim(),
        carreraDepto: _carreraDeptoController.text.trim(),
        clasificacion: _clasificacionController.text.trim(),
        tipoBien: _tipoBienController.text.trim(),
        consecutivo: _consecutivoController.text.trim(),

        fechaRegistro: _originalMaterial!.fechaRegistro,
        fechaModificacion: DateTime.now(),
        modificadoPor: _modificadoPorController.text.trim(),
      );

      await _firestoreService.updateMaterial(
        widget.numId,
        updatedMaterial,
        _modificadoPorController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Material actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A30),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2540),
        title: Text('Editar Material #${widget.numId}'),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.white),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                'Cantidad *',
                _cantidadController,
                keyboardType: TextInputType.number,
              ),
              _buildTextField('Descripción *', _descripcionController),
              _buildTextField('Marca', _marcaController),
              _buildTextField('Modelo', _modeloController),
              _buildTextField('Ubicación *', _ubicacionController),
              _buildTextField('Carrera/Depto *', _carreraDeptoController),
              _buildTextField('Clasificación *', _clasificacionController),
              _buildTextField('Tipo bien *', _tipoBienController),
              _buildTextField('Consecutivo *', _consecutivoController),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              _buildTextField(
                'Modificado por *',
                _modificadoPorController,
                hintText: 'Nombre de quien modifica',
              ),
              const SizedBox(height: 24),
              if (_originalMaterial != null) ...[
                _buildInfoText(
                  'Fecha de registro',
                  _formatDate(_originalMaterial!.fechaRegistro),
                ),
                if (_originalMaterial!.fechaModificacion != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoText(
                    'Última modificación',
                    _formatDate(_originalMaterial!.fechaModificacion!),
                  ),
                  if (_originalMaterial!.modificadoPor != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoText(
                      'Modificado por',
                      _originalMaterial!.modificadoPor!,
                    ),
                  ],
                ],
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveMaterial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F6BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Guardar cambios',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType? keyboardType,
        String? hintText,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.black.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2F6BFF)),
          ),
        ),
        validator: (value) {
          if (label.contains('*') && (value == null || value.trim().isEmpty)) {
            return 'Este campo es obligatorio';
          }
          if (label == 'Cantidad *' && int.tryParse(value ?? '') == null) {
            return 'Ingresa un número válido';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Text(
      '$label: $value',
      style: const TextStyle(color: Colors.white70, fontSize: 12),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
