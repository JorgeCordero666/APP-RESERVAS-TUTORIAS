// lib/pantallas/home_screen.dart - DISEÑO PROFESIONAL UNIVERSITARIO RESPONSIVE
import 'package:app_tesis/pantallas/docente/solicitudes_tutorias_screen.dart';
import 'package:app_tesis/pantallas/estudiante/mis_tutorias_screen.dart';
import 'package:flutter/material.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';
import '../config/responsive_helper.dart';
import 'admin/gestion_usuarios_screen.dart';
import 'admin/gestion_estudiantes_screen.dart';
import 'admin/gestion_materias_screen.dart' as AdminMaterias;
import 'admin/reportes_admin_screen.dart';
import 'admin/historial_tutorias_admin_screen.dart';
import 'perfil/perfil_screen.dart';
import 'docente/gestion_materias_screen.dart' as DocenteMaterias;
import 'docente/gestion_horarios_screen.dart';
import 'docente/reportes_screen.dart';
import 'estudiante/ver_disponibilidad_docentes_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
    _cargarUsuarioActualizado();
  }

  Future<void> _cargarUsuarioActualizado() async {
    final usuarioActualizado = await AuthService.getUsuarioActual();
    if (usuarioActualizado != null && mounted) {
      setState(() {
        _usuario = usuarioActualizado;
      });
      print('✅ Usuario actualizado en HomeScreen');
      print('   Nombre: ${_usuario.nombre}');
      print('   Rol: ${_usuario.rol}');
      if (_usuario.esDocente) {
        print('   Asignaturas: ${_usuario.asignaturas?.join(", ") ?? "ninguna"}');
      }
    }
  }

  List<Widget> _buildScreens() {
    if (_usuario.esAdministrador) {
      return [
        _buildDashboardAdmin(),
        GestionUsuariosScreen(usuario: _usuario),
        GestionEstudiantesScreen(usuario: _usuario),
        PerfilScreen(usuario: _usuario),
      ];
    } else if (_usuario.esDocente) {
      return [
        _buildDashboardDocente(),
        DocenteMaterias.GestionMateriasScreen(usuario: _usuario),
        GestionHorariosScreen(usuario: _usuario),
        PerfilScreen(usuario: _usuario),
      ];
    } else {
      return [
        _buildDashboardEstudiante(),
        VerDisponibilidadDocentesScreen(usuario: _usuario),
        PerfilScreen(usuario: _usuario),
      ];
    }
  }

  List<BottomNavigationBarItem> _buildNavItems() {
    final iconSize = context.isMobile ? 24.0 : 28.0;
    
    if (_usuario.esAdministrador) {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, size: iconSize),
          activeIcon: Icon(Icons.dashboard_rounded, size: iconSize),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded, size: iconSize),
          activeIcon: Icon(Icons.people_rounded, size: iconSize),
          label: 'Docentes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined, size: iconSize),
          activeIcon: Icon(Icons.school_rounded, size: iconSize),
          label: 'Estudiantes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded, size: iconSize),
          activeIcon: Icon(Icons.person_rounded, size: iconSize),
          label: 'Perfil',
        ),
      ];
    } else if (_usuario.esDocente) {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, size: iconSize),
          activeIcon: Icon(Icons.dashboard_rounded, size: iconSize),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined, size: iconSize),
          activeIcon: Icon(Icons.book_rounded, size: iconSize),
          label: 'Materias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule_outlined, size: iconSize),
          activeIcon: Icon(Icons.schedule, size: iconSize),
          label: 'Horarios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded, size: iconSize),
          activeIcon: Icon(Icons.person_rounded, size: iconSize),
          label: 'Perfil',
        ),
      ];
    } else {
      return [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined, size: iconSize),
          activeIcon: Icon(Icons.dashboard_rounded, size: iconSize),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined, size: iconSize),
          activeIcon: Icon(Icons.calendar_today_rounded, size: iconSize),
          label: 'Disponibilidad',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded, size: iconSize),
          activeIcon: Icon(Icons.person_rounded, size: iconSize),
          label: 'Perfil',
        ),
      ];
    }
  }

  Widget _buildDashboardAdmin() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar('Panel Administrativo'),
          
          SliverToBoxAdapter(
            child: ResponsiveHelper.centerConstrainedBox(
              context: context,
              child: Padding(
                padding: EdgeInsets.all(context.responsivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: context.responsiveSpacing * 2),
                    
                    _buildSectionTitle('Gestión del Sistema', Icons.settings_rounded),
                    SizedBox(height: context.responsiveSpacing),
                    
                    _buildActionCard(
                      title: 'Gestión de Docentes',
                      subtitle: 'Administrar docentes del sistema',
                      icon: Icons.people_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.75),
                    
                    _buildActionCard(
                      title: 'Gestión de Estudiantes',
                      subtitle: 'Administrar estudiantes',
                      icon: Icons.school_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      ),
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.75),
                    
                    _buildActionCard(
                      title: 'Gestión de Materias',
                      subtitle: 'Administrar catálogo de materias',
                      icon: Icons.menu_book_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF8E24AA)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminMaterias.GestionMateriasScreen(usuario: _usuario),
                          ),
                        );
                      },
                    ),
                    
                    SizedBox(height: context.responsiveSpacing * 2),
                    _buildSectionTitle('Reportes y Análisis', Icons.analytics_rounded),
                    SizedBox(height: context.responsiveSpacing),
                    
                    _buildActionCard(
                      title: 'Reportes Generales',
                      subtitle: 'Ver estadísticas del sistema',
                      icon: Icons.bar_chart_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportesAdminScreen(usuario: _usuario),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.75),
                    
                    _buildActionCard(
                      title: 'Historial de Tutorías',
                      subtitle: 'Ver todas las tutorías del sistema',
                      icon: Icons.history_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00695C), Color(0xFF00897B)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistorialTutoriasAdminScreen(usuario: _usuario),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing * 1.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDashboardDocente() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar('Panel Docente'),
          
          SliverToBoxAdapter(
            child: ResponsiveHelper.centerConstrainedBox(
              context: context,
              child: Padding(
                padding: EdgeInsets.all(context.responsivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: context.responsiveSpacing * 2),
                    
                    _buildSectionTitle('Configuración', Icons.tune_rounded),
                    SizedBox(height: context.responsiveSpacing),
                    
                    _buildActionCard(
                      title: 'Mis Materias',
                      subtitle: 'Gestionar materias asignadas',
                      icon: Icons.book_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                      ),
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.75),
                    
                    _buildActionCard(
                      title: 'Horarios de Atención',
                      subtitle: 'Configurar disponibilidad',
                      icon: Icons.schedule,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7B1FA2), Color(0xFF8E24AA)],
                      ),
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                    
                    SizedBox(height: context.responsiveSpacing * 2),
                    _buildSectionTitle('Tutorías', Icons.event_note_rounded),
                    SizedBox(height: context.responsiveSpacing),
                    
                    _buildActionCard(
                      title: 'Solicitudes Pendientes',
                      subtitle: 'Gestionar tutorías solicitadas',
                      icon: Icons.notifications_active_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC62828), Color(0xFFD32F2F)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SolicitudesTutoriasScreen(usuario: _usuario),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.75),
                    
                    _buildActionCard(
                      title: 'Reportes de Tutorías',
                      subtitle: 'Ver estadísticas por materia',
                      icon: Icons.analytics_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReportesScreen(usuario: _usuario),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing * 1.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardEstudiante() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar('Panel Estudiante'),
          
          SliverToBoxAdapter(
            child: ResponsiveHelper.centerConstrainedBox(
              context: context,
              child: Padding(
                padding: EdgeInsets.all(context.responsivePadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: context.responsiveSpacing * 2),
                    
                    _buildSectionTitle('Mis Tutorías', Icons.school_rounded),
                    SizedBox(height: context.responsiveSpacing),
                    
                    _buildActionCard(
                      title: 'Agendar Tutoría',
                      subtitle: 'Solicitar nueva tutoría con un docente',
                      icon: Icons.add_circle_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      ),
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    SizedBox(height: context.responsiveSpacing * 0.75),
                    
                    _buildActionCard(
                      title: 'Mis Tutorías',
                      subtitle: 'Ver tutorías agendadas',
                      icon: Icons.event_note_rounded,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MisTutoriasScreen(usuario: _usuario),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: context.responsiveSpacing * 1.5),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String title) {
    final expandedHeight = context.isMobile ? 120.0 : 140.0;
    
    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1565C0),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(
          left: context.responsivePadding,
          bottom: 16,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: context.responsiveFontSize(context.isMobile ? 20 : 22),
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
        background: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF42A5F5),
                    Color(0xFF1E88E5),
                    Color(0xFF1565C0),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decoración con círculos - ajustados para responsive
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: context.isMobile ? 100 : 120,
                height: context.isMobile ? 100 : 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: Container(
                width: context.isMobile ? 80 : 100,
                height: context.isMobile ? 80 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: context.responsiveIconSize(24),
              ),
              onPressed: _logout,
              tooltip: 'Cerrar sesión',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 14 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.08),
            const Color(0xFF42A5F5).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        border: Border.all(
          color: const Color(0xFF1565C0).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: context.responsiveIconSize(20),
            ),
          ),
          SizedBox(width: context.responsiveSpacing * 0.75),
          Text(
            title,
            style: TextStyle(
              fontSize: context.responsiveFontSize(context.isMobile ? 17 : 18),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E3A5F),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final avatarRadius = context.isMobile ? 35.0 : 40.0;
    
    return Container(
      padding: EdgeInsets.all(context.isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF42A5F5),
            Color(0xFF1E88E5),
            Color(0xFF1565C0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: avatarRadius,
                  backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
                  backgroundColor: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(context.isMobile ? 5 : 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: context.isMobile ? 10 : 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: context.responsiveSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: context.responsiveFontSize(context.isMobile ? 13 : 14),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _usuario.nombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: context.responsiveFontSize(context.isMobile ? 18 : 20),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile ? 12 : 14,
                    vertical: context.isMobile ? 6 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRolIcon(),
                        color: Colors.white,
                        size: context.responsiveIconSize(14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _usuario.rol,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: context.responsiveFontSize(12),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRolIcon() {
    if (_usuario.esAdministrador) return Icons.admin_panel_settings_rounded;
    if (_usuario.esDocente) return Icons.school_rounded;
    return Icons.person_rounded;
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    required VoidCallback onTap,
    String? badge,
  }) {
    final cardPadding = context.isMobile ? 16.0 : 20.0;
    final iconContainerSize = context.isMobile ? 14.0 : 16.0;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        child: Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
            border: Border.all(
              color: Colors.grey.shade100,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(iconContainerSize),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.first.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: context.responsiveIconSize(26),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: context.responsiveSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(context.isMobile ? 15 : 16),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E3A5F),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(context.isMobile ? 12 : 13),
                        color: Colors.grey[600],
                        height: 1.3,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: context.responsiveSpacing * 0.75),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: context.responsiveIconSize(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveHelper.getBorderRadius(context)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.red[400]!,
                    Colors.red[600]!,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: context.responsiveIconSize(24),
              ),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(context.isMobile ? 18 : 20),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '¿Estás seguro de que deseas cerrar sesión?',
            style: TextStyle(
              fontSize: context.responsiveFontSize(15),
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
        actionsPadding: EdgeInsets.all(context.responsivePadding),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: context.responsiveFontSize(15),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: context.responsiveFontSize(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      await AuthService.logout();
      if (mounted) {
        AppRoutes.navigateToLogin(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _buildScreens(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: _buildNavItems(),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: context.isMobile ? 11 : 12,
          unselectedFontSize: context.isMobile ? 10 : 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
    );
  }
}