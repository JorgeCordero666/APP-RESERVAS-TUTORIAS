import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/estudiante_service.dart';
import '../../config/responsive_helper.dart';
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
  String _filtroEstado = 'Todos';

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
        contentPadding: EdgeInsets.all(context.responsivePadding),
        title: Text(
          '¿Deshabilitar estudiante?',
          style: TextStyle(fontSize: context.responsiveFontSize(18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de deshabilitar a ${estudiante['nombreEstudiante']}?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(14),
              ),
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              '⚠️ El estudiante no podrá acceder al sistema después de esta acción.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: context.responsiveFontSize(13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Deshabilitar',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
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
    final useGrid = context.isTablet || context.isDesktop;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gestión de Estudiantes',
          style: TextStyle(
            fontSize: context.responsiveFontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: context.responsiveIconSize(24),
            ),
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
              padding: EdgeInsets.all(context.responsivePadding),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o email',
                  hintStyle: TextStyle(
                    fontSize: context.responsiveFontSize(14),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: context.responsiveIconSize(24),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: context.responsiveIconSize(20),
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      ResponsiveHelper.getBorderRadius(context),
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: context.responsivePadding,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
            ),

            // Filtros por estado
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsivePadding,
                vertical: context.responsiveSpacing * 0.5,
              ),
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Todos',
                    isSelected: _filtroEstado == 'Todos',
                    onTap: () => _cambiarFiltroEstado('Todos'),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  _FiltroChip(
                    label: 'Activos',
                    isSelected: _filtroEstado == 'Activos',
                    onTap: () => _cambiarFiltroEstado('Activos'),
                    color: Colors.green,
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.5),
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
                      : useGrid
                          ? _buildGridView()
                          : _buildListView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(context.responsivePadding),
      itemCount: _estudiantesFiltrados.length,
      itemBuilder: (context, index) {
        final estudiante = _estudiantesFiltrados[index];
        return _EstudianteCard(
          estudiante: estudiante,
          onDesabilitar: () => _deshabilitarEstudiante(estudiante),
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
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(context.responsivePadding),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridColumns(context),
        childAspectRatio: context.isDesktop ? 1.2 : 1,
        crossAxisSpacing: context.responsiveSpacing,
        mainAxisSpacing: context.responsiveSpacing,
      ),
      itemCount: _estudiantesFiltrados.length,
      itemBuilder: (context, index) {
        final estudiante = _estudiantesFiltrados[index];
        return _EstudianteGridCard(
          estudiante: estudiante,
          onDesabilitar: () => _deshabilitarEstudiante(estudiante),
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
    );
  }

  Widget _buildEstadoVacio() {
    if (_estudiantes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: context.responsiveIconSize(80),
              color: Colors.grey[400],
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              'No hay estudiantes registrados',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: context.responsiveIconSize(80),
              color: Colors.grey[400],
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              'No se encontraron estudiantes',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: Colors.grey[600],
              ),
            ),
            ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
            Text(
              'Intenta con otro criterio de búsqueda',
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
  }
}

// Widget para la tarjeta de estudiante (ListView)
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
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.responsivePadding,
          vertical: context.responsiveSpacing * 0.5,
        ),
        leading: CircleAvatar(
          radius: context.isMobile ? 30 : 35,
          backgroundImage: NetworkImage(fotoUrl),
          backgroundColor: Colors.grey[300],
        ),
        title: Text(
          estudiante['nombreEstudiante'] ?? 'Sin nombre',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: context.responsiveFontSize(16),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: context.responsiveSpacing * 0.3),
            Text(
              estudiante['emailEstudiante'] ?? 'Sin email',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Chip(
              label: Text(
                estadoEstudiante ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(12),
                  color: Colors.white,
                ),
              ),
              backgroundColor: estadoEstudiante ? Colors.green : Colors.grey,
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveSpacing * 0.5,
                vertical: 0,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: context.responsiveIconSize(24),
          ),
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
            PopupMenuItem(
              value: 'detalle',
              child: Row(
                children: [
                  Icon(Icons.info, size: context.responsiveIconSize(20)),
                  SizedBox(width: context.responsiveSpacing),
                  Text(
                    'Ver detalle',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: context.responsiveIconSize(20)),
                  SizedBox(width: context.responsiveSpacing),
                  Text(
                    'Editar',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(14),
                    ),
                  ),
                ],
              ),
            ),
            if (estadoEstudiante)
              PopupMenuItem(
                value: 'deshabilitar',
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: context.responsiveIconSize(20),
                      color: Colors.red,
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Text(
                      'Deshabilitar',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: context.responsiveFontSize(14),
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
}

// Widget para la tarjeta de estudiante (GridView)
class _EstudianteGridCard extends StatelessWidget {
  final Map<String, dynamic> estudiante;
  final VoidCallback onDesabilitar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _EstudianteGridCard({
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
      elevation: 2,
      child: InkWell(
        onTap: onVerDetalle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing * 0.6,
                      vertical: context.responsiveSpacing * 0.2,
                    ),
                    decoration: BoxDecoration(
                      color: estadoEstudiante ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estadoEstudiante ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(10),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      size: context.responsiveIconSize(20),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'editar':
                          onEditar();
                          break;
                        case 'deshabilitar':
                          onDesabilitar();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text(
                          'Editar',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(13),
                          ),
                        ),
                      ),
                      if (estadoEstudiante)
                        PopupMenuItem(
                          value: 'deshabilitar',
                          child: Text(
                            'Deshabilitar',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: context.responsiveFontSize(13),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
              CircleAvatar(
                radius: context.isDesktop ? 45 : 40,
                backgroundImage: NetworkImage(fotoUrl),
                backgroundColor: Colors.grey[300],
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 0.8),
              Text(
                estudiante['nombreEstudiante'] ?? 'Sin nombre',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsiveFontSize(15),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 0.3),
              Text(
                estudiante['emailEstudiante'] ?? 'Sin email',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(12),
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
            fontSize: context.responsiveFontSize(12),
          ),
        ),
        backgroundColor: isSelected ? chipColor : chipColor.withOpacity(0.1),
        padding: EdgeInsets.symmetric(
          horizontal: context.responsiveSpacing,
          vertical: context.responsiveSpacing * 0.5,
        ),
      ),
    );
  }
}