// lib/pantallas/docente/reportes_screen.dart - VERSIÓN MEJORADA
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
    
    // Filtrar por estado
    if (_filtroEstado != null && _filtroEstado != 'Todos') {
      resultado = resultado.where((t) => t['estado'] == _filtroEstado).toList();
    }
    
    // Filtrar por rango de fechas
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, cancelar'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Tutorías'),
        backgroundColor: const Color(0xFF1565C0),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        actions: [
          if (_tabIndex == 1 && (_filtroEstado != null || _fechaInicio != null || _fechaFin != null))
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              onPressed: _limpiarFiltros,
              tooltip: 'Limpiar filtros',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTutorias,
            tooltip: 'Actualizar',
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
      return const Center(child: CircularProgressIndicator());
    }

    final stats = _calcularEstadisticas();
    final tasaAsistencia = stats['finalizadas']! > 0
        ? ((stats['asistencias']! / stats['finalizadas']!) * 100).toStringAsFixed(1)
        : 'N/A';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen general
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resumen General',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatRow('Total de Tutorías', '${stats['total']}', Icons.event_note, Colors.blue),
                const Divider(),
                _buildStatRow('Pendientes', '${stats['pendientes']}', Icons.pending, Colors.orange),
                const Divider(),
                _buildStatRow('Confirmadas', '${stats['confirmadas']}', Icons.check_circle, Colors.green),
                const Divider(),
                _buildStatRow('Finalizadas', '${stats['finalizadas']}', Icons.done_all, Colors.blue),
                const Divider(),
                _buildStatRow('Canceladas', '${stats['canceladas']}', Icons.cancel, Colors.red),
                const Divider(),
                _buildStatRow('Rechazadas', '${stats['rechazadas']}', Icons.block, Colors.red),
                const Divider(),
                _buildStatRow('Asistencias', '${stats['asistencias']}', Icons.check, Colors.teal),
                const Divider(),
                _buildStatRow('Inasistencias', '${stats['inasistencias']}', Icons.close, Colors.red),
                const Divider(),
                _buildStatRow('Tasa de Asistencia', '$tasaAsistencia%', Icons.percent, Colors.indigo),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorialTab() {
    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Column(
            children: [
              // Filtro de estado
              Row(
                children: [
                  const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _filtroEstado ?? 'Todos',
                      isExpanded: true,
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
              const SizedBox(height: 12),
              // Filtro de fechas
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarFechaInicio,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Desde', style: TextStyle(fontSize: 12)),
                            Text(
                              _fechaInicio != null
                                  ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                  : 'Seleccionar',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _seleccionarFechaFin,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Hasta', style: TextStyle(fontSize: 12)),
                            Text(
                              _fechaFin != null
                                  ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                                  : 'Hoy',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_filtroEstado != null || _fechaInicio != null || _fechaFin != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_tutoriasFiltradas.length} de ${_todasTutorias.length} tutorías',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay tutorías con estos filtros',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
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
    final estudiante = tutoria['estudiante'] as Map<String, dynamic>?;
    final estado = tutoria['estado'] as String;
    final puedeFinalizar = estado == 'confirmada';
    final puedeReagendar = estado == 'pendiente' || estado == 'confirmada';
    final puedeCancelar = estado == 'pendiente' || estado == 'confirmada';

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
                    estudiante?['fotoPerfil'] ??
                        'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estudiante?['nombreEstudiante'] ?? 'Sin nombre',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        estudiante?['emailEstudiante'] ?? '',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(estado).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getEstadoColor(estado), width: 1.5),
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
              ],
            ),

            // Asistencia (si está finalizada)
            if (estado == 'finalizada' && tutoria['asistenciaEstudiante'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tutoria['asistenciaEstudiante'] == true
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: tutoria['asistenciaEstudiante'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tutoria['asistenciaEstudiante'] == true
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: tutoria['asistenciaEstudiante'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tutoria['asistenciaEstudiante'] == true
                          ? 'Estudiante asistió'
                          : 'Estudiante NO asistió',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tutoria['asistenciaEstudiante'] == true
                            ? Colors.green[700]
                            : Colors.red[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (tutoria['observacionesDocente'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Observaciones:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tutoria['observacionesDocente'],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            // Botones de acción
            if (puedeFinalizar || puedeReagendar || puedeCancelar) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (puedeFinalizar)
                    ElevatedButton.icon(
                      onPressed: () => _finalizarTutoria(tutoria),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                    ),
                  if (puedeReagendar)
                    OutlinedButton.icon(
                      onPressed: () => _reagendarTutoria(tutoria),
                      icon: const Icon(Icons.event_repeat, size: 18),
                      label: const Text('Reagendar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                      ),
                    ),
                  if (puedeCancelar)
                    OutlinedButton.icon(
                      onPressed: () => _cancelarTutoria(tutoria['_id']),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancelar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
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