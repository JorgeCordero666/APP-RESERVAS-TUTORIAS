import 'package:flutter/material.dart';
import '../../servicios/docente_service.dart';
import '../../config/responsive_helper.dart';

class CrearDocenteScreen extends StatefulWidget {
  const CrearDocenteScreen({super.key});

  @override
  State<CrearDocenteScreen> createState() => _CrearDocenteScreenState();
}

class _CrearDocenteScreenState extends State<CrearDocenteScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nombreController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _emailController = TextEditingController();
  final _celularController = TextEditingController();
  final _oficinaController = TextEditingController();
  final _emailAlternativoController = TextEditingController();
  
  bool _isLoading = false;
  DateTime? _fechaNacimiento;
  DateTime? _fechaIngreso;

  @override
  void dispose() {
    _nombreController.dispose();
    _cedulaController.dispose();
    _emailController.dispose();
    _celularController.dispose();
    _oficinaController.dispose();
    _emailAlternativoController.dispose();
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

  String? _validarCedula(String? value) {
    if (value == null || value.isEmpty) {
      return 'La cédula es obligatoria';
    }
    if (value.length != 10) {
      return 'La cédula debe tener 10 dígitos';
    }
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'La cédula solo debe contener números';
    }
    return null;
  }

  String? _validarTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'El celular es obligatorio';
    }
    if (value.length < 10) {
      return 'El celular debe tener al menos 10 dígitos';
    }
    return null;
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esNacimiento) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (esNacimiento) {
          _fechaNacimiento = picked;
        } else {
          _fechaIngreso = picked;
        }
      });
    }
  }

  Future<void> _registrarDocente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaNacimiento == null) {
      _mostrarError('Por favor selecciona la fecha de nacimiento');
      return;
    }

    final fechaActual = DateTime.now();
    final edad = fechaActual.year - _fechaNacimiento!.year;
    final mesActual = fechaActual.month;
    final diaActual = fechaActual.day;

    int edadReal = edad;
    if (mesActual < _fechaNacimiento!.month ||
        (mesActual == _fechaNacimiento!.month && diaActual < _fechaNacimiento!.day)) {
      edadReal = edad - 1;
    }

    if (_fechaNacimiento!.year < 1960) {
      _mostrarError('El año de nacimiento debe ser 1960 o posterior');
      return;
    }

    if (edadReal < 18) {
      _mostrarError('El docente debe tener al menos 18 años');
      return;
    }

    if (_fechaIngreso == null) {
      _mostrarError('Por favor selecciona la fecha de ingreso');
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await DocenteService.registrarDocente(
      nombreDocente: _nombreController.text.trim(),
      cedulaDocente: _cedulaController.text.trim(),
      emailDocente: _emailController.text.trim(),
      celularDocente: _celularController.text.trim(),
      oficinaDocente: _oficinaController.text.trim(),
      emailAlternativoDocente: _emailAlternativoController.text.trim(),
      fechaNacimientoDocente: _fechaNacimiento!.toIso8601String().split('T')[0],
      fechaIngresoDocente: _fechaIngreso!.toIso8601String().split('T')[0],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Docente registrado exitosamente. Se envió un correo con las credenciales.');
      
      await Future.delayed(const Duration(seconds: 2));
      
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Crear Docente',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            fontSize: context.responsiveFontSize(20),
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
              
              // Banner informativo
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
                        Icons.info_outline,
                        color: Colors.blue[700],
                        size: context.responsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: Text(
                        'El sistema generará automáticamente una contraseña y la enviará por correo al docente.',
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

              // Sección: Información Personal
              _buildSeccionTitulo('Información Personal', Icons.person_outline),
              ResponsiveHelper.verticalSpace(context),

              _buildTextField(
                controller: _nombreController,
                label: 'Nombre Completo',
                icon: Icons.person,
                hint: 'Dr. Juan Pérez',
                validator: (value) => _validarRequerido(value, 'El nombre'),
              ),
              ResponsiveHelper.verticalSpace(context),

              _buildTextField(
                controller: _cedulaController,
                label: 'Cédula',
                icon: Icons.badge,
                hint: '1234567890',
                keyboardType: TextInputType.number,
                maxLength: 10,
                validator: _validarCedula,
              ),
              ResponsiveHelper.verticalSpace(context),

              _buildDateField(
                label: 'Fecha de Nacimiento',
                icon: Icons.cake_outlined,
                fecha: _fechaNacimiento,
                onTap: () => _seleccionarFecha(context, true),
              ),
              ResponsiveHelper.verticalSpace(context),

              _buildDateField(
                label: 'Fecha de Ingreso',
                icon: Icons.event_available,
                fecha: _fechaIngreso,
                onTap: () => _seleccionarFecha(context, false),
              ),
              
              ResponsiveHelper.verticalSpace(context, multiplier: 1.5),

              // Sección: Información de Contacto
              _buildSeccionTitulo('Información de Contacto', Icons.contact_mail_outlined),
              ResponsiveHelper.verticalSpace(context),

              _buildTextField(
                controller: _emailController,
                label: 'Correo Institucional',
                icon: Icons.email,
                hint: 'docente@epn.edu.ec',
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              ResponsiveHelper.verticalSpace(context),

              _buildTextField(
                controller: _emailAlternativoController,
                label: 'Correo Alternativo',
                icon: Icons.alternate_email,
                hint: 'docente@gmail.com',
                keyboardType: TextInputType.emailAddress,
                validator: _validarEmail,
              ),
              ResponsiveHelper.verticalSpace(context),

              _buildTextField(
                controller: _celularController,
                label: 'Celular',
                icon: Icons.phone_android,
                hint: '0987654321',
                keyboardType: TextInputType.phone,
                validator: _validarTelefono,
              ),
              ResponsiveHelper.verticalSpace(context),

              _buildTextField(
                controller: _oficinaController,
                label: 'Oficina',
                icon: Icons.meeting_room,
                hint: 'Edificio A - Oficina 101',
                validator: (value) => _validarRequerido(value, 'La oficina'),
              ),
              
              ResponsiveHelper.verticalSpace(context, multiplier: 2),

              // Botón registrar
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
                  onPressed: _isLoading ? null : _registrarDocente,
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
                            Icon(Icons.person_add, 
                              size: context.responsiveIconSize(22)),
                            SizedBox(width: context.responsiveSpacing),
                            Text(
                              'Registrar Docente',
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

  Widget _buildSeccionTitulo(String titulo, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF1565C0),
            size: context.responsiveIconSize(22),
          ),
        ),
        SizedBox(width: context.responsiveSpacing),
        Text(
          titulo,
          style: TextStyle(
            fontSize: context.responsiveFontSize(18),
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1565C0),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
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
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            fontSize: context.responsiveFontSize(14),
          ),
          hintStyle: TextStyle(
            fontSize: context.responsiveFontSize(14),
          ),
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
          counterText: '',
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

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? fecha,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        ResponsiveHelper.getBorderRadius(context),
      ),
      child: Container(
        padding: EdgeInsets.all(context.responsivePadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            ResponsiveHelper.getBorderRadius(context),
          ),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, 
                size: context.responsiveIconSize(20), 
                color: const Color(0xFF1565C0)),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(12),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fecha == null
                        ? 'Seleccionar fecha'
                        : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(16),
                      color: fecha == null ? Colors.grey[400] : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_month,
              color: Colors.grey[400],
              size: context.responsiveIconSize(22),
            ),
          ],
        ),
      ),
    );
  }
}