import 'package:flutter/material.dart';
import 'package:app_tesis/servicios/auth_service.dart';
import 'package:app_tesis/config/routes.dart';
import 'package:app_tesis/config/responsive_helper.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();

  bool _isLoading = false;
  bool _mostrarPassword = false;
  bool _mostrarConfirmPassword = false;
  bool _emailEsInstitucional = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  bool _esEmailInstitucional(String email) {
    return email.toLowerCase().contains('@epn.edu.ec');
  }

  Future<bool> _validarEmailInstitucional(String email) async {
    if (_esEmailInstitucional(email)) {
      final confirmacion = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.business, color: Colors.orange[700], size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Email Institucional',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Eres docente?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Si eres docente, debes contactar al administrador de tu institución para que te registre en el sistema. Los docentes no pueden auto-registrarse.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, soy estudiante', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Soy docente'),
            ),
          ],
        ),
      );

      if (confirmacion == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Para registrarte como docente, contacta al administrador de tu institución.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              backgroundColor: Colors.orange[700],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return false;
      }
      return true;
    }
    return true;
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

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  String? _validarConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  String? _validarRequerido(String? value, String campo) {
    if (value == null || value.isEmpty) {
      return '$campo es obligatorio';
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

  Future<void> _registrarEstudiante() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final emailValido = await _validarEmailInstitucional(_emailController.text.trim());
    if (!emailValido) {
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.registrarEstudiante(
      nombre: _nombreController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      telefono: _telefonoController.text.trim().isEmpty
          ? null
          : _telefonoController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (resultado != null && !resultado.containsKey('error')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Registro exitoso. Verifica tu correo para confirmar tu cuenta',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFF388E3C),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );

        _formKey.currentState!.reset();
        _nombreController.clear();
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _telefonoController.clear();

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            AppRoutes.navigateToLogin(context);
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resultado?['error'] ?? 'Error en el registro',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.responsivePadding;
    final spacing = context.responsiveSpacing;
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);
    final borderRadius = ResponsiveHelper.getBorderRadius(context);
    final iconSize = context.responsiveIconSize(22);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Crear Cuenta',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.responsiveFontSize(18),
          ),
        ),
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ResponsiveHelper.centerConstrainedBox(
        context: context,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResponsiveHelper.verticalSpace(context),
                
                // Título
                Text(
                  'Registro de Estudiante',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(26),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1565C0),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: spacing * 0.5),
                Text(
                  'Completa el formulario para crear tu cuenta',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: context.responsiveFontSize(14.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.8),

                // Aviso para docentes
                Container(
                  padding: EdgeInsets.all(spacing),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange[50]!, Colors.orange[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.orange[300]!, width: 1.5),
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing * 0.8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.info, color: Colors.orange[700], size: iconSize),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: Text(
                          '¿Eres docente? Contacta al administrador de tu institución.',
                          style: TextStyle(
                            color: Colors.orange[900],
                            fontSize: context.responsiveFontSize(13.5),
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.8),

                // Campo de nombre
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _nombreController,
                    style: TextStyle(fontSize: context.responsiveFontSize(15)),
                    decoration: InputDecoration(
                      labelText: 'Nombre Completo',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: context.responsiveFontSize(14),
                      ),
                      prefixIcon: Icon(Icons.person_outline, size: iconSize),
                      hintText: 'Juan Pérez',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                    ),
                    validator: (value) => _validarRequerido(value, 'El nombre'),
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                // Campo de email
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: context.responsiveFontSize(15)),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: context.responsiveFontSize(14),
                      ),
                      prefixIcon: Icon(Icons.email_outlined, size: iconSize),
                      hintText: 'tu@email.com',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                    ),
                    validator: _validarEmail,
                    onChanged: (value) {
                      setState(() => _emailEsInstitucional = _esEmailInstitucional(value));
                    },
                  ),
                ),
                if (_emailEsInstitucional)
                  Padding(
                    padding: EdgeInsets.only(top: spacing * 0.8, left: 4),
                    child: Row(
                      children: [
                        Icon(Icons.business, color: Colors.orange[700], size: 16),
                        SizedBox(width: spacing * 0.5),
                        Text(
                          'Email institucional detectado',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: context.responsiveFontSize(12.5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                // Campo de teléfono
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: context.responsiveFontSize(15)),
                    decoration: InputDecoration(
                      labelText: 'Teléfono (Opcional)',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: context.responsiveFontSize(14),
                      ),
                      prefixIcon: Icon(Icons.phone_outlined, size: iconSize),
                      hintText: '0987654321',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                    ),
                    validator: _validarTelefono,
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                // Campo de contraseña
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _passwordController,
                    obscureText: !_mostrarPassword,
                    style: TextStyle(fontSize: context.responsiveFontSize(15)),
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: context.responsiveFontSize(14),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, size: iconSize),
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarPassword ? Icons.visibility : Icons.visibility_off,
                          size: iconSize,
                        ),
                        onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
                      ),
                    ),
                    validator: _validarPassword,
                  ),
                ),
                SizedBox(height: spacing * 0.8),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'Mínimo 8 caracteres',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: context.responsiveFontSize(12.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                // Campo de confirmar contraseña
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_mostrarConfirmPassword,
                    style: TextStyle(fontSize: context.responsiveFontSize(15)),
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      labelStyle: TextStyle(
                        color: Colors.grey[700],
                        fontSize: context.responsiveFontSize(14),
                      ),
                      prefixIcon: Icon(Icons.lock_clock, size: iconSize),
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _mostrarConfirmPassword ? Icons.visibility : Icons.visibility_off,
                          size: iconSize,
                        ),
                        onPressed: () => setState(() => _mostrarConfirmPassword = !_mostrarConfirmPassword),
                      ),
                    ),
                    validator: (value) => _validarConfirmPassword(value, _passwordController.text),
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 2),

                // Botón de registro
                Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
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
                    onPressed: _isLoading ? null : _registrarEstudiante,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: context.responsiveIconSize(24),
                            width: context.responsiveIconSize(24),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Registrarse',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(16),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                // Ir a login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: context.responsiveFontSize(14),
                      ),
                    ),
                    TextButton(
                      onPressed: () => AppRoutes.push(context, AppRoutes.login),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: context.responsiveFontSize(14),
                        ),
                      ),
                    ),
                  ],
                ),
                ResponsiveHelper.verticalSpace(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}