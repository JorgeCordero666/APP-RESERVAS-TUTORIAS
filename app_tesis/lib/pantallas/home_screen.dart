// lib/pantallas/home_screen.dart - VERSIÓN CORREGIDA COMPLETA
import 'package:flutter/material.dart';
import '../modelos/usuario.dart';
import '../servicios/auth_service.dart';
import '../config/routes.dart';
import 'perfil/editar_perfil_screen.dart';
import 'auth/cambiar_password_screen.dart';
import 'admin/gestion_usuarios_screen.dart';
import 'admin/gestion_estudiantes_screen.dart';
import 'docente/gestion_materias_screen.dart';
import 'docente/gestion_horarios_screen.dart';
import 'estudiante/ver_disponibilidad_docentes_screen.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

// =====================================================
// ✅ SERVICIO DE ESTADÍSTICAS ACTUALIZADO
// =====================================================

class EstadisticasService {
  static Future<Map<String, int>> obtenerEstadisticas() async {
    try {
      final token = await AuthService.getToken();

      if (token == null) {
        return {
          'docentes': 0,
          'docentesActivos': 0,
          'estudiantes': 0,
          'estudiantesActivos': 0,
          'tutorias': 0,
          'tutoriasMes': 0,
        };
      }

      // ✅ Obtener docentes
      final docentesResponse = await http.get(
        Uri.parse(ApiConfig.listarDocentes),
        headers: ApiConfig.getHeaders(token: token),
      );

      int totalDocentes = 0;
      int docentesActivos = 0;

      if (docentesResponse.statusCode == 200) {
        final data = jsonDecode(docentesResponse.body);
        final docentes = data['docentes'] as List? ?? [];
        totalDocentes = docentes.length;
        docentesActivos =
            docentes.where((d) => d['estadoDocente'] == true).length;
      }

      // ✅ Obtener estudiantes
      final estudiantesResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes'),
        headers: ApiConfig.getHeaders(token: token),
      );

      int totalEstudiantes = 0;
      int estudiantesActivos = 0;

      if (estudiantesResponse.statusCode == 200) {
        final data = jsonDecode(estudiantesResponse.body);
        final estudiantes = data['estudiantes'] as List? ?? [];
        totalEstudiantes = estudiantes.length;
        estudiantesActivos =
            estudiantes.where((e) => e['status'] == true).length;
      }

      // ✅ Obtener tutorías (cuando el endpoint esté listo)
      int totalTutorias = 0;
      int tutoriasMes = 0;

      // TODO: Descomentar cuando el endpoint de tutorías esté disponible
      /*
      final tutoriasResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/tutorias/estadisticas'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (tutoriasResponse.statusCode == 200) {
        final data = jsonDecode(tutoriasResponse.body);
        totalTutorias = data['total'] ?? 0;
        tutoriasMes = data['mes_actual'] ?? 0;
      }
      */

      return {
        'docentes': totalDocentes,
        'docentesActivos': docentesActivos,
        'estudiantes': totalEstudiantes,
        'estudiantesActivos': estudiantesActivos,
        'tutorias': totalTutorias,
        'tutoriasMes': tutoriasMes,
      };
    } catch (e) {
      print('Error obteniendo estadísticas: $e');
      return {
        'docentes': 0,
        'docentesActivos': 0,
        'estudiantes': 0,
        'estudiantesActivos': 0,
        'tutorias': 0,
        'tutoriasMes': 0,
      };
    }
  }
}

// =====================================================
// ✅ HOME SCREEN PRINCIPAL
// =====================================================

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
  }

  void _onUserUpdated(Usuario usuarioActualizado) {
    setState(() {
      _usuario = usuarioActualizado;
    });
  }

  List<Widget> _getScreens() {
    switch (_usuario.rol) {
      case 'Administrador':
        return [
          _DashboardAdministrador(usuario: _usuario),
          _PlaceholderScreen(titulo: 'Reportes'),
          _PerfilScreen(usuario: _usuario, onUserUpdated: _onUserUpdated),
        ];
      case 'Docente':
        return [
          _DashboardDocente(usuario: _usuario),
          GestionHorariosScreen(usuario: _usuario), // ⭐ NAVEGACIÓN CORREGIDA
          _PlaceholderScreen(titulo: 'Mis Tutorías'),
          _PerfilScreen(usuario: _usuario, onUserUpdated: _onUserUpdated),
        ];
      default:
        return [
          _DashboardEstudiante(usuario: _usuario),
          _PlaceholderScreen(titulo: 'Docentes Disponibles'),
          _PlaceholderScreen(titulo: 'Mis Citas'),
          _PerfilScreen(usuario: _usuario, onUserUpdated: _onUserUpdated),
        ];
    }
  }

  List<BottomNavigationBarItem> _getNavItems() {
    switch (_usuario.rol) {
      case 'Administrador':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ];
      case 'Docente':
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Horarios'), // ⭐ CORREGIDO
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Tutorías'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ];
      default:
        return const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Docentes'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Mis Citas'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1565C0),
        items: _getNavItems(),
      ),
    );
  }
}

// =====================================================
// ✅ DASHBOARD PARA ADMINISTRADORES — ACTUALIZADO COMPLETO
// =====================================================

class _DashboardAdministrador extends StatefulWidget {
  final Usuario usuario;

  const _DashboardAdministrador({required this.usuario});

  @override
  State<_DashboardAdministrador> createState() => _DashboardAdministradorState();
}

class _DashboardAdministradorState extends State<_DashboardAdministrador> {
  Map<String, int> _estadisticas = {
    'docentes': 0,
    'docentesActivos': 0,
    'estudiantes': 0,
    'estudiantesActivos': 0,
    'tutorias': 0,
    'tutoriasMes': 0,
  };

  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    setState(() => _cargando = true);

