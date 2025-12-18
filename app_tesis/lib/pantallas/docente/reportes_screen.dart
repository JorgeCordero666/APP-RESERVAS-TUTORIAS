import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
import '../../config/responsive_helper.dart';
import 'finalizar_tutoria_dialog.dart';
import '../estudiante/reagendar_tutoria_dialog.dart';

class ReportesScreen extends StatefulWidget {
  final Usuario usuario;

  const ReportesScreen({super.key, required this.usuario});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> 
    with SingleTickerProviderStateMixin {
  
  List<Map<String, dynamic>> _todasTutorias = [];
  List<Map<String, dynamic>> _tutoriasFiltradas = [];
  bool _isLoading = true;
  late TabController _tabController;
  
  String? _filtroEstado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  
  final List<String> _estadosDisponibles = [
    'Todos', 'pendiente', 'confirmada', 'finalizada',
    'cancelada_por_estudiante', 'cancelada_por_docente', 'rechazada',
  ];
  
  final List<String> _tabs = ['Estadísticas', 'Historial Completo'];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _tabIndex = _tabController.index);
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
      final resultado = await TutoriaService.obtenerHistorialTutorias(
        incluirCanceladas: true,
        limit: 200,
      );
      
      if (resultado != null && !resultado.containsKey('error')) {
        final tutorias = List<Map<String, dynamic>>.from(resultado['tutorias'] ?? []);
        
        if (mounted) {
          setState(() {
            _todasTutorias = tutorias;
            _aplicarFiltros();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          _mostrarError('Error al cargar tutorías');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error: $e');
      }
    }
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultado = List.from(_todasTutorias);
    
    if (_filtroEstado != null && _filtroEstado != 'Todos') {
      resultado = resultado.where((t) => t['estado'] == _filtroEstado).toList();
    }
    
    if (_fechaInicio != null || _fechaFin != null) {
      resultado = resultado.where((t) {
        final fecha = DateTime.parse(t['fecha']);
        bool cumple = true;
        if (_fechaInicio != null) cumple = cumple && fecha.isAfter(_fechaInicio!.subtract(const Duration(days: 1)));
        if (_fechaFin != null) cumple = cumple && fecha.isBefore(_fechaFin!.add(const Duration(days: 1)));
        return cumple;
      }).toList();
    }
    
    _tutoriasFiltradas = resultado;
  }

  Future<void> _finalizarTutoria(Map<String, dynamic> tutoria) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => FinalizarTutoriaDialog(tutoria: tutoria),
    );

