import 'package:flutter/material.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';
import '../config/responsive_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configurar animación
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
    
    // Verificar autenticación
    _verificarAutenticacion();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verificarAutenticacion() async {
    // Esperar al menos 2 segundos para mostrar el splash
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Verificar si hay sesión activa
    final usuario = await AuthService.getUsuarioActual();
    
    if (!mounted) return;
    
    if (usuario != null) {
      // Usuario logueado, ir al home
      AppRoutes.navigateToHome(context, usuario);
    } else {
      // No hay sesión, ir a la pantalla de bienvenida
      AppRoutes.navigateToBienvenida(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ResponsiveHelper.centerConstrainedBox(
          context: context,
          maxWidth: 600,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: context.responsivePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo - responsivo
                Container(
                  padding: EdgeInsets.all(context.isMobile ? 20 : 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.school,
                    size: context.responsiveIconSize(context.isMobile ? 70 : 80),
                    color: const Color(0xFF1565C0),
                  ),
                ),
                SizedBox(height: context.isMobile ? 24 : 32),
                
                // Título - responsivo
                Text(
                  'ESFOT Tutorías',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(context.isMobile ? 32 : 36),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Subtítulo - responsivo
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile ? 30 : 40,
                  ),
                  child: Text(
                    'Escuela de Formación de Tecnólogos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(context.isMobile ? 14 : 16),
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: context.isMobile ? 50 : 60),
                
                // Indicador de carga - tamaño responsivo
                SizedBox(
                  width: context.isMobile ? 36 : 40,
                  height: context.isMobile ? 36 : 40,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Cargando...',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}