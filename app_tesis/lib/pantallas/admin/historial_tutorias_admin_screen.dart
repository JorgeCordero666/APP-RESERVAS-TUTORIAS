// app_tesis/lib/pantallas/admin/historial_tutorias_admin_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
import 'package:intl/intl.dart';

class HistorialTutoriasAdminScreen extends StatefulWidget {
  final Usuario usuario;

  const HistorialTutoriasAdminScreen({super.key, required this.usuario});

  @override
  State<HistorialTutoriasAdminScreen> createState() =>
      _HistorialTutoriasAdminScreenState();
}

class _HistorialTutoriasAdminScreenState
    extends State<HistorialTutoriasAdminScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _tutorias = [];
  List<Map<String, dynamic>> _tutoriasFiltradas = [];
  
  final _searchController = TextEditingController();
  String _filtroEstado = 'Todas';
  
  final List<String> _estados = [
    'Todas',
    'pendiente',
    'confirmada',
    'finalizada',
    'cancelada_por_estudiante',
    'cancelada_por_docente',
    'rechazada',
    'expirada',
  ];

  @override
  void initState() {
    super.initState();
    _cargarTutorias();
    _searchController.addListener(_filtrarTutorias);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTutorias() async {
    setState(() => _isLoading = true);

    try {
      final tutorias = await TutoriaService.listarTodasTutoriasAdmin(
        incluirCanceladas: true,
      );

      setState(() {
        _tutorias = tutorias;
        _aplicarFiltros();
      });
    } catch (e) {
      _mostrarError('Error al cargar tutorías: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarTutorias() {
    _aplicarFiltros();
  }

  void _aplicarFiltros() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _tutoriasFiltradas = _tutorias.where((tutoria) {
        // Filtro por búsqueda
        final estudianteNombre = (tutoria['estudiante']?['nombreEstudiante'] ?? '')
            .toString()
            .toLowerCase();
        final docenteNombre = (tutoria['docente']?['nombreDocente'] ?? '')
            .toString()
            .toLowerCase();
        
        final cumpleBusqueda = query.isEmpty ||
            estudianteNombre.contains(query) ||
            docenteNombre.contains(query);

        // Filtro por estado
        final estadoTutoria = tutoria['estado']?.toString() ?? '';
        final cumpleEstado = _filtroEstado == 'Todas' ||
            estadoTutoria == _filtroEstado;

        return cumpleBusqueda && cumpleEstado;
      }).toList();

      // Ordenar por fecha descendente
      _tutoriasFiltradas.sort((a, b) {
        final fechaA = DateTime.parse(a['fecha'] ?? '2000-01-01');
        final fechaB = DateTime.parse(b['fecha'] ?? '2000-01-01');
        return fechaB.compareTo(fechaA);
      });
    });
  }

  void _cambiarFiltroEstado(String nuevoFiltro) {
    setState(() {
      _filtroEstado = nuevoFiltro;
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

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmada':
        return Colors.blue;
      case 'finalizada':
        return Colors.green;
      case 'cancelada_por_estudiante':
      case 'cancelada_por_docente':
        return Colors.red;
      case 'rechazada':
        return Colors.red.shade700;
      case 'expirada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTextoEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'confirmada':
        return 'Confirmada';
      case 'finalizada':
        return 'Finalizada';
      case 'cancelada_por_estudiante':
        return 'Cancelada (Est.)';
      case 'cancelada_por_docente':
        return 'Cancelada (Doc.)';
      case 'rechazada':
        return 'Rechazada';
      case 'expirada':
        return 'Expirada';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Tutorías (${_tutoriasFiltradas.length})'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTutorias,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarTutorias,
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por estudiante o docente',
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _estados.map((estado) {
                    final isSelected = _filtroEstado == estado;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(estado == 'Todas' ? estado : _getTextoEstado(estado)),
                        selected: isSelected,
                        onSelected: (_) => _cambiarFiltroEstado(estado),
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Lista de tutorías
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tutoriasFiltradas.isEmpty
                      ? _buildEstadoVacio()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tutoriasFiltradas.length,
                          itemBuilder: (context, index) {
                            final tutoria = _tutoriasFiltradas[index];
                            return _TutoriaCard(
                              tutoria: tutoria,
                              getColorEstado: _getColorEstado,
                              getTextoEstado: _getTextoEstado,
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
    if (_tutorias.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay tutorías registradas',
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
              'No se encontraron tutorías',
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

class _TutoriaCard extends StatelessWidget {
  final Map<String, dynamic> tutoria;
  final Color Function(String) getColorEstado;
  final String Function(String) getTextoEstado;

  const _TutoriaCard({
    required this.tutoria,
    required this.getColorEstado,
    required this.getTextoEstado,
  });

  @override
  Widget build(BuildContext context) {
    final estudiante = tutoria['estudiante'] ?? {};
    final docente = tutoria['docente'] ?? {};
    final estado = tutoria['estado']?.toString() ?? 'desconocido';
    final fecha = tutoria['fecha'] ?? '';
    final horaInicio = tutoria['horaInicio'] ?? '';
    final horaFin = tutoria['horaFin'] ?? '';

    // Formatear fecha
    String fechaFormateada = '';
    try {
      final date = DateTime.parse(fecha);
      fechaFormateada = DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      fechaFormateada = fecha;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tutoría #${tutoria['_id']?.toString().substring(0, 8) ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    getTextoEstado(estado),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: getColorEstado(estado),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
            
            const SizedBox(height: 12),

            // Información del estudiante
            Row(
              children: [
                const Icon(Icons.school, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estudiante['nombreEstudiante']?.toString() ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),

            // Información del docente
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    docente['nombreDocente']?.toString() ?? 'Sin nombre',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),

            // Fecha y horario
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  fechaFormateada,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 18, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  '$horaInicio - $horaFin',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),

            // Información adicional según estado
            if (tutoria['asistenciaEstudiante'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    tutoria['asistenciaEstudiante'] == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 18,
                    color: tutoria['asistenciaEstudiante'] == true
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tutoria['asistenciaEstudiante'] == true
                        ? 'Estudiante asistió'
                        : 'Estudiante no asistió',
                    style: TextStyle(
                      fontSize: 13,
                      color: tutoria['asistenciaEstudiante'] == true
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ],

            if (tutoria['motivoCancelacion'] != null &&
                tutoria['motivoCancelacion'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Motivo: ${tutoria['motivoCancelacion']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}