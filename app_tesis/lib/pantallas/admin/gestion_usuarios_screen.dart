import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/docente_service.dart';
import '../../config/responsive_helper.dart';
import 'crear_docente_screen.dart';
import 'detalle_docente_screen.dart';
import 'editar_docente_screen.dart';

class GestionUsuariosScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionUsuariosScreen({super.key, required this.usuario});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _docentes = [];
  List<Map<String, dynamic>> _docentesFiltrados = [];
  final _searchController = TextEditingController();
  String _filtroEstado = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
    _searchController.addListener(_filtrarDocentes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDocentes() async {
    setState(() => _isLoading = true);

    try {
      final docentes = await DocenteService.listarDocentes();
      setState(() {
        _docentes = docentes;
        _aplicarFiltros();
      });
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar docentes: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filtrarDocentes() {
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      _docentesFiltrados = _docentes.where((docente) {
        final nombreMatch = (docente['nombreDocente'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query);
        final emailMatch = (docente['emailDocente'] ?? '')
            .toString()
            .toLowerCase()
            .contains(query);
        
        final cumpleBusqueda = query.isEmpty || nombreMatch || emailMatch;
        
        final estadoDocente = docente['estadoDocente'] ?? true;
        final cumpleEstado = _filtroEstado == 'Todos' ||
            (_filtroEstado == 'Activos' && estadoDocente) ||
            (_filtroEstado == 'Inactivos' && !estadoDocente);
        
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

  Future<void> _deshabilitarDocente(Map<String, dynamic> docente) async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
      helpText: 'Selecciona fecha de salida',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(context.responsivePadding),
        title: Text(
          '¿Deshabilitar docente?',
          style: TextStyle(fontSize: context.responsiveFontSize(18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de deshabilitar a ${docente['nombreDocente']}?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(14),
              ),
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              '⚠️ El docente no podrá acceder al sistema después de esta acción.',
              style: TextStyle(
                color: Colors.orange,
                fontSize: context.responsiveFontSize(13),
              ),
            ),
            ResponsiveHelper.verticalSpace(context, multiplier: 0.8),
            Text(
              'Fecha de salida: ${fechaSeleccionada.day}/${fechaSeleccionada.month}/${fechaSeleccionada.year}',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
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

    final resultado = await DocenteService.eliminarDocente(
      id: docente['_id'],
      salidaDocente: fechaSeleccionada.toIso8601String().split('T')[0],
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Docente deshabilitado exitosamente');
      _cargarDocentes();
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
          'Gestión de Docentes',
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
            onPressed: _cargarDocentes,
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDocentes,
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

            // Lista de docentes
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _docentesFiltrados.isEmpty
                      ? _buildEstadoVacio()
                      : useGrid
                          ? _buildGridView()
                          : _buildListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearDocenteScreen(),
            ),
          );

          if (resultado == true && mounted) {
            _cargarDocentes();
          }
        },
        backgroundColor: const Color(0xFF1565C0),
        child: Icon(
          Icons.person_add,
          size: context.responsiveIconSize(24),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(context.responsivePadding),
      itemCount: _docentesFiltrados.length,
      itemBuilder: (context, index) {
        final docente = _docentesFiltrados[index];
        return _DocenteCard(
          docente: docente,
          onDesabilitar: () => _deshabilitarDocente(docente),
          onVerDetalle: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleDocenteScreen(
                  docenteId: docente['_id'],
                ),
              ),
            );
          },
          onEditar: () async {
            final resultado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => EditarDocenteScreen(
                  docente: docente,
                ),
              ),
            );

            if (resultado == true && mounted) {
              _cargarDocentes();
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
      itemCount: _docentesFiltrados.length,
      itemBuilder: (context, index) {
        final docente = _docentesFiltrados[index];
        return _DocenteGridCard(
          docente: docente,
          onDesabilitar: () => _deshabilitarDocente(docente),
          onVerDetalle: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleDocenteScreen(
                  docenteId: docente['_id'],
                ),
              ),
            );
          },
          onEditar: () async {
            final resultado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => EditarDocenteScreen(
                  docente: docente,
                ),
              ),
            );

            if (resultado == true && mounted) {
              _cargarDocentes();
            }
          },
        );
      },
    );
  }

  Widget _buildEstadoVacio() {
    if (_docentes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: context.responsiveIconSize(80),
              color: Colors.grey[400],
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              'No hay docentes registrados',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: Colors.grey[600],
              ),
            ),
            ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
            Text(
              'Presiona el botón + para crear uno',
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[500],
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
              'No se encontraron docentes',
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

// Widget para la tarjeta de docente (ListView)
class _DocenteCard extends StatelessWidget {
  final Map<String, dynamic> docente;
  final VoidCallback onDesabilitar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _DocenteCard({
    required this.docente,
    required this.onDesabilitar,
    required this.onVerDetalle,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final estadoDocente = docente['estadoDocente'] ?? true;
    final avatarUrl = docente['avatarDocente'] ??
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
          backgroundImage: NetworkImage(avatarUrl),
          backgroundColor: Colors.grey[300],
        ),
        title: Text(
          docente['nombreDocente'] ?? 'Sin nombre',
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
              docente['emailDocente'] ?? 'Sin email',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Chip(
              label: Text(
                estadoDocente ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(12),
                  color: Colors.white,
                ),
              ),
              backgroundColor: estadoDocente ? Colors.green : Colors.grey,
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
            if (estadoDocente)
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

// Widget para la tarjeta de docente (GridView)
class _DocenteGridCard extends StatelessWidget {
  final Map<String, dynamic> docente;
  final VoidCallback onDesabilitar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _DocenteGridCard({
    required this.docente,
    required this.onDesabilitar,
    required this.onVerDetalle,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final estadoDocente = docente['estadoDocente'] ?? true;
    final avatarUrl = docente['avatarDocente'] ??
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
                      color: estadoDocente ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      estadoDocente ? 'Activo' : 'Inactivo',
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
                      if (estadoDocente)
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
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: Colors.grey[300],
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 0.8),
              Text(
                docente['nombreDocente'] ?? 'Sin nombre',
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
                docente['emailDocente'] ?? 'Sin email',
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