    final stats = await EstadisticasService.obtenerEstadisticas();

    setState(() {
      _estadisticas = stats;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Calcular total de usuarios
    final totalUsuarios = _estadisticas['docentes']! + _estadisticas['estudiantes']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarEstadisticas),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenido, ${widget.usuario.nombre}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Panel de Administración - ESFOT Tutorías',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ✅ Estadísticas
              if (_cargando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _StatCard(
                      title: 'Docentes',
                      value: '${_estadisticas['docentes']}',
                      subtitle: '${_estadisticas['docentesActivos']} activos',
                      icon: Icons.people,
                      color: const Color(0xFF1565C0),
                    ),
                    _StatCard(
                      title: 'Estudiantes',
                      value: '${_estadisticas['estudiantes']}',
                      subtitle: '${_estadisticas['estudiantesActivos']} activos',
                      icon: Icons.school,
                      color: const Color(0xFF4CAF50),
                    ),
                    _StatCard(
                      title: 'Total Usuarios',
                      value: '$totalUsuarios',
                      subtitle: 'En el sistema',
                      icon: Icons.group,
                      color: const Color(0xFF9C27B0),
                    ),
                    _StatCard(
                      title: 'Tutorías',
                      value: '${_estadisticas['tutorias']}',
                      subtitle: '${_estadisticas['tutoriasMes']} este mes',
                      icon: Icons.event_note,
                      color: const Color(0xFFFF9800),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // ✅ Acciones rápidas
              const Text(
                'Acciones rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ✅ Gestión de Docentes
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GestionUsuariosScreen(usuario: widget.usuario),
                      ),
                    ).then((_) => _cargarEstadisticas());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.people,
                              size: 32, color: Color(0xFF1565C0)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gestión de Docentes',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Administrar docentes del sistema',
                                  style:
                                      TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // ⭐ NUEVO: Gestión de Estudiantes
              Card(
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            GestionEstudiantesScreen(usuario: widget.usuario),
                      ),
                    ).then((_) => _cargarEstadisticas());
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.school,
                              size: 32, color: Color(0xFF4CAF50)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gestión de Estudiantes',
                                  style: TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text('Administrar estudiantes del sistema',
                                  style:
                                      TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 18, color: Colors.grey),
                      ],
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
}

// Tarjeta auxiliar
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ✅ DASHBOARD ESTUDIANTE (SIN CAMBIOS)
// =====================================================

class _DashboardEstudiante extends StatelessWidget {
  final Usuario usuario;

  const _DashboardEstudiante({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(usuario.fotoPerfilUrl),
                      backgroundColor: Colors.grey[300],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Hola, ${usuario.nombreCompleto}!',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Estudiante',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _QuickActionCard(
                  icon: Icons.add_circle,
                  title: 'Agendar Tutoría',
                  color: Colors.blue,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.search,
                  title: 'Docentes Disponibles',
                  color: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VerDisponibilidadDocentesScreen(usuario: usuario),
                      ),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.history,
                  title: 'Historial',
                  color: Colors.orange,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
                _QuickActionCard(
                  icon: Icons.help,
                  title: 'Ayuda',
                  color: Colors.purple,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Próximas tutorías',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes tutorías próximas',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ✅ DASHBOARD DOCENTE (ACTUALIZADO)
// =====================================================

class _DashboardDocente extends StatelessWidget {
  final Usuario usuario;

  const _DashboardDocente({required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificaciones próximamente')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenido, ${usuario.nombre}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Docente',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pendientes',
                    value: '0',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Hoy',
                    value: '0',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Acciones rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GestionMateriasScreen(usuario: usuario),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1565C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.book,
                          size: 32,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis Materias',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestionar materias que imparto',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ⭐ BOTÓN DE ACCIÓN RÁPIDA PARA HORARIOS
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GestionHorariosScreen(usuario: usuario),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.schedule,
                          size: 32,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mis Horarios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Gestionar horarios de tutorías',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Solicitudes pendientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No hay solicitudes pendientes',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ✅ PERFIL SCREEN (SIN CAMBIOS)
// =====================================================

class _PerfilScreen extends StatefulWidget {
  final Usuario usuario;
  final ValueChanged<Usuario>? onUserUpdated;

  const _PerfilScreen({required this.usuario, this.onUserUpdated});

  @override
  State<_PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<_PerfilScreen> {
  late Usuario _usuario;

  @override
  void initState() {
    super.initState();
    _usuario = widget.usuario;
  }

  Future<void> _navegarAEditarPerfil() async {
    if (_usuario.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Sesión inválida. Inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final usuarioActualizado = await Navigator.push<Usuario>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilScreen(usuario: _usuario),
      ),
    );

    if (usuarioActualizado != null && mounted) {
      setState(() {
        _usuario = usuarioActualizado;
      });
      widget.onUserUpdated?.call(usuarioActualizado);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage(_usuario.fotoPerfilUrl),
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            _usuario.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Text(
            _usuario.email,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          Center(
            child: Chip(
              label: Text(_usuario.rol),
              backgroundColor: const Color(0xFF1565C0).withOpacity(0.1),
              labelStyle: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 32),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Editar Perfil'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _navegarAEditarPerfil,
          ),

          ListTile(
            leading: const Icon(Icons.lock),
            title: const Text('Cambiar Contraseña'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CambiarPasswordScreen(usuario: _usuario),
                ),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirmar == true && context.mounted) {
                await AuthService.logout();
                AppRoutes.navigateToLogin(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

// =====================================================
// ✅ WIDGETS AUXILIARES
// =====================================================

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String titulo;

  const _PlaceholderScreen({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Pantalla en construcción',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}