import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/auth_service.dart';
import '../../config/routes.dart';
import '../../config/responsive_helper.dart';

class CambioPasswordObligatorioScreen extends StatefulWidget {
  final Usuario usuario;
  final String email;

  const CambioPasswordObligatorioScreen({
    super.key,
    required this.usuario,
    required this.email,
  });

  @override
  State<CambioPasswordObligatorioScreen> createState() =>
      _CambioPasswordObligatorioScreenState();
}

class _CambioPasswordObligatorioScreenState
    extends State<CambioPasswordObligatorioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordActualController = TextEditingController();
  final _passwordNuevaController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePasswordActual = true;
  bool _obscurePasswordNueva = true;
  bool _obscurePasswordConfirmar = true;

  @override
  void dispose() {
    _passwordActualController.dispose();
    _passwordNuevaController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  String? _validarPasswordNueva(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'Debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe incluir al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Debe incluir al menos un carácter especial';
    }
    return null;
  }

  String? _validarPasswordConfirmar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordNuevaController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _cambiarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resultado = await AuthService.cambiarPasswordObligatorio(
      email: widget.email,
      passwordActual: _passwordActualController.text,
      passwordNueva: _passwordNuevaController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Contraseña actualizada exitosamente');
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      AppRoutes.navigateToHome(context, widget.usuario);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.w500),
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
        content: Text(
          mensaje,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF388E3C),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.responsivePadding;
    final spacing = context.responsiveSpacing;
    final buttonHeight = ResponsiveHelper.getButtonHeight(context);
    final borderRadius = ResponsiveHelper.getBorderRadius(context);
    final iconSize = context.responsiveIconSize(65);

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Cambio de Contraseña Requerido',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: context.responsiveFontSize(17),
            ),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: SafeArea(
          child: ResponsiveHelper.centerConstrainedBox(
            context: context,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
                    
                    // Icono de advertencia
                    Container(
                      padding: EdgeInsets.all(padding),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange[100]!,
                            Colors.orange[50]!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: iconSize,
                        color: const Color(0xFFFF6B35),
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 2),

                    // Título
                    Text(
                      'Cambio de Contraseña Requerido',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(24),
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1565C0),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: spacing),

                    // Descripción
                    Text(
                      'Por seguridad, debes cambiar tu contraseña temporal antes de continuar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(14.5),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 1.5),

                    // Información del usuario
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
                              Icons.person,
                              color: Colors.blue[700],
                              size: context.responsiveIconSize(24),
                            ),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.usuario.nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: context.responsiveFontSize(15),
                                    color: const Color(0xFF1565C0),
                                  ),
                                ),
                                SizedBox(height: spacing * 0.3),
                                Text(
                                  widget.email,
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(13),
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 2),

                    // Campo de contraseña actual
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
                          labelText: 'Contraseña Temporal',
                          labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: context.responsiveFontSize(14),
                          ),
                          hintText: 'Ingresa la contraseña enviada por correo',
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                            return 'Ingresa tu contraseña temporal';
                          }
                          return null;
                        },
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                    // Campo de nueva contraseña
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
                        controller: _passwordNuevaController,
                        obscureText: _obscurePasswordNueva,
                        style: TextStyle(fontSize: context.responsiveFontSize(15)),
                        decoration: InputDecoration(
                          labelText: 'Nueva Contraseña',
                          labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: context.responsiveFontSize(14),
                          ),
                          hintText: 'Mínimo 8 caracteres',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.lock,
                            size: context.responsiveIconSize(22),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePasswordNueva ? Icons.visibility_off : Icons.visibility,
                              size: context.responsiveIconSize(22),
                            ),
                            onPressed: () {
                              setState(() => _obscurePasswordNueva = !_obscurePasswordNueva);
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
                        validator: _validarPasswordNueva,
                        onChanged: (value) => setState(() {}),
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
                        controller: _passwordConfirmarController,
                        obscureText: _obscurePasswordConfirmar,
                        style: TextStyle(fontSize: context.responsiveFontSize(15)),
                        decoration: InputDecoration(
                          labelText: 'Confirmar Nueva Contraseña',
                          labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: context.responsiveFontSize(14),
                          ),
                          hintText: 'Repite la contraseña',
                          hintStyle: TextStyle(color: Colors.grey[400]),
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
                        validator: _validarPasswordConfirmar,
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 1.8),

                    // Requisitos de la contraseña
                    Container(
                      padding: EdgeInsets.all(padding * 1.2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(borderRadius),
                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(spacing * 0.7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.checklist,
                                  size: context.responsiveIconSize(20),
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                              SizedBox(width: spacing),
                              Text(
                                'Requisitos de seguridad:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: context.responsiveFontSize(15),
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: spacing * 1.2),
                          _RequisitoItem(
                            texto: 'Mínimo 8 caracteres',
                            cumple: _passwordNuevaController.text.length >= 8,
                            context: context,
                          ),
                          _RequisitoItem(
                            texto: 'Al menos una mayúscula (A-Z)',
                            cumple: RegExp(r'[A-Z]').hasMatch(_passwordNuevaController.text),
                            context: context,
                          ),
                          _RequisitoItem(
                            texto: 'Al menos una minúscula (a-z)',
                            cumple: RegExp(r'[a-z]').hasMatch(_passwordNuevaController.text),
                            context: context,
                          ),
                          _RequisitoItem(
                            texto: 'Al menos un número (0-9)',
                            cumple: RegExp(r'[0-9]').hasMatch(_passwordNuevaController.text),
                            context: context,
                          ),
                          _RequisitoItem(
                            texto: 'Al menos un carácter especial (!@#\$%)',
                            cumple: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordNuevaController.text),
                            context: context,
                          ),
                        ],
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 2),

                    // Botón de cambiar contraseña
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
                    ResponsiveHelper.verticalSpace(context, multiplier: 1.2),

                    // Advertencia
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange[50]!, Colors.orange[100]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(borderRadius * 0.75),
                        border: Border.all(color: Colors.orange[300]!, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange[700],
                            size: context.responsiveIconSize(24),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: Text(
                              'No podrás acceder al sistema sin cambiar tu contraseña',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(13),
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ResponsiveHelper.verticalSpace(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para mostrar requisitos - RESPONSIVE
class _RequisitoItem extends StatelessWidget {
  final String texto;
  final bool cumple;
  final BuildContext context;

  const _RequisitoItem({
    required this.texto,
    required this.cumple,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = context.responsiveSpacing;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing * 0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: cumple ? const Color(0xFF388E3C).withOpacity(0.1) : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              cumple ? Icons.check_circle : Icons.radio_button_unchecked,
              size: context.responsiveIconSize(20),
              color: cumple ? const Color(0xFF388E3C) : Colors.grey[400],
            ),
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                fontSize: context.responsiveFontSize(13.5),
                color: cumple ? const Color(0xFF388E3C) : Colors.grey[600],
                fontWeight: cumple ? FontWeight.w600 : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}