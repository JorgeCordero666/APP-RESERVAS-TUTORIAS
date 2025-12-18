import 'package:flutter/material.dart';
import '../../servicios/auth_service.dart';
import '../../config/responsive_helper.dart';

class RecuperarPasswordScreen extends StatefulWidget {
  const RecuperarPasswordScreen({super.key});

  @override
  State<RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<RecuperarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _recuperarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final resultado = await AuthService.recuperarPassword(
      email: _emailController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado?['error'] != null) {
      _mostrarSnackBar(resultado!['error'], isError: true);
    } else if (resultado?['msg'] != null) {
      _mostrarSnackBar(resultado!['msg'], isError: false);
      _emailController.clear();

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    }
  }

  void _mostrarSnackBar(String mensaje, {required bool isError}) {
    final color = isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C);
    final icon = isError ? Icons.error_outline : Icons.check_circle_outline;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        duration: const Duration(seconds: 4),
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
          'Recuperar Contraseña',
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ResponsiveHelper.verticalSpace(context),
                  
                  // Icono header
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
                  
                  // Título y descripción
                  Text(
                    '¿Olvidaste tu Contraseña?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(26),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1565C0),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: spacing),
                  Text(
                    'No te preocupes. Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14.5),
                      color: Colors.grey[600],
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 2.5),
                  
                  // Campo email
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
                        labelText: 'Correo Electrónico',
                        labelStyle: TextStyle(
                          color: Colors.grey[700],
                          fontSize: context.responsiveFontSize(14),
                        ),
                        hintText: 'ejemplo@epn.edu.ec',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          size: context.responsiveIconSize(22),
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
                          return 'Por favor ingresa tu correo';
                        }
                        if (!value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 1.5),
                  
                  // Info box
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
                            Icons.mail_outline,
                            color: Colors.blue[700],
                            size: context.responsiveIconSize(24),
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Text(
                            'Recibirás un correo con un enlace que abrirá automáticamente la aplicación.',
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
                  ResponsiveHelper.verticalSpace(context, multiplier: 2.5),
                  
                  // Botón enviar
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
                      onPressed: _isLoading ? null : _recuperarPassword,
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
                              'Enviar Enlace',
                              style: TextStyle(
                                fontSize: context.responsiveFontSize(16),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 2),
                  
                  // Separador
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: spacing),
                        child: Text(
                          '¿No recibiste el enlace?',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: context.responsiveFontSize(13),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    ],
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 1.5),
                  
                  // Botón código manual
                  Container(
                    height: buttonHeight * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
                      color: Colors.white,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/ingresar-codigo'),
                      icon: Icon(Icons.vpn_key, size: context.responsiveIconSize(20)),
                      label: Text(
                        'Ingresar código manualmente',
                        style: TextStyle(fontSize: context.responsiveFontSize(15)),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1565C0),
                        side: BorderSide.none,
                        padding: EdgeInsets.symmetric(vertical: spacing),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                        ),
                      ),
                    ),
                  ),
                  ResponsiveHelper.verticalSpace(context, multiplier: 1.2),
                  
                  // Volver al login
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      padding: EdgeInsets.symmetric(vertical: spacing),
                    ),
                    child: Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: context.responsiveFontSize(14),
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