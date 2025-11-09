// lib/pantallas/home_screen.dart
import 'package:flutter/material.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';
import 'admin/gestion_usuarios_screen.dart';
import 'admin/gestion_estudiantes_screen.dart';
import 'perfil/perfil_screen.dart';
import 'docente/gestion_materias_screen.dart';
import 'docente/gestion_horarios_screen.dart';
import 'estudiante/ver_disponibilidad_docentes_screen.dart';

class HomeScreen extends StatefulWidget {
  final Usuario usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        GestionMateriasScreen(usuario: _usuario),
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
          icon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Docentes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Estudiantes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else if (_usuario.esDocente) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'Materias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule),
          label: 'Horarios',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Disponibilidad',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
  }

  Widget _buildDashboardAdmin() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Administrativo'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarUsuarioActualizado,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickAccessCard(
              title: 'Gestión de Docentes',
              subtitle: 'Administrar docentes del sistema',
              icon: Icons.people,
              color: Colors.blue,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 16),
            _buildQuickAccessCard(
              title: 'Gestión de Estudiantes',
              subtitle: 'Administrar estudiantes',
              icon: Icons.school,
              color: Colors.green,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardDocente() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Docente'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarUsuarioActualizado,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickAccessCard(
              title: 'Mis Materias',
              subtitle: 'Gestionar materias asignadas',
              icon: Icons.book,
              color: Colors.orange,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
            const SizedBox(height: 16),
            _buildQuickAccessCard(
              title: 'Horarios de Atención',
              subtitle: 'Configurar disponibilidad',
              icon: Icons.schedule,
              color: Colors.purple,
              onTap: () => setState(() => _selectedIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardEstudiante() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Estudiante'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarUsuarioActualizado,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickAccessCard(
              title: 'Ver Disponibilidad',
              subtitle: 'Consultar horarios de docentes',
              icon: Icons.calendar_today,
              color: Colors.teal,
              onTap: () => setState(() => _selectedIndex = 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '¡Bienvenido!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _usuario.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _usuario.rol,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
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
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 20,
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
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}