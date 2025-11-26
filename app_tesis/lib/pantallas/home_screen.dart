// lib/pantallas/home_screen.dart - DISEÑO PROFESIONAL UNIVERSITARIO
import 'package:app_tesis/pantallas/docente/solicitudes_tutorias_screen.dart';
import 'package:app_tesis/pantallas/estudiante/mis_tutorias_screen.dart';
import 'package:flutter/material.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';
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
    if (_usuario.esAdministrador) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline_rounded),
          activeIcon: Icon(Icons.people_rounded),
          label: 'Docentes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school_rounded),
          label: 'Estudiantes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ];
    } else if (_usuario.esDocente) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book_rounded),
          label: 'Materias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule_outlined),
          activeIcon: Icon(Icons.schedule),
          label: 'Horarios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today_rounded),
          label: 'Disponibilidad',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          activeIcon: Icon(Icons.person_rounded),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 28),
                  
                  _buildSectionTitle('Gestión del Sistema', Icons.settings_rounded),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Gestión de Docentes',
                    subtitle: 'Administrar docentes del sistema',
                    icon: Icons.people_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                    ),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: 'Gestión de Estudiantes',
                    subtitle: 'Administrar estudiantes',
                    icon: Icons.school_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  const SizedBox(height: 12),
                  
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
                  
                  const SizedBox(height: 28),
                  _buildSectionTitle('Reportes y Análisis', Icons.analytics_rounded),
                  const SizedBox(height: 16),
                  
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
                  const SizedBox(height: 12),
                  
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
                  const SizedBox(height: 24),
                ],
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 28),
                  
                  _buildSectionTitle('Configuración', Icons.tune_rounded),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Mis Materias',
                    subtitle: 'Gestionar materias asignadas',
                    icon: Icons.book_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                    ),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: 'Horarios de Atención',
                    subtitle: 'Configurar disponibilidad',
                    icon: Icons.schedule,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7B1FA2), Color(0xFF8E24AA)],
                    ),
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  
                  const SizedBox(height: 28),
                  _buildSectionTitle('Tutorías', Icons.event_note_rounded),
                  const SizedBox(height: 16),
                  
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
                  const SizedBox(height: 12),
                  
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
                  const SizedBox(height: 24),
                ],
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 28),
                  
                  _buildSectionTitle('Mis Tutorías', Icons.school_rounded),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Agendar Tutoría',
                    subtitle: 'Solicitar nueva tutoría con un docente',
                    icon: Icons.add_circle_rounded,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  
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
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(String title) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1565C0),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
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
            // Decoración con círculos
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 120,
                height: 120,
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
                width: 100,
                height: 100,
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
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.08),
            const Color(0xFF42A5F5).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E3A5F),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
        borderRadius: BorderRadius.circular(24),
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
                  radius: 40,
                  backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
                  backgroundColor: Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _usuario.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
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
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _usuario.rol,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(16),
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
                      size: 28,
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
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
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
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[400],
                  size: 16,
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
          borderRadius: BorderRadius.circular(24),
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
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 20,
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
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(20),
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
                fontSize: 15,
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
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
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
          selectedFontSize: 12,
          unselectedFontSize: 11,
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