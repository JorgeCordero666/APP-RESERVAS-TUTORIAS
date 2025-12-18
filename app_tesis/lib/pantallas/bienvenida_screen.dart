import 'package:flutter/material.dart';
import '../config/routes.dart';
import '../config/responsive_helper.dart';

class BienvenidaScreen extends StatelessWidget {
  const BienvenidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1976D2),
              Color(0xFF1565C0),
              Color(0xFF0D47A1),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decoración de fondo con círculos - responsiva
              Positioned(
                top: -50,
                right: -50,
                child: Container(
                  width: context.isMobile ? 150 : 200,
                  height: context.isMobile ? 150 : 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: context.isMobile ? 200 : 250,
                  height: context.isMobile ? 200 : 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              if (!context.isMobile)
                Positioned(
                  top: 200,
                  left: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.03),
                    ),
                  ),
                ),
              
              // Contenido principal - scrollable
              SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                  ),
                  child: ResponsiveHelper.centerConstrainedBox(
                    context: context,
                    maxWidth: 600,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsivePadding,
                        vertical: context.responsivePadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isSmallScreen ? 20 : 40),
                          
                          // Logo con animación implícita
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.all(context.isMobile ? 24 : 32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, -5),
                                  ),
                                ],
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF1565C0).withOpacity(0.1),
                                      const Color(0xFF1565C0).withOpacity(0.05),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.school_rounded,
                                  size: context.responsiveIconSize(80),
                                  color: const Color(0xFF1565C0),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 32 : 48),
                          
                          // Título con efecto de aparición
                          TweenAnimationBuilder(
                            duration: const Duration(milliseconds: 600),
                            tween: Tween<double>(begin: 0, end: 1),
                            builder: (context, double value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Colors.white.withOpacity(0.95),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'ESFOT Tutorías',
                                    style: TextStyle(
                                      fontSize: context.responsiveFontSize(context.isMobile ? 36 : 42),
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                      shadows: const [
                                        Shadow(
                                          color: Colors.black26,
                                          offset: Offset(0, 4),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                // Línea decorativa
                                Container(
                                  width: 80,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white,
                                        Colors.white.withOpacity(0.3),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 20),
                          
                          // Subtítulo
                          Text(
                            'Escuela de Formación de Tecnólogos',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(context.isMobile ? 14 : 16),
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 40),
                          
                          // Descripción mejorada
                          Container(
                            padding: EdgeInsets.all(context.isMobile ? 20 : 24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildFeatureIcon(Icons.calendar_today_rounded, context),
                                    const SizedBox(width: 20),
                                    _buildFeatureIcon(Icons.people_rounded, context),
                                    const SizedBox(width: 20),
                                    _buildFeatureIcon(Icons.check_circle_rounded, context),
                                  ],
                                ),
                                SizedBox(height: isSmallScreen ? 16 : 20),
                                Text(
                                  'Sistema de gestión de tutorías académicas para la ESFOT',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(context.isMobile ? 15 : 16),
                                    color: Colors.white,
                                    height: 1.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 12),
                                Text(
                                  'Agenda, gestiona y realiza seguimiento de tus tutorías de manera eficiente',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(context.isMobile ? 13 : 14),
                                    color: Colors.white.withOpacity(0.9),
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: isSmallScreen ? 32 : 48),
                          
                          // Botones de acción
                          Column(
                            children: [
                              // Botón Iniciar Sesión
                              SizedBox(
                                width: double.infinity,
                                height: ResponsiveHelper.getButtonHeight(context),
                                child: ElevatedButton(
                                  onPressed: () {
                                    AppRoutes.push(context, AppRoutes.login);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1565C0),
                                    elevation: 12,
                                    shadowColor: Colors.black.withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Iniciar Sesión',
                                        style: TextStyle(
                                          fontSize: context.responsiveFontSize(context.isMobile ? 16 : 18),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1565C0).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          size: context.responsiveIconSize(20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 12 : 16),
                              
                              // Botón Registrarse
                              SizedBox(
                                width: double.infinity,
                                height: ResponsiveHelper.getButtonHeight(context),
                                child: OutlinedButton(
                                  onPressed: () {
                                    AppRoutes.navigateToRegistro(context);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white, width: 2.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
                                    ),
                                    backgroundColor: Colors.white.withOpacity(0.1),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Registrarse',
                                        style: TextStyle(
                                          fontSize: context.responsiveFontSize(context.isMobile ? 16 : 18),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(
                                          Icons.person_add_rounded,
                                          size: context.responsiveIconSize(20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          
                          // Versión con diseño mejorado
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Versión 1.0.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                        ],
                      ),
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

  Widget _buildFeatureIcon(IconData icon, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: context.responsiveIconSize(22),
      ),
    );
  }
}