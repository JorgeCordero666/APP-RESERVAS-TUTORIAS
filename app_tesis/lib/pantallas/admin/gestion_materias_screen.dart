import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../modelos/materia.dart';
import '../../servicios/materia_service.dart';
import '../../config/responsive_helper.dart';
import 'crear_materia_screen.dart';
import 'editar_materia_screen.dart';
import 'detalle_materia_screen.dart';

class GestionMateriasScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionMateriasScreen({super.key, required this.usuario});

  @override
  State<GestionMateriasScreen> createState() => _GestionMateriasScreenState();
}

class _GestionMateriasScreenState extends State<GestionMateriasScreen> {
  bool _isLoading = false;
  List<Materia> _materias = [];
  List<Materia> _materiasFiltradas = [];
  final _searchController = TextEditingController();
  String _filtroSemestre = 'Todos';
  String _filtroEstado = 'Activas';

  final List<String> _semestres = [
    'Todos',
    'Nivelación',
    'Primer Semestre',
    'Segundo Semestre',
    'Tercer Semestre',
    'Cuarto Semestre',
    'Quinto Semestre',
    'Sexto Semestre',
  ];

  @override
  void initState() {
    super.initState();
    print('🎬 GestionMateriasScreen iniciado');
    _cargarMaterias();
    _searchController.addListener(_filtrarMaterias);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarMaterias() async {
    print('\n🔄 === CARGANDO MATERIAS ===');
    print('   Filtro estado: $_filtroEstado');
    
    setState(() => _isLoading = true);

    try {
      final materias = await MateriaService.listarMaterias(
        soloActivas: _filtroEstado == 'Activas',
      );
      
      print('📦 Materias recibidas del servicio: ${materias.length}');
      
      if (materias.isEmpty) {
        print('⚠️ No hay materias en la base de datos');
      } else {
        print('📋 Primeras materias:');
        materias.take(3).forEach((m) {
          print('   - ${m.nombre} (${m.codigo}) - Activa: ${m.activa}');
        });
      }
      
      if (mounted) {
        setState(() {
          _materias = materias;
          _aplicarFiltros();
          print('✅ Estado actualizado. Total: ${_materias.length}');
        });
      }
    } catch (e) {
      print('❌ ERROR al cargar materias: $e');
      if (mounted) {
        _mostrarError('Error al cargar materias: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    
    print('=== FIN CARGA ===\n');
  }

  void _filtrarMaterias() {
    print('🔍 Filtrando materias...');
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase().trim();
    
    print('📝 Aplicando filtros:');
    print('   Query: "$query"');
    print('   Semestre: $_filtroSemestre');
    print('   Estado: $_filtroEstado');
    print('   Total antes: ${_materias.length}');
    
    setState(() {
      _materiasFiltradas = _materias.where((materia) {
        final nombreMatch = materia.nombre.toLowerCase().contains(query);
        final codigoMatch = materia.codigo.toLowerCase().contains(query);
        final cumpleBusqueda = query.isEmpty || nombreMatch || codigoMatch;
        
        final cumpleSemestre = _filtroSemestre == 'Todos' ||
            materia.semestre == _filtroSemestre;
        
        final cumpleEstado = _filtroEstado == 'Todas' ||
            (_filtroEstado == 'Activas' && materia.activa) ||
            (_filtroEstado == 'Inactivas' && !materia.activa);
        
        return cumpleBusqueda && cumpleSemestre && cumpleEstado;
      }).toList();
      
      print('✅ Materias filtradas: ${_materiasFiltradas.length}');
    });
  }

  void _cambiarFiltroSemestre(String nuevoFiltro) {
    print('🔄 Cambiando filtro semestre a: $nuevoFiltro');
    setState(() {
      _filtroSemestre = nuevoFiltro;
      _aplicarFiltros();
    });
  }

  void _cambiarFiltroEstado(String nuevoFiltro) {
    print('🔄 Cambiando filtro estado a: $nuevoFiltro');
    setState(() {
      _filtroEstado = nuevoFiltro;
      _cargarMaterias();
    });
  }

  Future<void> _desactivarMateria(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.all(context.responsivePadding),
        title: Text(
          '¿Desactivar materia?',
          style: TextStyle(fontSize: context.responsiveFontSize(18)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de desactivar "${materia.nombre}"?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(14),
              ),
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              '⚠️ La materia quedará inactiva pero no se eliminará.',
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
              'Desactivar',
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    final resultado = await MateriaService.eliminarMateria(materia.id);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Materia desactivada exitosamente');
      await _cargarMaterias();
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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
          'Gestión de Materias (${_materiasFiltradas.length})',
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
            onPressed: () {
              print('🔄 Botón refresh presionado');
              _cargarMaterias();
            },
            tooltip: 'Recargar lista',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('🔄 Pull to refresh activado');
          await _cargarMaterias();
        },
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: EdgeInsets.all(context.responsivePadding),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código',
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

            // Filtros por semestre
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsivePadding,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _semestres.map((semestre) {
                    final isSelected = _filtroSemestre == semestre;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: context.responsiveSpacing * 0.5,
                      ),
                      child: FilterChip(
                        label: Text(
                          semestre,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (_) => _cambiarFiltroSemestre(semestre),
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          fontSize: context.responsiveFontSize(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveSpacing * 0.8,
                          vertical: context.responsiveSpacing * 0.5,
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
                    label: 'Activas',
                    isSelected: _filtroEstado == 'Activas',
                    onTap: () => _cambiarFiltroEstado('Activas'),
                    color: Colors.green,
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  _FiltroChip(
                    label: 'Inactivas',
                    isSelected: _filtroEstado == 'Inactivas',
                    onTap: () => _cambiarFiltroEstado('Inactivas'),
                    color: Colors.grey,
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  _FiltroChip(
                    label: 'Todas',
                    isSelected: _filtroEstado == 'Todas',
                    onTap: () => _cambiarFiltroEstado('Todas'),
                  ),
                ],
              ),
            ),

            // Lista de materias
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando materias...'),
                        ],
                      ),
                    )
                  : _materiasFiltradas.isEmpty
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
          print('➕ Navegando a crear materia...');
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const CrearMateriaScreen(),
            ),
          );

          print('🔙 Retorno: $resultado');
          if (resultado == true && mounted) {
            print('✅ Materia creada, recargando...');
            await _cargarMaterias();
          }
        },
        backgroundColor: const Color(0xFF1565C0),
        child: Icon(
          Icons.add,
          size: context.responsiveIconSize(24),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(context.responsivePadding),
      itemCount: _materiasFiltradas.length,
      itemBuilder: (context, index) {
        final materia = _materiasFiltradas[index];
        return _MateriaCard(
          materia: materia,
          onDesactivar: () => _desactivarMateria(materia),
          onVerDetalle: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleMateriaScreen(
                  materiaId: materia.id,
                ),
              ),
            );
          },
          onEditar: () async {
            print('📝 Navegando a editar: ${materia.nombre}');
            final resultado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => EditarMateriaScreen(
                  materia: materia,
                ),
              ),
            );

