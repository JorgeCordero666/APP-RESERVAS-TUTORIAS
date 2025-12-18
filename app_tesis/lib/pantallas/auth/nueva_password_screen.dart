import 'package:flutter/material.dart';
import '../../servicios/auth_service.dart';
import '../../config/routes.dart';
import '../../config/responsive_helper.dart';

class NuevaPasswordScreen extends StatefulWidget {
  const NuevaPasswordScreen({super.key});

  @override
  State<NuevaPasswordScreen> createState() => _NuevaPasswordScreenState();
}

class _NuevaPasswordScreenState extends State<NuevaPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _crearNuevaPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_token == null || _token!.isEmpty) {
      _mostrarError('Token no válido. Solicita un nuevo enlace de recuperación.');
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await AuthService.crearNuevaPassword(
      token: _token!,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('¡Contraseña actualizada exitosamente! Ya puedes iniciar sesión.');
      
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      AppRoutes.navigateToLogin(context);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.responsivePadding;
    final spacing = context.responsiveSpacing;
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);
    final borderRadius = ResponsiveHelper.getBorderRadius(context);
    final iconSize = context.responsiveIconSize(70);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Nueva Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.responsiveFontSize(18),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: ResponsiveHelper.centerConstrainedBox(
          context: context,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResponsiveHelper.verticalSpace(context),
                  
                  // Icono
                  Container(
                    padding: EdgeInsets.all(padding * 1.3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1565C0).withOpacity(0.15),
                          const Color(0xFF1565C0).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: iconSize,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 2.5),

                  // Título
                  Text(
                    'Crear Nueva Contraseña',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(26),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: spacing),

                  // Descripción
                  Text(
                    'Ingresa tu nueva contraseña. Debe tener al menos 8 caracteres.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14.5),
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 2.5),

                  // Información
                  Container(
                    padding: EdgeInsets.all(spacing),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.blue[100]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(color: Colors.blue[200]!, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
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
                          child: Icon(
                            Icons.security,
                            color: Colors.blue[700],
                            size: context.responsiveIconSize(24),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Text(
                            'Usa una combinación de letras, números y símbolos para mayor seguridad',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(13.5),
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 1.8),

                  // Nueva contraseña
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
                      obscureText: _obscurePassword,
                      style: TextStyle(fontSize: context.responsiveFontSize(15)),
                      decoration: InputDecoration(
                        labelText: 'Nueva Contraseña',
                        labelStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: context.responsiveFontSize(14),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          size: context.responsiveIconSize(22),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            size: context.responsiveIconSize(22),
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: spacing,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa una contraseña';
                        }
                        if (value.length < 8) {
                          return 'La contraseña debe tener al menos 8 caracteres';
                        }
                        return null;
                      },
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                  // Confirmar contraseña
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
                      obscureText: _obscureConfirmPassword,
                      style: TextStyle(fontSize: context.responsiveFontSize(15)),
                      decoration: InputDecoration(
                        labelText: 'Confirmar Contraseña',
                        labelStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: context.responsiveFontSize(14),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_clock,
                          size: context.responsiveIconSize(22),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            size: context.responsiveIconSize(22),
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: spacing,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor confirma tu contraseña';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 2.5),

                  // Botón actualizar
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
                      onPressed: _isLoading ? null : _crearNuevaPassword,
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
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'Actualizar Contraseña',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(16),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}