    if (resultado != null && resultado['success'] == true) {
      _mostrarExito('Tutoría finalizada correctamente');
      _cargarTutorias();
    }
  }

  Future<void> _reagendarTutoria(Map<String, dynamic> tutoria) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ReagendarTutoriaDialog(
        tutoria: tutoria,
        nombreDocente: widget.usuario.nombre,
      ),
    );

    if (resultado != null && resultado['success'] == true) {
      _mostrarExito('Tutoría reagendada exitosamente');
      _cargarTutorias();
    }
  }

  Future<void> _cancelarTutoria(String tutoriaId) async {
    final motivoController = TextEditingController();

    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancelar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('¿Estás seguro de cancelar esta tutoría?'),
            SizedBox(height: context.responsiveSpacing),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, motivoController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (motivo == null) return;

    final resultado = await TutoriaService.cancelarTutoria(
      tutoriaId: tutoriaId,
      motivo: motivo.isEmpty ? 'Sin motivo' : motivo,
      canceladaPor: 'Docente',
    );

    if (!mounted) return;
    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría cancelada');
      _cargarTutorias();
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) setState(() { _fechaInicio = fecha; _aplicarFiltros(); });
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (fecha != null) setState(() { _fechaFin = fecha; _aplicarFiltros(); });
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroEstado = null;
      _fechaInicio = null;
      _fechaFin = null;
      _aplicarFiltros();
    });
  }

  void _mostrarError(String m) => _mostrarSnackBar(m, const Color(0xFFD32F2F), Icons.error_outline_rounded);
  void _mostrarExito(String m) => _mostrarSnackBar(m, const Color(0xFF43A047), Icons.check_circle_outline_rounded);

  void _mostrarSnackBar(String mensaje, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: context.responsiveIconSize(24)),
            SizedBox(width: context.responsiveSpacing),
            Expanded(child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.orange;
      case 'confirmada': return Colors.green;
      case 'rechazada': return Colors.red;
      case 'finalizada': return Colors.blue;
      case 'cancelada_por_estudiante':
      case 'cancelada_por_docente': return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado) {
      case 'pendiente': return 'PENDIENTE';
      case 'confirmada': return 'CONFIRMADA';
      case 'rechazada': return 'RECHAZADA';
      case 'finalizada': return 'FINALIZADA';
      case 'cancelada_por_estudiante': return 'CANCELADA';
      case 'cancelada_por_docente': return 'CANCELADA POR MÍ';
      default: return estado.toUpperCase();
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

  Map<String, int> _calcularEstadisticas() {
    final stats = {
      'total': _todasTutorias.length, 'pendientes': 0, 'confirmadas': 0,
      'finalizadas': 0, 'canceladas': 0, 'rechazadas': 0,
      'asistencias': 0, 'inasistencias': 0,
    };

    for (var t in _todasTutorias) {
      final estado = t['estado'] as String;
      if (estado == 'pendiente') stats['pendientes'] = stats['pendientes']! + 1;
      if (estado == 'confirmada') stats['confirmadas'] = stats['confirmadas']! + 1;
      if (estado == 'finalizada') stats['finalizadas'] = stats['finalizadas']! + 1;
      if (estado == 'rechazada') stats['rechazadas'] = stats['rechazadas']! + 1;
      if (estado == 'cancelada_por_estudiante' || estado == 'cancelada_por_docente') 
        stats['canceladas'] = stats['canceladas']! + 1;
      if (t['asistenciaEstudiante'] == true) stats['asistencias'] = stats['asistencias']! + 1;
      if (t['asistenciaEstudiante'] == false) stats['inasistencias'] = stats['inasistencias']! + 1;
    }
    return stats;
  }

  Map<String, Map<String, dynamic>> _calcularEstadisticasPorEstudiante() {
    final Map<String, Map<String, dynamic>> estudiantesStats = {};
    
    for (var tutoria in _todasTutorias) {
      final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;
      if (estudiante == null) continue;
      
      final estudianteId = estudiante['_id'] as String;
      final estado = tutoria['estado'] as String;
      
      if (!estudiantesStats.containsKey(estudianteId)) {
        estudiantesStats[estudianteId] = {
          'nombre': estudiante['nombreEstudiante'] ?? 'Sin nombre',
          'email': estudiante['emailEstudiante'] ?? '',
          'fotoPerfil': estudiante['fotoPerfil'],
          'total': 0, 'pendientes': 0, 'confirmadas': 0,
          'finalizadas': 0, 'canceladas': 0, 'rechazadas': 0,
          'asistencias': 0, 'inasistencias': 0,
        };
      }
      
      final stats = estudiantesStats[estudianteId]!;
      stats['total'] = (stats['total'] as int) + 1;
      
      if (estado == 'pendiente') stats['pendientes'] = (stats['pendientes'] as int) + 1;
      if (estado == 'confirmada') stats['confirmadas'] = (stats['confirmadas'] as int) + 1;
      if (estado == 'finalizada') stats['finalizadas'] = (stats['finalizadas'] as int) + 1;
      if (estado == 'rechazada') stats['rechazadas'] = (stats['rechazadas'] as int) + 1;
      if (estado == 'cancelada_por_estudiante' || estado == 'cancelada_por_docente')
        stats['canceladas'] = (stats['canceladas'] as int) + 1;
      if (tutoria['asistenciaEstudiante'] == true) stats['asistencias'] = (stats['asistencias'] as int) + 1;
      if (tutoria['asistenciaEstudiante'] == false) stats['inasistencias'] = (stats['inasistencias'] as int) + 1;
    }
    
    return estudiantesStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Reportes de Tutorías',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: context.responsiveFontSize(21),
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: context.responsiveFontSize(14),
          ),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        actions: [
          if (_tabIndex == 1 && (_filtroEstado != null || _fechaInicio != null || _fechaFin != null))
            IconButton(icon: const Icon(Icons.filter_alt_off_rounded), onPressed: _limpiarFiltros),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _cargarTutorias),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildEstadisticasTab(), _buildHistorialTab()],
      ),
    );
  }

  Widget _buildEstadisticasTab() {
    if (_isLoading) return _buildLoadingState();

    final stats = _calcularEstadisticas();
    final tasaAsistencia = stats['finalizadas']! > 0
        ? ((stats['asistencias']! / stats['finalizadas']!) * 100).toStringAsFixed(1)
        : 'N/A';

    final estudiantesStats = _calcularEstadisticasPorEstudiante();
    final estudiantesLista = estudiantesStats.entries.toList()
      ..sort((a, b) => (b.value['total'] as int).compareTo(a.value['total'] as int));

    final isMobile = context.isMobile;
    final padding = context.responsivePadding;

    return ListView(
      padding: EdgeInsets.all(padding),
      children: [
        // Resumen General
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: const Color(0xFF1565C0), size: context.responsiveIconSize(26)),
                    SizedBox(width: context.responsiveSpacing),
                    Text(
                      'Resumen General',
                      style: TextStyle(fontSize: context.responsiveFontSize(20), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing * 1.5),
                _buildStatRow('Total de Tutorías', '${stats['total']}', Icons.event_note_rounded, Colors.blue),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Pendientes', '${stats['pendientes']}', Icons.pending_rounded, Colors.orange),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Confirmadas', '${stats['confirmadas']}', Icons.check_circle_rounded, Colors.green),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Finalizadas', '${stats['finalizadas']}', Icons.done_all_rounded, Colors.blue),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Canceladas', '${stats['canceladas']}', Icons.cancel_rounded, Colors.red),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Rechazadas', '${stats['rechazadas']}', Icons.block_rounded, Colors.red),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Asistencias', '${stats['asistencias']}', Icons.check_rounded, Colors.teal),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Inasistencias', '${stats['inasistencias']}', Icons.close_rounded, Colors.red),
                Divider(height: context.responsiveSpacing * 2),
                _buildStatRow('Tasa de Asistencia', '$tasaAsistencia%', Icons.percent_rounded, Colors.indigo),
              ],
            ),
          ),
        ),

        // Estadísticas por Estudiante
        if (estudiantesLista.isNotEmpty) ...[
          SizedBox(height: context.responsiveSpacing * 2),
          Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF42A5F5).withOpacity(0.1), const Color(0xFF1E88E5).withOpacity(0.05)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.people_rounded, color: Colors.green[700], size: context.responsiveIconSize(26)),
                SizedBox(width: context.responsiveSpacing),
                Expanded(
                  child: Text(
                    'Estadísticas por Estudiante',
                    style: TextStyle(fontSize: context.responsiveFontSize(20), fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${estudiantesLista.length} estudiantes',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(13),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: context.responsiveSpacing),
          ...estudiantesLista.map((entry) {
            final stats = entry.value;
            final tasaAsistencia = (stats['finalizadas'] as int) > 0
                ? (((stats['asistencias'] as int) / (stats['finalizadas'] as int)) * 100).toStringAsFixed(1)
                : 'N/A';

            return Container(
              margin: EdgeInsets.only(bottom: context.responsiveSpacing),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: isMobile ? 24 : 30,
                          backgroundImage: NetworkImage(
                            stats['fotoPerfil'] ?? 'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stats['nombre'] as String,
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(17),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!isMobile) ...[
                                SizedBox(height: 4),
                                Text(
                                  stats['email'] as String,
                                  style: TextStyle(fontSize: context.responsiveFontSize(13), color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
                          ),
                          child: Text(
                            '${stats['total']} tutorías',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(12),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Divider(height: context.responsiveSpacing * 2),
                    isMobile
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildMiniStat('Pendientes', '${stats['pendientes']}', Colors.orange)),
                                  SizedBox(width: context.responsiveSpacing * 0.75),
                                  Expanded(child: _buildMiniStat('Confirmadas', '${stats['confirmadas']}', Colors.green)),
                                ],
                              ),
                              SizedBox(height: context.responsiveSpacing * 0.75),
                              Row(
                                children: [
                                  Expanded(child: _buildMiniStat('Finalizadas', '${stats['finalizadas']}', Colors.blue)),
                                  SizedBox(width: context.responsiveSpacing * 0.75),
                                  Expanded(child: _buildMiniStat('Asistencia', tasaAsistencia, Colors.indigo)),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildMiniStat('Pendientes', '${stats['pendientes']}', Colors.orange)),
                                  SizedBox(width: context.responsiveSpacing * 0.75),
                                  Expanded(child: _buildMiniStat('Confirmadas', '${stats['confirmadas']}', Colors.green)),
                                  SizedBox(width: context.responsiveSpacing * 0.75),
                                  Expanded(child: _buildMiniStat('Finalizadas', '${stats['finalizadas']}', Colors.blue)),
                                ],
                              ),
                              SizedBox(height: context.responsiveSpacing * 0.75),
                              Row(
                                children: [
                                  Expanded(child: _buildMiniStat('Canceladas', '${stats['canceladas']}', Colors.red)),
                                  SizedBox(width: context.responsiveSpacing * 0.75),
                                  Expanded(child: _buildMiniStat('Rechazadas', '${stats['rechazadas']}', Colors.red[300]!)),
                                  SizedBox(width: context.responsiveSpacing * 0.75),
                                  Expanded(child: _buildMiniStat('Asistencia', tasaAsistencia, Colors.indigo)),
                                ],
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: context.responsiveSpacing * 0.75, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color.withOpacity(0.1), color.withOpacity(0.05)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: context.responsiveFontSize(18),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: context.responsiveFontSize(11),
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(context.responsiveSpacing * 0.75),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.15), color.withOpacity(0.05)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: context.responsiveIconSize(24)),
        ),
        SizedBox(width: context.responsiveSpacing),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: context.responsiveFontSize(15), fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialTab() {
    final padding = context.responsivePadding;
    final isMobile = context.isMobile;

    return Column(
      children: [
        // Filtros
        Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF42A5F5).withOpacity(0.12), const Color(0xFF1E88E5).withOpacity(0.06)],
            ),
          ),
          child: Column(
            children: [
              // Filtro de estado
              Container(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded, color: const Color(0xFF1565C0), size: context.responsiveIconSize(20)),
                    SizedBox(width: context.responsiveSpacing * 0.75),
                    Text(
                      'Estado:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: context.responsiveFontSize(14)),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.75),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _filtroEstado ?? 'Todos',
                        isExpanded: true,
                        underline: const SizedBox(),
                        style: TextStyle(fontSize: context.responsiveFontSize(14), fontWeight: FontWeight.w600),
                        items: _estadosDisponibles.map((e) => DropdownMenuItem(value: e, child: Text(_getEstadoTexto(e)))).toList(),
                        onChanged: (v) => setState(() { _filtroEstado = v == 'Todos' ? null : v; _aplicarFiltros(); }),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.responsiveSpacing),
              // Filtro de fechas
              isMobile
                  ? Column(
                      children: [
                        _buildFechaButton('Desde', _fechaInicio, _seleccionarFechaInicio),
                        SizedBox(height: context.responsiveSpacing * 0.75),
                        _buildFechaButton('Hasta', _fechaFin, _seleccionarFechaFin),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildFechaButton('Desde', _fechaInicio, _seleccionarFechaInicio)),
                        SizedBox(width: context.responsiveSpacing),
                        Expanded(child: _buildFechaButton('Hasta', _fechaFin, _seleccionarFechaFin)),
                      ],
                    ),
              if (_filtroEstado != null || _fechaInicio != null || _fechaFin != null) ...[
                SizedBox(height: context.responsiveSpacing),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_tutoriasFiltradas.length} de ${_todasTutorias.length} tutorías',
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(13),
                      color: const Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Lista de tutorías
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargarTutorias,
            color: const Color(0xFF1565C0),
            child: _isLoading
                ? _buildLoadingState()
                : _tutoriasFiltradas.isEmpty
                    ? _buildEmptyState('No hay tutorías', 'Intenta ajustar los filtros', Icons.event_busy_rounded)
                    : ListView.builder(
                        padding: EdgeInsets.all(padding),
                        itemCount: _tutoriasFiltradas.length,
                        itemBuilder: (context, index) => _buildTutoriaCard(_tutoriasFiltradas[index]),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildFechaButton(String label, DateTime? fecha, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(context.responsiveSpacing),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: context.responsiveIconSize(16), color: Colors.grey[600]),
                  SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(fontSize: context.responsiveFontSize(12), fontWeight: FontWeight.w600, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                fecha != null ? '${fecha.day}/${fecha.month}/${fecha.year}' : 'Seleccionar',
                style: TextStyle(fontSize: context.responsiveFontSize(14), fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: context.responsiveSpacing * 2),
          Text(
            'Cargando...',
            style: TextStyle(fontSize: context.responsiveFontSize(16), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.responsiveIconSize(90), color: Colors.grey[400]),
            SizedBox(height: context.responsiveSpacing * 2),
            Text(title, style: TextStyle(fontSize: context.responsiveFontSize(19), fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            SizedBox(height: context.responsiveSpacing * 0.75),
            Text(subtitle, style: TextStyle(fontSize: context.responsiveFontSize(14), color: Colors.grey[500]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTutoriaCard(Map<String, dynamic> tutoria) {
    final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;
    final estado = tutoria['estado'] as String;
    final puedeFinalizar = estado == 'confirmada';
    final puedeReagendar = estado == 'pendiente' || estado == 'confirmada';
    final puedeCancelar = estado == 'pendiente' || estado == 'confirmada';
    final padding = context.responsivePadding;
    final isMobile = context.isMobile;

    return Container(
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getEstadoColor(estado).withOpacity(0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 28,
                  backgroundImage: NetworkImage(
                    estudiante?['fotoPerfil'] ?? 'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                  ),
                ),
                SizedBox(width: context.responsiveSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                        style: TextStyle(fontSize: context.responsiveFontSize(16), fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isMobile) ...[
                        SizedBox(height: 4),
                        Text(
                          estudiante?['emailEstudiante'] ?? '',
                          style: TextStyle(fontSize: context.responsiveFontSize(13), color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_getEstadoColor(estado).withOpacity(0.15), _getEstadoColor(estado).withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getEstadoColor(estado), width: 1.5),
                  ),
                  child: Text(
                    _getEstadoTexto(estado),
                    style: TextStyle(
                      fontSize: context.responsiveFontSize(11),
                      fontWeight: FontWeight.w700,
                      color: _getEstadoColor(estado),
                    ),
                  ),
                ),
              ],
            ),

            Divider(height: context.responsiveSpacing * 2),

            // Información
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: context.responsiveIconSize(18), color: const Color(0xFF1565C0)),
                      SizedBox(width: context.responsiveSpacing * 0.75),
                      Text(_formatearFecha(tutoria['fecha']), style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.responsiveFontSize(14))),
                    ],
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.75),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: context.responsiveIconSize(18), color: Colors.green),
                      SizedBox(width: context.responsiveSpacing * 0.75),
                      Text('${tutoria['horaInicio']} - ${tutoria['horaFin']}', style: TextStyle(fontWeight: FontWeight.w600, fontSize: context.responsiveFontSize(14))),
                    ],
                  ),
                ],
              ),
            ),

            // Asistencia
            if (estado == 'finalizada' && tutoria['asistenciaEstudiante'] != null) ...[
              SizedBox(height: context.responsiveSpacing),
              Container(
                padding: EdgeInsets.all(context.responsiveSpacing),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tutoria['asistenciaEstudiante'] == true
                        ? [Colors.green[50]!, Colors.green[100]!.withOpacity(0.3)]
                        : [Colors.red[50]!, Colors.red[100]!.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tutoria['asistenciaEstudiante'] == true ? Colors.green : Colors.red, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(
                      tutoria['asistenciaEstudiante'] == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: tutoria['asistenciaEstudiante'] == true ? Colors.green[700] : Colors.red[700],
                      size: context.responsiveIconSize(24),
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.75),
                    Expanded(
                      child: Text(
                        tutoria['asistenciaEstudiante'] == true ? 'Estudiante asistió' : 'Estudiante NO asistió',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: context.responsiveFontSize(14),
                          color: tutoria['asistenciaEstudiante'] == true ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Botones de acción
            if (puedeFinalizar || puedeReagendar || puedeCancelar) ...[
              SizedBox(height: context.responsiveSpacing),
              isMobile
                  ? Column(
                      children: [
                        if (puedeFinalizar)
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton('Finalizar', Icons.check_circle_rounded, const Color(0xFF1565C0), () => _finalizarTutoria(tutoria), filled: true),
                          ),
                        if (puedeReagendar) ...[
                          if (puedeFinalizar) SizedBox(height: context.responsiveSpacing * 0.75),
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton('Reagendar', Icons.event_repeat_rounded, const Color(0xFF1565C0), () => _reagendarTutoria(tutoria)),
                          ),
                        ],
                        if (puedeCancelar) ...[
                          if (puedeFinalizar || puedeReagendar) SizedBox(height: context.responsiveSpacing * 0.75),
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton('Cancelar', Icons.cancel_rounded, Colors.red, () => _cancelarTutoria(tutoria['_id'])),
                          ),
                        ],
                      ],
                    )
                  : Wrap(
                      spacing: context.responsiveSpacing * 0.75,
                      runSpacing: context.responsiveSpacing * 0.75,
                      children: [
                        if (puedeFinalizar) _buildActionButton('Finalizar', Icons.check_circle_rounded, const Color(0xFF1565C0), () => _finalizarTutoria(tutoria), filled: true),
                        if (puedeReagendar) _buildActionButton('Reagendar', Icons.event_repeat_rounded, const Color(0xFF1565C0), () => _reagendarTutoria(tutoria)),
                        if (puedeCancelar) _buildActionButton('Cancelar', Icons.cancel_rounded, Colors.red, () => _cancelarTutoria(tutoria['_id'])),
                      ],
                    ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool filled = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: context.responsiveSpacing, vertical: context.responsiveSpacing * 0.75),
          decoration: BoxDecoration(
            gradient: filled ? LinearGradient(colors: [color.withOpacity(0.9), color]) : null,
            color: filled ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: context.responsiveIconSize(18), color: filled ? Colors.white : color),
              SizedBox(width: context.responsiveSpacing * 0.5),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : color,
                  fontWeight: FontWeight.w700,
                  fontSize: context.responsiveFontSize(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}