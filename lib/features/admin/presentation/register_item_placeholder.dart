import 'package:flutter/material.dart';

class RegisterItemPlaceholder extends StatefulWidget {
  const RegisterItemPlaceholder({super.key});

  @override
  State<RegisterItemPlaceholder> createState() => _RegisterItemPlaceholderState();
}

class _RegisterItemPlaceholderState extends State<RegisterItemPlaceholder> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para cada campo
  final _cantidadCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _modeloCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _carreraDeptoCtrl = TextEditingController();
  final _clasificacionCtrl = TextEditingController();
  final _tipoBienCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _consecutivoCtrl = TextEditingController();

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _descripcionCtrl.dispose();
    _marcaCtrl.dispose();
    _modeloCtrl.dispose();
    _ubicacionCtrl.dispose();
    _carreraDeptoCtrl.dispose();
    _clasificacionCtrl.dispose();
    _tipoBienCtrl.dispose();
    _numeroCtrl.dispose();
    _consecutivoCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bien registrado correctamente')),
      );
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121A30), //
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloque de titulo y regreso
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Registrar producto nuevo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  //Espacio para mantener el título centrado visualmente
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Completa los campos obligatorios para registrar un nuevo bien.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 8),
              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(_cantidadCtrl, 'Cantidad', isRequired: true, keyboardType: TextInputType.number),
                        _buildTextField(_descripcionCtrl, 'Descripción de los bienes', isRequired: true),
                        _buildTextField(_marcaCtrl, 'Marca', isRequired: false),
                        _buildTextField(_modeloCtrl, 'Modelo', isRequired: false),
                        _buildTextField(_ubicacionCtrl, 'Ubicación', isRequired: true),
                        _buildTextField(_carreraDeptoCtrl, 'Carrera o Depto', isRequired: true),
                        _buildTextField(_clasificacionCtrl, 'Clasificación del bien', isRequired: true),
                        _buildTextField(_tipoBienCtrl, 'Tipo de bien', isRequired: true),
                        _buildTextField(_numeroCtrl, '#', isRequired: true),
                        _buildTextField(_consecutivoCtrl, 'No. Consecutivo de bienes', isRequired: true),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2F6BFF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _onSubmit,
                          child: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool isRequired = true,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white30),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color(0xFF2F6BFF), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'Este campo es requerido';
          }
          if (keyboardType == TextInputType.number && value != null && value.isNotEmpty) {
            if (int.tryParse(value) == null) {
              return 'Debe ser un número válido';
            }
          }
          return null;
        },
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}