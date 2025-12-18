import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../config/responsive_helper.dart';

class CambiarPasswordScreen extends StatefulWidget {
  final Usuario usuario;

  const CambiarPasswordScreen({super.key, required this.usuario});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevoController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  bool _obscurePasswordActual = true;
  bool _obscurePasswordNuevo = true;
  bool _obscurePasswordConfirmar = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevoController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  String? _validarPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  String? _validarConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu nueva contraseña';
    }
    if (value != _passwordNuevoController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordNuevoController.text != _passwordConfirmarController.text) {
      _mostrarError('Las contraseñas nuevas no coinciden');
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic>? resultado;
    try {
      if (widget.usuario.esAdministrador) {
        resultado = await PerfilService.cambiarPasswordAdministrador(
          id: widget.usuario.id,
          passwordActual: _passwordActualController.text,
          passwordNuevo: _passwordNuevoController.text,
        );
      } else if (widget.usuario.esEstudiante) {
        resultado = await PerfilService.cambiarPasswordEstudiante(
          id: widget.usuario.id,
          passwordActual: _passwordActualController.text,
          passwordNuevo: _passwordNuevoController.text,
        );
      } else if (widget.usuario.esDocente) {
        resultado = await PerfilService.cambiarPasswordDocente(
          id: widget.usuario.id,
          passwordActual: _passwordActualController.text,
          passwordNuevo: _passwordNuevoController.text,
        );
      }
    } catch (e) {
      resultado = {'error': 'Error inesperado: $e'};
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Contraseña actualizada correctamente');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Cambiar Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.responsiveFontSize(18),
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
            padding: EdgeInsets.all(padding),
            children: [
              ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
              
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
                        'La contraseña debe tener al menos 8 caracteres para garantizar la seguridad de tu cuenta',
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
              ResponsiveHelper.verticalSpace(context, multiplier: 2),

              // Contraseña actual
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
                  controller: _passwordActualController,
                  obscureText: _obscurePasswordActual,
                  style: TextStyle(fontSize: context.responsiveFontSize(15)),
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
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
                        _obscurePasswordActual ? Icons.visibility_off : Icons.visibility,
                        size: context.responsiveIconSize(22),
                      ),
                      onPressed: () {
                        setState(() => _obscurePasswordActual = !_obscurePasswordActual);
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
                      return 'Por favor ingresa tu contraseña actual';
                    }
                    return null;
                  },
                ),
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

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
                  controller: _passwordNuevoController,
                  obscureText: _obscurePasswordNuevo,
                  style: TextStyle(fontSize: context.responsiveFontSize(15)),
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    labelStyle: TextStyle(
                      color: Colors.grey[700],
                      fontSize: context.responsiveFontSize(14),
                    ),
                    prefixIcon: Icon(
                      Icons.lock,
                      size: context.responsiveIconSize(22),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePasswordNuevo ? Icons.visibility_off : Icons.visibility,
                        size: context.responsiveIconSize(22),
                      ),
                      onPressed: () {
                        setState(() => _obscurePasswordNuevo = !_obscurePasswordNuevo);
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
                  validator: _validarPassword,
                ),
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

              // Confirmar nueva contraseña
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
                  controller: _passwordConfirmarController,
                  obscureText: _obscurePasswordConfirmar,
                  style: TextStyle(fontSize: context.responsiveFontSize(15)),
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
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
                        _obscurePasswordConfirmar ? Icons.visibility_off : Icons.visibility,
                        size: context.responsiveIconSize(22),
                      ),
                      onPressed: () {
                        setState(() => _obscurePasswordConfirmar = !_obscurePasswordConfirmar);
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
                  validator: _validarConfirmPassword,
                ),
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 2.5),

              // Botón cambiar contraseña
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
                  onPressed: _isLoading ? null : _cambiarPassword,
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
                          'Cambiar Contraseña',
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
    );
  }
}