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
          activeIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Docentes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_outlined),
          activeIcon: Icon(Icons.school),
          label: 'Estudiantes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else if (_usuario.esDocente) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: 'Materias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule_outlined),
          activeIcon: Icon(Icons.schedule),
          label: 'Horarios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Disponibilidad',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
  }

  Widget _buildDashboardAdmin() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Gestión del Sistema'),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Gestión de Docentes',
                    subtitle: 'Administrar docentes del sistema',
                    icon: Icons.people,
                    color: const Color(0xFF1565C0),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: 'Gestión de Estudiantes',
                    subtitle: 'Administrar estudiantes',
                    icon: Icons.school,
                    color: const Color(0xFF2E7D32),
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: 'Gestión de Materias',
                    subtitle: 'Administrar catálogo de materias',
                    icon: Icons.menu_book,
                    color: const Color(0xFF7B1FA2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminMaterias.GestionMateriasScreen(usuario: _usuario),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Reportes y Análisis'),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Reportes Generales',
                    subtitle: 'Ver estadísticas del sistema',
                    icon: Icons.analytics,
                    color: const Color(0xFFE65100),
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
                    icon: Icons.history,
                    color: const Color(0xFF00695C),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HistorialTutoriasAdminScreen(usuario: _usuario),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Configuración'),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Mis Materias',
                    subtitle: 'Gestionar materias asignadas',
                    icon: Icons.book,
                    color: const Color(0xFFE65100),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: 'Horarios de Atención',
                    subtitle: 'Configurar disponibilidad',
                    icon: Icons.schedule,
                    color: const Color(0xFF7B1FA2),
                    onTap: () => setState(() => _selectedIndex = 2),
                  ),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Tutorías'),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Solicitudes Pendientes',
                    subtitle: 'Gestionar tutorías solicitadas',
                    icon: Icons.notifications_active,
                    color: const Color(0xFFC62828),
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
                    icon: Icons.analytics,
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportesScreen(usuario: _usuario),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Mis Tutorías'),
                  const SizedBox(height: 16),
                  
                  _buildActionCard(
                    title: 'Agendar Tutoría',
                    subtitle: 'Solicitar nueva tutoría con un docente',
                    icon: Icons.add_circle,
                    color: const Color(0xFF2E7D32),
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildActionCard(
                    title: 'Mis Tutorías',
                    subtitle: 'Ver tutorías agendadas',
                    icon: Icons.event_note,
                    color: const Color(0xFF1565C0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MisTutoriasScreen(usuario: _usuario),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
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
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1565C0),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _usuario.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
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
                          fontWeight: FontWeight.w600,
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
    if (_usuario.esAdministrador) return Icons.admin_panel_settings;
    if (_usuario.esDocente) return Icons.school;
    return Icons.person;
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 18,
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
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.logout, color: Colors.red[700], size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Cerrar sesión',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          '¿Está seguro de que desea cerrar sesión?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text('Cerrar sesión'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: _buildNavItems(),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: Colors.white,
        elevation: 8,
      ),
    );
  }
}