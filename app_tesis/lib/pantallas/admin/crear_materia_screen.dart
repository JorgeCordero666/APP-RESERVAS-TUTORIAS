import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../servicios/materia_service.dart';
import '../../config/responsive_helper.dart';

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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = context.isTablet || context.isDesktop;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Crear Materia',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: context.responsiveFontSize(20),
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveHelper.centerConstrainedBox(
        context: context,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: ResponsiveHelper.getContentPadding(context),
            children: [
              ResponsiveHelper.verticalSpace(context),
              
              // Información
              Container(
                padding: EdgeInsets.all(context.responsivePadding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                  ),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getBorderRadius(context),
                  ),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.book,
                        color: Colors.blue[700],
                        size: context.responsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: Text(
                        'Registra una nueva materia en el sistema',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(13.5),
                          color: Colors.blue[900],
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              ResponsiveHelper.verticalSpace(context, multiplier: 1.5),

              // Para tablets/desktop: layout de 2 columnas
              if (isTablet) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre de la Materia',
                        icon: Icons.book,
                        hint: 'Cálculo Diferencial',
                        validator: (value) => _validarRequerido(value, 'El nombre'),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: _buildTextField(
                        controller: _codigoController,
                        label: 'Código',
                        icon: Icons.tag,
                        hint: 'MAT-101',
                        validator: _validarCodigo,
                      ),
                    ),
                  ],
                ),
                ResponsiveHelper.verticalSpace(context),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDropdown(),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: _buildTextField(
                        controller: _creditosController,
                        label: 'Créditos',
                        icon: Icons.stars,
                        hint: '4',
                        keyboardType: TextInputType.number,
                        validator: _validarCreditos,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Para móviles: layout vertical normal
                _buildTextField(
                  controller: _nombreController,
                  label: 'Nombre de la Materia',
                  icon: Icons.book,
                  hint: 'Cálculo Diferencial',
                  validator: (value) => _validarRequerido(value, 'El nombre'),
                ),
                ResponsiveHelper.verticalSpace(context),
                _buildTextField(
                  controller: _codigoController,
                  label: 'Código',
                  icon: Icons.tag,
                  hint: 'MAT-101',
                  validator: _validarCodigo,
                ),
                ResponsiveHelper.verticalSpace(context),
                _buildDropdown(),
                ResponsiveHelper.verticalSpace(context),
                _buildTextField(
                  controller: _creditosController,
                  label: 'Créditos',
                  icon: Icons.stars,
                  hint: '4',
                  keyboardType: TextInputType.number,
                  validator: _validarCreditos,
                ),
              ],
              
              ResponsiveHelper.verticalSpace(context),

              // Descripción (siempre full width)
              _buildTextField(
                controller: _descripcionController,
                label: 'Descripción (Opcional)',
                icon: Icons.description,
                hint: 'Breve descripción de la materia',
                maxLines: 3,
              ),
              
              ResponsiveHelper.verticalSpace(context, multiplier: 2),

              // Botón crear
              Container(
                height: ResponsiveHelper.getButtonHeight(context),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getBorderRadius(context),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _crearMateria,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.getBorderRadius(context),
                      ),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                size: context.responsiveIconSize(22)),
                            SizedBox(width: context.responsiveSpacing),
                            Text(
                              'Crear Materia',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(16),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 1.5),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLines != null && maxLines > 1 ? 200 : null,
        textCapitalization: label.contains('Código') 
            ? TextCapitalization.characters 
            : TextCapitalization.words,
        inputFormatters: label.contains('Código')
            ? [FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]'))]
            : label.contains('Créditos')
                ? [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(2),
                  ]
                : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: label.contains('Código')
              ? 'Ej: MAT-101, FIS-201, etc.'
              : label.contains('Créditos')
                  ? 'Entre 1 y 10'
                  : null,
          labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
          hintStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
          helperStyle: TextStyle(fontSize: context.responsiveFontSize(12)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                size: context.responsiveIconSize(20),
                color: const Color(0xFF1565C0)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          counterText: maxLines != null && maxLines > 1 ? null : '',
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsivePadding,
            vertical: 18,
          ),
          alignLabelWithHint: maxLines != null && maxLines > 1,
        ),
        style: TextStyle(fontSize: context.responsiveFontSize(14)),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getBorderRadius(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _semestreSeleccionado,
        decoration: InputDecoration(
          labelText: 'Semestre',
          labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.school,
                size: context.responsiveIconSize(20),
                color: const Color(0xFF1565C0)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveHelper.getBorderRadius(context),
            ),
            borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsivePadding,
            vertical: 18,
          ),
        ),
        style: TextStyle(
          fontSize: context.responsiveFontSize(14),
          color: Colors.black87,
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
    );
  }
}