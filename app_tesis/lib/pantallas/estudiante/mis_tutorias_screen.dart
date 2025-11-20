// lib/pantallas/estudiante/mis_tutorias_screen.dart - CON FILTROS COMPLETOS
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
import 'reagendar_tutoria_dialog.dart';

class MisTutoriasScreen extends StatefulWidget {
  final Usuario usuario;

  const MisTutoriasScreen({super.key, required this.usuario});

  @override
  State<MisTutoriasScreen> createState() => _MisTutoriasScreenState();
}

class _MisTutoriasScreenState extends State<MisTutoriasScreen> 
    with SingleTickerProviderStateMixin {
  
  List<Map<String, dynamic>> _todasTutorias = [];
  List<Map<String, dynamic>> _tutoriasFiltradas = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  // ✅ NUEVAS VARIABLES PARA FILTROS
  String? _filtroEstado;
  final List<String> _estadosDisponibles = [
    'Todos',
    'pendiente',
    'confirmada',
    'finalizada',
    'cancelada_por_estudiante',
    'cancelada_por_docente',
    'rechazada',
    'expirada',
  ];
  
  final List<String> _tabs = ['Activas', 'Historial'];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabIndex = _tabController.index;
          _filtroEstado = null; // Resetear filtro al cambiar tab
        });
        _cargarTutorias();
      }
    });
    _cargarTutorias();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarTutorias() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔄 Cargando tutorías - Tab: ${_tabs[_tabIndex]}');
      
      List<Map<String, dynamic>> tutorias;

      if (_tabIndex == 0) {
        // Tab "Activas": solo pendientes y confirmadas
        tutorias = await TutoriaService.listarTutorias(
          incluirCanceladas: false,
        );
        
        tutorias = tutorias.where((t) {
          final estado = t['estado'] as String;
          return estado == 'pendiente' || estado == 'confirmada';
        }).toList();
      } else {
        // Tab "Historial": todas incluyendo canceladas
        final resultado = await TutoriaService.obtenerHistorialTutorias(
          incluirCanceladas: true,
          limit: 100,
        );
        
        if (resultado != null && !resultado.containsKey('error')) {
          tutorias = List<Map<String, dynamic>>.from(resultado['tutorias'] ?? []);
        } else {
          tutorias = [];
        }
      }
      
      if (mounted) {
        setState(() {
          _todasTutorias = tutorias;
          _aplicarFiltros();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando tutorías: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar tutorías: $e');
      }
    }
  }

  // ✅ NUEVA FUNCIÓN: Aplicar filtros
  void _aplicarFiltros() {
    if (_filtroEstado == null || _filtroEstado == 'Todos') {
      _tutoriasFiltradas = List.from(_todasTutorias);
    } else {
      _tutoriasFiltradas = _todasTutorias.where((t) {
        return t['estado'] == _filtroEstado;
      }).toList();
    }
    
    print('📊 Total: ${_todasTutorias.length}, Filtradas: ${_tutoriasFiltradas.length}');
  }

  Future<void> _cancelarTutoria(String tutoriaId) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de cancelar esta tutoría?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivoController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (motivo == null) return;

    _mostrarCargando();

    final resultado = await TutoriaService.cancelarTutoria(
      tutoriaId: tutoriaId,
      motivo: motivo.isEmpty ? 'Sin motivo especificado' : motivo,
      canceladaPor: 'Estudiante',
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría cancelada exitosamente');
      _cargarTutorias();
    }
  }

  Future<void> _reagendarTutoria(Map<String, dynamic> tutoria) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReagendarTutoriaDialog(
        tutoria: tutoria,
        nombreDocente: tutoria['docente']?['nombreDocente'] ?? 'Docente',
      ),
    );

    if (resultado != null && resultado['success'] == true) {
      _mostrarExito('Tutoría reagendada exitosamente');
      _cargarTutorias();
    }
  }

  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Procesando...'),
              ],
            ),
          ),
        ),
      ),
    );
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

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.green;
      case 'rechazada':
        return Colors.red;
      case 'finalizada':
        return Colors.blue;
      case 'cancelada_por_estudiante':
      case 'cancelada_por_docente':
        return Colors.grey;
      case 'expirada':  // ✅ NUEVO
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'confirmada':
        return 'CONFIRMADA';
      case 'rechazada':
        return 'RECHAZADA';
      case 'finalizada':
        return 'FINALIZADA';
      case 'cancelada_por_estudiante':
        return 'CANCELADA';
      case 'cancelada_por_docente':
        return 'CANCELADA POR DOCENTE';
      case 'expirada':  // ✅ NUEVO
        return 'EXPIRADA';
      default:
        return estado.toUpperCase();
    }
  }

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'Sin fecha';
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Tutorías'),
        backgroundColor: const Color(0xFF1565C0),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        actions: [
          // ✅ NUEVO: Botón de filtros (solo en Historial)
          if (_tabIndex == 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por estado',
              onSelected: (value) {
                setState(() {
                  _filtroEstado = value == 'Todos' ? null : value;
                  _aplicarFiltros();
                });
              },
              itemBuilder: (context) {
                return _estadosDisponibles.map((estado) {
                  final isSelected = (_filtroEstado == estado) || 
                                    (estado == 'Todos' && _filtroEstado == null);
                  
                  return PopupMenuItem<String>(
                    value: estado,
                    child: Row(
                      children: [
                        if (isSelected)
                          const Icon(Icons.check, size: 18, color: Color(0xFF1565C0))
                        else
                          const SizedBox(width: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            estado == 'Todos' 
                              ? 'Mostrar todos' 
                              : _getEstadoTexto(estado),
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTutorias,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ NUEVO: Chip de filtro activo
          if (_filtroEstado != null && _tabIndex == 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.filter_list, size: 18),
                    label: Text('Filtro: ${_getEstadoTexto(_filtroEstado!)}'),
                    onDeleted: () {
                      setState(() {
                        _filtroEstado = null;
                        _aplicarFiltros();
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                  ),
                  Text(
                    '${_tutoriasFiltradas.length} de ${_todasTutorias.length} tutorías',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          
          // Lista de tutorías
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarTutorias,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tutoriasFiltradas.isEmpty
                      ? _buildEmptyState()
                      : _buildListaTutorias(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final mensaje = _filtroEstado != null
        ? 'No hay tutorías con el filtro seleccionado'
        : (_tabIndex == 0 
            ? 'No tienes tutorías activas'
            : 'No tienes historial de tutorías');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_filtroEstado != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _filtroEstado = null;
                  _aplicarFiltros();
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar filtro'),
            ),
          ],
          if (_tabIndex == 0 && _filtroEstado == null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Agendar Tutoría'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListaTutorias() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tutoriasFiltradas.length,
      itemBuilder: (context, index) {
        final tutoria = _tutoriasFiltradas[index];
        return _buildTutoriaCard(tutoria);
      },
    );
  }

  Widget _buildTutoriaCard(Map<String, dynamic> tutoria) {
    final docente = tutoria['docente'] as Map<String, dynamic>?;
    final estado = tutoria['estado'] as String;
    final puedeCancelar = estado == 'pendiente' || estado == 'confirmada';
    final puedeReagendar = estado == 'pendiente' || estado == 'confirmada';
    final reagendada = tutoria['reagendadaPor'] != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(
                    docente?['avatarDocente'] ??
                        'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        docente?['nombreDocente'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        docente?['oficinaDocente'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(estado).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getEstadoColor(estado),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _getEstadoTexto(estado),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _getEstadoColor(estado),
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Información
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(_formatearFecha(tutoria['fecha'])),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text('${tutoria['horaInicio']} - ${tutoria['horaFin']}'),
                if (reagendada) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.update, size: 12, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          'Reagendada',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Motivos
            if (estado == 'rechazada' && tutoria['motivoRechazo'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.info_outline,
                color: Colors.red,
                title: 'Motivo de rechazo',
                content: tutoria['motivoRechazo'],
              ),
            ],

            if ((estado == 'cancelada_por_estudiante' || 
                 estado == 'cancelada_por_docente') && 
                 tutoria['motivoCancelacion'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.cancel_outlined,
                color: Colors.orange,
                title: 'Motivo de cancelación',
                content: tutoria['motivoCancelacion'],
              ),
            ],

            if (reagendada && tutoria['motivoReagendamiento'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoBox(
                icon: Icons.update,
                color: Colors.blue,
                title: 'Motivo de reagendamiento',
                content: tutoria['motivoReagendamiento'],
              ),
            ],

            // Botones de acción
            if (puedeCancelar || puedeReagendar) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (puedeReagendar) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _reagendarTutoria(tutoria),
                        icon: const Icon(Icons.event_repeat, size: 18),
                        label: const Text('Reagendar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (puedeCancelar)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _cancelarTutoria(tutoria['_id']),
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text('Cancelar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}