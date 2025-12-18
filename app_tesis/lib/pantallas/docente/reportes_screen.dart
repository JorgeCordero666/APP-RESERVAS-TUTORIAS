import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
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
    'Todos',
    'pendiente',
    'confirmada',
    'finalizada',
    'cancelada_por_estudiante',
    'cancelada_por_docente',
    'rechazada',
  ];
  
  final List<String> _tabs = ['Estadísticas', 'Historial Completo'];
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _tabIndex = _tabController.index;
        });
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
      print('🔄 Cargando todas las tutorías del docente');
      
      final resultado = await TutoriaService.obtenerHistorialTutorias(
        incluirCanceladas: true,
        limit: 200,
      );
      
      if (resultado != null && !resultado.containsKey('error')) {
        final tutorias = List<Map<String, dynamic>>.from(
          resultado['tutorias'] ?? []
        );
        
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
      print('❌ Error cargando tutorías: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar tutorías: $e');
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
        
        if (_fechaInicio != null) {
          cumple = cumple && fecha.isAfter(_fechaInicio!.subtract(const Duration(days: 1)));
        }
        
        if (_fechaFin != null) {
          cumple = cumple && fecha.isBefore(_fechaFin!.add(const Duration(days: 1)));
        }
        
        return cumple;
      }).toList();
    }
    
    _tutoriasFiltradas = resultado;
    print('📊 Total: ${_todasTutorias.length}, Filtradas: ${_tutoriasFiltradas.length}');
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.cancel_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Cancelar Tutoría',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¿Estás seguro de cancelar esta tutoría?',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo (opcional)',
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'No',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, motivoController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sí, cancelar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (motivo == null) return;

    final resultado = await TutoriaService.cancelarTutoria(
      tutoriaId: tutoriaId,
      motivo: motivo.isEmpty ? 'Sin motivo especificado' : motivo,
      canceladaPor: 'Docente',
    );

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría cancelada exitosamente');
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

    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
        _aplicarFiltros();
      });
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
        _aplicarFiltros();
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _filtroEstado = null;
      _fechaInicio = null;
      _fechaFin = null;
      _aplicarFiltros();
    });
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        elevation: 6,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        elevation: 6,
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
        return 'CANCELADA POR MÍ';
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

  Map<String, int> _calcularEstadisticas() {
    final stats = {
      'total': _todasTutorias.length,
      'pendientes': 0,
      'confirmadas': 0,
      'finalizadas': 0,
      'canceladas': 0,
      'rechazadas': 0,
      'asistencias': 0,
      'inasistencias': 0,
    };

    for (var t in _todasTutorias) {
      final estado = t['estado'] as String;
      
      if (estado == 'pendiente') stats['pendientes'] = stats['pendientes']! + 1;
      if (estado == 'confirmada') stats['confirmadas'] = stats['confirmadas']! + 1;
      if (estado == 'finalizada') stats['finalizadas'] = stats['finalizadas']! + 1;
      if (estado == 'rechazada') stats['rechazadas'] = stats['rechazadas']! + 1;
      if (estado == 'cancelada_por_estudiante' || estado == 'cancelada_por_docente') {
        stats['canceladas'] = stats['canceladas']! + 1;
      }
      
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
      final nombreEstudiante = estudiante['nombreEstudiante'] as String? ?? 'Sin nombre';
      final emailEstudiante = estudiante['emailEstudiante'] as String? ?? '';
      final fotoPerfil = estudiante['fotoPerfil'] as String?;
      final estado = tutoria['estado'] as String;
      
      if (!estudiantesStats.containsKey(estudianteId)) {
        estudiantesStats[estudianteId] = {
          'nombre': nombreEstudiante,
          'email': emailEstudiante,
          'fotoPerfil': fotoPerfil,
          'total': 0,
          'pendientes': 0,
          'confirmadas': 0,
          'finalizadas': 0,
          'canceladas': 0,
          'rechazadas': 0,
          'asistencias': 0,
          'inasistencias': 0,
        };
      }
      
      final stats = estudiantesStats[estudianteId]!;
      stats['total'] = (stats['total'] as int) + 1;
      
      if (estado == 'pendiente') stats['pendientes'] = (stats['pendientes'] as int) + 1;
      if (estado == 'confirmada') stats['confirmadas'] = (stats['confirmadas'] as int) + 1;
      if (estado == 'finalizada') stats['finalizadas'] = (stats['finalizadas'] as int) + 1;
      if (estado == 'rechazada') stats['rechazadas'] = (stats['rechazadas'] as int) + 1;
      if (estado == 'cancelada_por_estudiante' || estado == 'cancelada_por_docente') {
        stats['canceladas'] = (stats['canceladas'] as int) + 1;
      }
      
      if (tutoria['asistenciaEstudiante'] == true) {
        stats['asistencias'] = (stats['asistencias'] as int) + 1;
      }
      if (tutoria['asistenciaEstudiante'] == false) {
        stats['inasistencias'] = (stats['inasistencias'] as int) + 1;
      }
    }
    
    return estudiantesStats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Reportes de Tutorías',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        actions: [
          if (_tabIndex == 1 && (_filtroEstado != null || _fechaInicio != null || _fechaFin != null))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.filter_alt_off_rounded, color: Colors.white),
                  onPressed: _limpiarFiltros,
                  tooltip: 'Limpiar filtros',
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _cargarTutorias,
                tooltip: 'Actualizar',
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEstadisticasTab(),
          _buildHistorialTab(),
        ],
      ),
    );
  }

  Widget _buildEstadisticasTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Cargando estadísticas...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A5F),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      );
    }

    final stats = _calcularEstadisticas();
    final tasaAsistencia = stats['finalizadas']! > 0
        ? ((stats['asistencias']! / stats['finalizadas']!) * 100).toStringAsFixed(1)
        : 'N/A';

    final estudiantesStats = _calcularEstadisticasPorEstudiante();
    final estudiantesLista = estudiantesStats.entries.toList()
      ..sort((a, b) => (b.value['total'] as int).compareTo(a.value['total'] as int));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Resumen General
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Resumen General',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A5F),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStatRow('Total de Tutorías', '${stats['total']}', Icons.event_note_rounded, Colors.blue),
                const Divider(height: 28),
                _buildStatRow('Pendientes', '${stats['pendientes']}', Icons.pending_rounded, Colors.orange),
                const Divider(height: 28),
                _buildStatRow('Confirmadas', '${stats['confirmadas']}', Icons.check_circle_rounded, Colors.green),
                const Divider(height: 28),
                _buildStatRow('Finalizadas', '${stats['finalizadas']}', Icons.done_all_rounded, Colors.blue),
                const Divider(height: 28),
                _buildStatRow('Canceladas', '${stats['canceladas']}', Icons.cancel_rounded, Colors.red),
                const Divider(height: 28),
                _buildStatRow('Rechazadas', '${stats['rechazadas']}', Icons.block_rounded, Colors.red),
                const Divider(height: 28),
                _buildStatRow('Asistencias', '${stats['asistencias']}', Icons.check_rounded, Colors.teal),
                const Divider(height: 28),
                _buildStatRow('Inasistencias', '${stats['inasistencias']}', Icons.close_rounded, Colors.red),
                const Divider(height: 28),
                _buildStatRow('Tasa de Asistencia', '$tasaAsistencia%', Icons.percent_rounded, Colors.indigo),
              ],
            ),
          ),
        ),

        // Estadísticas por Estudiante
        if (estudiantesLista.isNotEmpty) ...[
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF42A5F5).withOpacity(0.1),
                  const Color(0xFF1E88E5).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Estadísticas por Estudiante',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E3A5F),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${estudiantesLista.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'estudiantes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1565C0).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...estudiantesLista.map((entry) {
            final stats = entry.value;
            final tasaAsistencia = (stats['finalizadas'] as int) > 0
                ? (((stats['asistencias'] as int) / (stats['finalizadas'] as int)) * 100).toStringAsFixed(1)
                : 'N/A';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF1565C0).withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              stats['fotoPerfil'] ?? 'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stats['nombre'] as String,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E3A5F),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stats['email'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1565C0).withOpacity(0.15),
                                const Color(0xFF1565C0).withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1565C0),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${stats['total']} tutorías',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1565C0),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat('Pendientes', '${stats['pendientes']}', Colors.orange),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat('Confirmadas', '${stats['confirmadas']}', Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat('Finalizadas', '${stats['finalizadas']}', Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat('Canceladas', '${stats['canceladas']}', Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat('Rechazadas', '${stats['rechazadas']}', Colors.red[300]!),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMiniStat('Asistencia', tasaAsistencia, Colors.indigo),
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.2,
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
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
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialTab() {
    return Column(
      children: [
        // Filtros mejorados
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF42A5F5).withOpacity(0.12),
                const Color(0xFF1E88E5).withOpacity(0.06),
              ],
            ),
          ),
          child: Column(
            children: [
              // Filtro de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Color(0xFF1565C0),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Estado:',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _filtroEstado ?? 'Todos',
                        isExpanded: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down_rounded),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A5F),
                        ),
                        items: _estadosDisponibles.map((estado) {
                          return DropdownMenuItem(
                            value: estado,
                            child: Text(_getEstadoTexto(estado)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _filtroEstado = value == 'Todos' ? null : value;
                            _aplicarFiltros();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Filtro de fechas
              Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _seleccionarFechaInicio,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Desde',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _fechaInicio != null
                                    ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                    : 'Seleccionar',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _seleccionarFechaFin,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Hasta',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _fechaFin != null
                                    ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                                    : 'Hoy',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_filtroEstado != null || _fechaInicio != null || _fechaFin != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_tutoriasFiltradas.length} de ${_todasTutorias.length} tutorías',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
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
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Cargando tutorías...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A5F),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                : _tutoriasFiltradas.isEmpty
                    ? _buildEmptyState()
                    : _buildListaTutorias(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[100]!,
                    Colors.grey[50]!,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 90,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'No hay tutorías con estos filtros',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Colors.grey[700],
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Intenta ajustar los filtros de búsqueda',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaTutorias() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _tutoriasFiltradas.length,
      itemBuilder: (context, index) {
        final tutoria = _tutoriasFiltradas[index];
        return _buildTutoriaCard(tutoria);
      },
    );
  }

  Widget _buildTutoriaCard(Map<String, dynamic> tutoria) {
    final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;
    final estado = tutoria['estado'] as String;
    final puedeFinalizar = estado == 'confirmada';
    final puedeReagendar = estado == 'pendiente' || estado == 'confirmada';
    final puedeCancelar = estado == 'pendiente' || estado == 'confirmada';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getEstadoColor(estado).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mejorado
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getEstadoColor(estado).withOpacity(0.3),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getEstadoColor(estado).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(
                      estudiante?['fotoPerfil'] ??
                          'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A5F),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estudiante?['emailEstudiante'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getEstadoColor(estado).withOpacity(0.15),
                        _getEstadoColor(estado).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getEstadoColor(estado),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _getEstadoTexto(estado),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _getEstadoColor(estado),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 28),

            // Información mejorada
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[100]!,
                              Colors.blue[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatearFecha(tutoria['fecha']),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.2,
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
                          gradient: LinearGradient(
                            colors: [
                              Colors.green[100]!,
                              Colors.green[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${tutoria['horaInicio']} - ${tutoria['horaFin']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Asistencia (si está finalizada)
            if (estado == 'finalizada' && tutoria['asistenciaEstudiante'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: tutoria['asistenciaEstudiante'] == true
                        ? [Colors.green[50]!, Colors.green[100]!.withOpacity(0.3)]
                        : [Colors.red[50]!, Colors.red[100]!.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: tutoria['asistenciaEstudiante'] == true
                        ? Colors.green
                        : Colors.red,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tutoria['asistenciaEstudiante'] == true
                            ? Colors.green[100]
                            : Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        tutoria['asistenciaEstudiante'] == true
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: tutoria['asistenciaEstudiante'] == true
                            ? Colors.green[700]
                            : Colors.red[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tutoria['asistenciaEstudiante'] == true
                            ? 'Estudiante asistió'
                            : 'Estudiante NO asistió',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: tutoria['asistenciaEstudiante'] == true
                              ? Colors.green[700]
                              : Colors.red[700],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (tutoria['observacionesDocente'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[50]!,
                        Colors.blue[100]!.withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.blue[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.note_rounded,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Observaciones:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.blue[700],
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tutoria['observacionesDocente'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Botones de acción mejorados
            if (puedeFinalizar || puedeReagendar || puedeCancelar) ...[
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (puedeFinalizar)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _finalizarTutoria(tutoria),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Finalizar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (puedeReagendar)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _reagendarTutoria(tutoria),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF1565C0), width: 2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_repeat_rounded, size: 18, color: Color(0xFF1565C0)),
                              SizedBox(width: 8),
                              Text(
                                'Reagendar',
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (puedeCancelar)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _cancelarTutoria(tutoria['_id']),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red, width: 2),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
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
}