            if (resultado == true && mounted) {
              print('✅ Editada, recargando...');
              _cargarMaterias();
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
        childAspectRatio: context.isDesktop ? 1.3 : 1.1,
        crossAxisSpacing: context.responsiveSpacing,
        mainAxisSpacing: context.responsiveSpacing,
      ),
      itemCount: _materiasFiltradas.length,
      itemBuilder: (context, index) {
        final materia = _materiasFiltradas[index];
        return _MateriaGridCard(
          materia: materia,
          onDesactivar: () => _desactivarMateria(materia),
          onVerDetalle: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetalleMateriaScreen(
                  materiaId: materia.id,
                ),
              ),
            );
          },
          onEditar: () async {
            final resultado = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => EditarMateriaScreen(
                  materia: materia,
                ),
              ),
            );

            if (resultado == true && mounted) {
              _cargarMaterias();
            }
          },
        );
      },
    );
  }

  Widget _buildEstadoVacio() {
    if (_materias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: context.responsiveIconSize(80),
              color: Colors.grey[400],
            ),
            ResponsiveHelper.verticalSpace(context),
            Text(
              'No hay materias registradas',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: Colors.grey[600],
              ),
            ),
            ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
            Text(
              'Presiona el botón + para crear una',
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
              'No se encontraron materias',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                color: Colors.grey[600],
              ),
            ),
            ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
            Text(
              'Intenta con otro criterio',
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

// Widget para tarjeta de materia (ListView)
class _MateriaCard extends StatelessWidget {
  final Materia materia;
  final VoidCallback onDesactivar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _MateriaCard({
    required this.materia,
    required this.onDesactivar,
    required this.onVerDetalle,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.responsivePadding,
          vertical: context.responsiveSpacing * 0.5,
        ),
        leading: Container(
          width: context.isMobile ? 50 : 60,
          height: context.isMobile ? 50 : 60,
          decoration: BoxDecoration(
            color: materia.activa 
                ? const Color(0xFF1565C0).withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              materia.codigo,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(12),
                color: materia.activa 
                    ? const Color(0xFF1565C0)
                    : Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        title: Text(
          materia.nombre,
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
              materia.semestre,
              style: TextStyle(fontSize: context.responsiveFontSize(13)),
            ),
            SizedBox(height: context.responsiveSpacing * 0.3),
            Row(
              children: [
                Chip(
                  label: Text(
                    '${materia.creditos} crédito${materia.creditos != 1 ? "s" : ""}',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(11),
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.blue[50],
                ),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Chip(
                  label: Text(
                    materia.activa ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(11),
                      color: Colors.white,
                    ),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: materia.activa ? Colors.green : Colors.grey,
                ),
              ],
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
              case 'desactivar':
                onDesactivar();
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
            if (materia.activa)
              PopupMenuItem(
                value: 'desactivar',
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: context.responsiveIconSize(20),
                      color: Colors.red,
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Text(
                      'Desactivar',
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

// Widget para tarjeta de materia (GridView)
class _MateriaGridCard extends StatelessWidget {
  final Materia materia;
  final VoidCallback onDesactivar;
  final VoidCallback onVerDetalle;
  final VoidCallback onEditar;

  const _MateriaGridCard({
    required this.materia,
    required this.onDesactivar,
    required this.onVerDetalle,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onVerDetalle,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(context.responsivePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing * 0.8,
                      vertical: context.responsiveSpacing * 0.4,
                    ),
                    decoration: BoxDecoration(
                      color: materia.activa
                          ? const Color(0xFF1565C0).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      materia.codigo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.responsiveFontSize(12),
                        color: materia.activa
                            ? const Color(0xFF1565C0)
                            : Colors.grey,
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
                        case 'desactivar':
                          onDesactivar();
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
                      if (materia.activa)
                        PopupMenuItem(
                          value: 'desactivar',
                          child: Text(
                            'Desactivar',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      materia.nombre,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.responsiveFontSize(15),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ResponsiveHelper.verticalSpace(context, multiplier: 0.3),
                    Text(
                      materia.semestre,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ResponsiveHelper.verticalSpace(context, multiplier: 0.5),
              Row(
                children: [
                  Icon(
                    Icons.stars,
                    size: context.responsiveIconSize(16),
                    color: Colors.orange,
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.3),
                  Text(
                    '${materia.creditos} créditos',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(12),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing * 0.6,
                      vertical: context.responsiveSpacing * 0.2,
                    ),
                    decoration: BoxDecoration(
                      color: materia.activa ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      materia.activa ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(10),
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget para chips de filtro
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