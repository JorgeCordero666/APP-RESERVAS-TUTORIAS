// lib/pantallas/admin/gestion_materias_screen.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../modelos/materia.dart';
import '../../servicios/materia_service.dart';
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

  // ✅ CORRECCIÓN: Cargar materias con logs detallados
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
      _cargarMaterias(); // Recargar con filtro de estado
    });
  }

  Future<void> _desactivarMateria(Materia materia) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Desactivar materia?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de desactivar "${materia.nombre}"?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ La materia quedará inactiva pero no se eliminará.',
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
            child: const Text('Desactivar'),
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
      await _cargarMaterias(); // ✅ Recargar después de desactivar
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Materias (${_materiasFiltradas.length})'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o código',
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

            // Filtros por semestre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _semestres.map((semestre) {
                    final isSelected = _filtroSemestre == semestre;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(semestre),
                        selected: isSelected,
                        onSelected: (_) => _cambiarFiltroSemestre(semestre),
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Filtros por estado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _FiltroChip(
                    label: 'Activas',
                    isSelected: _filtroEstado == 'Activas',
                    onTap: () => _cambiarFiltroEstado('Activas'),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Inactivas',
                    isSelected: _filtroEstado == 'Inactivas',
                    onTap: () => _cambiarFiltroEstado('Inactivas'),
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
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
                        ),
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
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    if (_materias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay materias registradas',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Presiona el botón + para crear una',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
              'No se encontraron materias',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro criterio',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
  }
}

// Widget para tarjeta de materia
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
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
                fontSize: 12,
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
              materia.semestre,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    '${materia.creditos} crédito${materia.creditos != 1 ? "s" : ""}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.blue[50],
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    materia.activa ? 'Activa' : 'Inactiva',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
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
          icon: const Icon(Icons.more_vert),
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
            if (materia.activa)
              const PopupMenuItem(
                value: 'desactivar',
                child: Row(
                  children: [
                    Icon(Icons.block, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Desactivar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
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
          ),
        ),
        backgroundColor: isSelected ? chipColor : chipColor.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}