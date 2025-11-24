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
  late AnimationController _fabAnimationController;
  
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
          _filtroEstado = null;
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
        tutorias = await TutoriaService.listarTutorias(
          incluirCanceladas: false,
        );
        
        tutorias = tutorias.where((t) {
          final estado = t['estado'] as String;
          return estado == 'pendiente' || estado == 'confirmada';
        }).toList();
      } else {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.cancel, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('Cancelar Tutoría'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Estás seguro de cancelar esta tutoría?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Ej: Tengo un compromiso académico',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit_note),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('No, mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, motivoController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
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
      builder: (context) => Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          child: const Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 3),
                SizedBox(height: 20),
                Text(
                  'Procesando...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.amber[700]!;
      case 'confirmada':
        return Colors.green[600]!;
      case 'rechazada':
        return Colors.red[600]!;
      case 'finalizada':
        return Colors.blue[600]!;
      case 'cancelada_por_estudiante':
      case 'cancelada_por_docente':
        return Colors.grey[600]!;
      case 'expirada':
        return Colors.brown[600]!;
      default:
        return Colors.grey[600]!;
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
      case 'expirada':
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Mis Tutorías',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF1565C0),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
              tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
        ),
        actions: [
          if (_tabIndex == 1)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_list, size: 20),
                ),
                tooltip: 'Filtrar por estado',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 48),
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
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              size: 20,
                              color: isSelected ? const Color(0xFF1565C0) : Colors.grey[400],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                estado == 'Todos' 
                                  ? 'Mostrar todos' 
                                  : _getEstadoTexto(estado),
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, size: 20),
            ),
            onPressed: _cargarTutorias,
            tooltip: 'Recargar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (_filtroEstado != null && _tabIndex == 1)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Chip(
                      avatar: Icon(
                        Icons.filter_list,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                      label: Text(
                        'Filtro: ${_getEstadoTexto(_filtroEstado!)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      onDeleted: () {
                        setState(() {
                          _filtroEstado = null;
                          _aplicarFiltros();
                        });
                      },
                      deleteIcon: Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.blue[700],
                      ),
                      backgroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${_tutoriasFiltradas.length} de ${_todasTutorias.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: _cargarTutorias,
              color: const Color(0xFF1565C0),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
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
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                mensaje,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _filtroEstado != null
                    ? 'Intenta con otro filtro'
                    : (_tabIndex == 0
                        ? 'Agenda una tutoría para comenzar'
                        : 'Tus tutorías aparecerán aquí'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (_filtroEstado != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filtroEstado = null;
                      _aplicarFiltros();
                    });
                  },
                  icon: const Icon(Icons.clear_all, size: 20),
                  label: const Text('Limpiar filtro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
              if (_tabIndex == 0 && _filtroEstado == null) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.add_circle_outline, size: 22),
                  label: const Text('Agendar Tutoría'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaTutorias() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tutoriasFiltradas.length,
      itemBuilder: (context, index) {
        final tutoria = _tutoriasFiltradas[index];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _buildTutoriaCard(tutoria),
        );
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
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: _getEstadoColor(estado),
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getEstadoColor(estado).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: NetworkImage(
                          docente?['avatarDocente'] ??
                              'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            docente?['nombreDocente'] ?? 'Sin nombre',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  docente?['oficinaDocente'] ?? 'Sin oficina',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
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
                        color: _getEstadoColor(estado).withOpacity(0.15),
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
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[100]!,
                        Colors.grey[300]!,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatearFecha(tutoria['fecha']),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.access_time,
                              size: 18,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${tutoria['horaInicio']} - ${tutoria['horaFin']}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (reagendada) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[400]!, Colors.blue[600]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.update,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Reagendada',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

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

                if (puedeCancelar || puedeReagendar) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (puedeReagendar) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _reagendarTutoria(tutoria),
                            icon: const Icon(Icons.event_repeat, size: 18),
                            label: const Text('Reagendar'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.blue[700],
                              backgroundColor: Colors.blue[50],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.blue[200]!, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (puedeCancelar)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _cancelarTutoria(tutoria['_id']),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Cancelar'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.red[700],
                              backgroundColor: Colors.red[50],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.red[200]!, width: 1.5),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}