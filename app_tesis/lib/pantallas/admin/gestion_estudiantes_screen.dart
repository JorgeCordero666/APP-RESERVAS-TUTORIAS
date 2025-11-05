// lib/pantallas/admin/gestion_estudiantes_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/estudiante_service.dart';
import 'editar_estudiante_screen.dart';
import 'detalle_estudiante_screen.dart';

class GestionEstudiantesScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionEstudiantesScreen({super.key, required this.usuario});

  @override
  State<GestionEstudiantesScreen> createState() => _GestionEstudiantesScreenState();
}

class _GestionEstudiantesScreenState extends State<GestionEstudiantesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _estudiantes = [];
  List<Map<String, dynamic>> _estudiantesFiltrados = [];
  final _searchController = TextEditingController();
  String _filtroEstado = 'Todos'; // 'Todos', 'Activos', 'Inactivos'

  @override
  void initState() {
    super.initState();
    _cargarEstudiantes();
    _searchController.addListener(_filtrarEstudiantes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarEstudiantes() async {
    setState(() => _isLoading = true);

    try {
      final estudiantes = await EstudianteService.listarEstudiantes();
      setState(() {
        _estudiantes = estudiantes;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar estudiantes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filtrarEstudiantes() {
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _estudiantesFiltrados = _estudiantes.where((estudiante) {
        final nombreMatch = (estudiante['nombreEstudiante'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query);
        final emailMatch = (estudiante['emailEstudiante'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query);
        
        final cumpleBusqueda = query.isEmpty || nombreMatch || emailMatch;
        
        final estadoEstudiante = estudiante['status'] ?? true;
        final cumpleEstado = _filtroEstado == 'Todos' ||
            (_filtroEstado == 'Activos' && estadoEstudiante) ||
            (_filtroEstado == 'Inactivos' && !estadoEstudiante);
        
        return cumpleBusqueda && cumpleEstado;
      }).toList();
    });
  }

  void _cambiarFiltroEstado(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
      _aplicarFiltros();
    });
  }

  Future<void> _deshabilitarEstudiante(Map<String, dynamic> estudiante) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Deshabilitar estudiante?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de deshabilitar a ${estudiante['nombreEstudiante']}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ El estudiante no podrá acceder al sistema después de esta acción.',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
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
            child: const Text('Deshabilitar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    final resultado = await EstudianteService.eliminarEstudiante(
      id: estudiante['_id'],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Estudiante deshabilitado exitosamente');
      _cargarEstudiantes();
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Estudiantes'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEstudiantes,
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarEstudiantes,
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Filtros por estado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    isSelected: _filtroEstado == 'Todos',
                    onTap: () => _cambiarFiltroEstado('Todos'),
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Activos',
                    isSelected: _filtroEstado == 'Activos',
                    onTap: () => _cambiarFiltroEstado('Activos'),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Inactivos',
                    isSelected: _filtroEstado == 'Inactivos',
                    onTap: () => _cambiarFiltroEstado('Inactivos'),
                    color: Colors.grey,
                  ),
                ],
              ),
            ),

            // Lista de estudiantes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _estudiantesFiltrados.isEmpty
                      ? _buildEstadoVacio()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _estudiantesFiltrados.length,
                          itemBuilder: (context, index) {
                            final estudiante = _estudiantesFiltrados[index];
                            return _EstudianteCard(
                              estudiante: estudiante,
                              onDesabilitar: () =>
                                  _deshabilitarEstudiante(estudiante),
                              onVerDetalle: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleEstudianteScreen(
                                      estudianteId: estudiante['_id'],
                                    ),
                                  ),
                                );
                              },
                              onEditar: () async {
                                final resultado = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarEstudianteScreen(
                                      estudiante: estudiante,
                                    ),
                                  ),
                                );

                                if (resultado == true && mounted) {
                                  _cargarEstudiantes();
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    if (_estudiantes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay estudiantes registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron estudiantes',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro criterio de búsqueda',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
  }
}

// Widget para la tarjeta de estudiante
class _EstudianteCard extends StatelessWidget {
  final Map<String, dynamic> estudiante;
  final VoidCallback onDesabilitar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _EstudianteCard({
    required this.estudiante,
    required this.onDesabilitar,
    required this.onVerDetalle,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final estadoEstudiante = estudiante['status'] ?? true;
    final fotoUrl = estudiante['fotoPerfil'] ??
        'https://cdn-icons-png.flaticon.com/512/4715/4715329.png';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(fotoUrl),
          backgroundColor: Colors.grey[300],
        ),
        title: Text(
          estudiante['nombreEstudiante'] ?? 'Sin nombre',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              estudiante['emailEstudiante'] ?? 'Sin email',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                estadoEstudiante ? 'Activo' : 'Inactivo',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: estadoEstudiante ? Colors.green : Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'detalle':
                onVerDetalle();
                break;
              case 'editar':
                onEditar();
                break;
              case 'deshabilitar':
                onDesabilitar();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detalle',
              child: Row(
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 12),
                  Text('Ver detalle'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 12),
                  Text('Editar'),
                ],
              ),
            ),
            if (estadoEstudiante)
              const PopupMenuItem(
                value: 'deshabilitar',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Deshabilitar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget para los chips de filtro
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FiltroChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? const Color(0xFF1565C0);

    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        backgroundColor: isSelected ? chipColor : chipColor.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}