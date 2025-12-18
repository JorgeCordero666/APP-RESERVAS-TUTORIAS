import 'package:flutter/material.dart';
import '../../servicios/estudiante_service.dart';
import '../../config/responsive_helper.dart';

class EditarEstudianteScreen extends StatefulWidget {
  final Map<String, dynamic> estudiante;

  const EditarEstudianteScreen({super.key, required this.estudiante});

  @override
  State<EditarEstudianteScreen> createState() => _EditarEstudianteScreenState();
}

class _EditarEstudianteScreenState extends State<EditarEstudianteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarDatosIniciales();
  }

  void _cargarDatosIniciales() {
    _nombreController = TextEditingController(text: widget.estudiante['nombreEstudiante']);
    _emailController = TextEditingController(text: widget.estudiante['emailEstudiante']);
    _telefonoController = TextEditingController(text: widget.estudiante['telefono'] ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  String? _validarRequerido(String? value, String campo) {
    if (value == null || value.isEmpty) {
      return '$campo es obligatorio';
    }
    return null;
  }

  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length < 10) {
        return 'El teléfono debe tener al menos 10 dígitos';
      }
    }
    return null;
  }

  Future<void> _actualizarEstudiante() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await EstudianteService.actualizarEstudiante(
      id: widget.estudiante['_id'],
      nombreEstudiante: _nombreController.text.trim(),
      emailEstudiante: _emailController.text.trim(),
      telefono: _telefonoController.text.trim().isEmpty 
          ? null 
          : _telefonoController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Estudiante actualizado exitosamente');
      
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
    final isTablet = context.isTablet || context.isDesktop;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Editar Estudiante',
          style: TextStyle(
            fontSize: context.responsiveFontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.getBorderRadius(context),
                  ),
                  border: Border.all(color: Colors.blue[200]!, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: context.responsiveIconSize(24),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: Text(
                        'Actualiza la información del estudiante.',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(13),
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              ResponsiveHelper.verticalSpace(context, multiplier: 1.5),

              // Layout responsive
              if (isTablet) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _nombreController,
                        label: 'Nombre Completo',
                        icon: Icons.person,
                        validator: (value) => _validarRequerido(value, 'El nombre'),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: _buildTextField(
                        controller: _emailController,
                        label: 'Correo Electrónico',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validarEmail,
                      ),
                    ),
                  ],
                ),
                ResponsiveHelper.verticalSpace(context),
                _buildTextField(
                  controller: _telefonoController,
                  label: 'Teléfono (Opcional)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: _validarTelefono,
                ),
              ] else ...[
                _buildTextField(
                  controller: _nombreController,
                  label: 'Nombre Completo',
                  icon: Icons.person,
                  validator: (value) => _validarRequerido(value, 'El nombre'),
                ),
                ResponsiveHelper.verticalSpace(context),
                _buildTextField(
                  controller: _emailController,
                  label: 'Correo Electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validarEmail,
                ),
                ResponsiveHelper.verticalSpace(context),
                _buildTextField(
                  controller: _telefonoController,
                  label: 'Teléfono (Opcional)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: _validarTelefono,
                ),
              ],
              
              ResponsiveHelper.verticalSpace(context, multiplier: 2),

              // Botón actualizar
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
                  onPressed: _isLoading ? null : _actualizarEstudiante,
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
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save, 
                              size: context.responsiveIconSize(22)),
                            SizedBox(width: context.responsiveSpacing),
                            Text(
                              'Actualizar Estudiante',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(16),
                                fontWeight: FontWeight.w600,
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
    TextInputType? keyboardType,
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
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: context.responsiveFontSize(14)),
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsivePadding,
            vertical: 18,
          ),
        ),
        style: TextStyle(fontSize: context.responsiveFontSize(14)),
        validator: validator,
      ),
    );
  }
}