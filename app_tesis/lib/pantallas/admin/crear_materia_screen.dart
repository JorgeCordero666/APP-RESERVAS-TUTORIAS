// lib/pantallas/admin/crear_materia_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../servicios/materia_service.dart';

class CrearMateriaScreen extends StatefulWidget {
  const CrearMateriaScreen({super.key});

  @override
  State<CrearMateriaScreen> createState() => _CrearMateriaScreenState();
}

class _CrearMateriaScreenState extends State<CrearMateriaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _creditosController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String? _semestreSeleccionado;
  bool _isLoading = false;

  final List<String> _semestres = [
    'Nivelación',
    'Primer Semestre',
    'Segundo Semestre',
    'Tercer Semestre',
    'Cuarto Semestre',
    'Quinto Semestre',
    'Sexto Semestre',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _creditosController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String? _validarRequerido(String? value, String campo) {
    if (value == null || value.isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  String? _validarCodigo(String? value) {
    if (value == null || value.isEmpty) {
      return 'El código es obligatorio';
    }
    if (value.length < 3 || value.length > 10) {
      return 'El código debe tener entre 3 y 10 caracteres';
    }
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(value.toUpperCase())) {
      return 'Solo letras mayúsculas, números y guiones';
    }
    return null;
  }

  String? _validarCreditos(String? value) {
    if (value == null || value.isEmpty) {
      return 'Los créditos son obligatorios';
    }
    final creditos = int.tryParse(value);
    if (creditos == null) {
      return 'Debe ser un número';
    }
    if (creditos < 1 || creditos > 10) {
      return 'Debe estar entre 1 y 10';
    }
    return null;
  }

  Future<void> _crearMateria() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_semestreSeleccionado == null) {
      _mostrarError('Por favor selecciona un semestre');
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await MateriaService.crearMateria(
      nombre: _nombreController.text.trim(),
      codigo: _codigoController.text.trim().toUpperCase(),
      semestre: _semestreSeleccionado!,
      creditos: int.parse(_creditosController.text),
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Materia creada exitosamente');
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Materia'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Información
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registra una nueva materia en el sistema',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre de la Materia',
                prefixIcon: const Icon(Icons.book),
                hintText: 'Cálculo Diferencial',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => _validarRequerido(value, 'El nombre'),
            ),
            const SizedBox(height: 16),

            // Código
            TextFormField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: 'Código',
                prefixIcon: const Icon(Icons.tag),
                hintText: 'MAT-101',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Ej: MAT-101, FIS-201, etc.',
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
              ],
              validator: _validarCodigo,
            ),
            const SizedBox(height: 16),

            // Semestre
            DropdownButtonFormField<String>(
              value: _semestreSeleccionado,
              decoration: InputDecoration(
                labelText: 'Semestre',
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _semestres.map((semestre) {
                return DropdownMenuItem(
                  value: semestre,
                  child: Text(semestre),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _semestreSeleccionado = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Selecciona un semestre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Créditos
            TextFormField(
              controller: _creditosController,
              decoration: InputDecoration(
                labelText: 'Créditos',
                prefixIcon: const Icon(Icons.stars),
                hintText: '4',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText: 'Entre 1 y 10',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              validator: _validarCreditos,
            ),
            const SizedBox(height: 16),

            // Descripción
            TextFormField(
              controller: _descripcionController,
              decoration: InputDecoration(
                labelText: 'Descripción (Opcional)',
                prefixIcon: const Icon(Icons.description),
                hintText: 'Breve descripción de la materia',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: 32),

            // Botón crear
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _crearMateria,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Crear Materia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}