// app_tesis/lib/pantallas/admin/reportes_admin_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';
import 'package:intl/intl.dart';

class ReportesAdminScreen extends StatefulWidget {
  final Usuario usuario;

  const ReportesAdminScreen({super.key, required this.usuario});

  @override
  State<ReportesAdminScreen> createState() => _ReportesAdminScreenState();
}

class _ReportesAdminScreenState extends State<ReportesAdminScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _reporteData;
  
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  
  @override
  void initState() {
    super.initState();
    // Por defecto: último mes
    _fechaFin = DateTime.now();
    _fechaInicio = DateTime.now().subtract(const Duration(days: 30));
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);

    try {
      final fechaInicioStr = DateFormat('yyyy-MM-dd').format(_fechaInicio!);
      final fechaFinStr = DateFormat('yyyy-MM-dd').format(_fechaFin!);

      final resultado = await TutoriaService.generarReporteGeneralAdmin(
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(resultado['error']);
        setState(() => _reporteData = null);
      } else {
        setState(() => _reporteData = resultado);
      }
    } catch (e) {
      _mostrarError('Error al cargar reporte: $e');
      setState(() => _reporteData = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio! : _fechaFin!,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
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

    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
      _cargarReporte();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes Generales'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReporte,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _cargarReporte,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reporteData == null
                ? _buildEstadoVacio()
                : _buildReporte(),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay datos de tutorías',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otro rango de fechas',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReporte() {
    final estadisticas = _reporteData!['estadisticasGlobales'] ?? {};
    final docentes = _reporteData!['reportePorDocente'] ?? {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Filtros de fecha
        _buildFiltrosFecha(),
        const SizedBox(height: 24),

        // Estadísticas globales
        _buildEstadisticasGlobales(estadisticas),
        const SizedBox(height: 24),

        // Reporte por docente
        _buildReportePorDocente(docentes),
      ],
    );
  }

  Widget _buildFiltrosFecha() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rango de Fechas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarFecha(context, true),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Desde',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _seleccionarFecha(context, false),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Hasta',
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(_fechaFin!),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasGlobales(Map<String, dynamic> stats) {
    return Card(
      elevation: 2,
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
            
            _buildStatRow(
              'Total de Tutorías',
              stats['totalTutorias']?.toString() ?? '0',
              Icons.event,
              Colors.blue,
            ),
            
            _buildStatRow(
              'Docentes Activos',
              stats['docentesActivos']?.toString() ?? '0',
              Icons.people,
              Colors.green,
            ),
            
            _buildStatRow(
              'Estudiantes Únicos',
              stats['estudiantesUnicos']?.toString() ?? '0',
              Icons.school,
              Colors.orange,
            ),
            
            const Divider(height: 24),
            
            _buildStatRow(
              'Confirmadas',
              stats['confirmadas']?.toString() ?? '0',
              Icons.check_circle,
              Colors.green,
            ),
            
            _buildStatRow(
              'Pendientes',
              stats['pendientes']?.toString() ?? '0',
              Icons.pending,
              Colors.orange,
            ),
            
            _buildStatRow(
              'Finalizadas',
              stats['finalizadas']?.toString() ?? '0',
              Icons.done_all,
              Colors.blue,
            ),
            
            _buildStatRow(
              'Canceladas',
              stats['canceladas']?.toString() ?? '0',
              Icons.cancel,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
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
      ),
    );
  }

  Widget _buildReportePorDocente(Map<String, dynamic> docentes) {
    if (docentes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reporte por Docente',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 16),
        
        ...docentes.entries.map((entry) {
          final nombreDocente = entry.key;
          final data = entry.value as Map<String, dynamic>;
          final stats = data['estadisticas'] ?? {};
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1565C0),
                child: Text(
                  nombreDocente[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                nombreDocente,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                '${stats['total'] ?? 0} tutorías',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMiniStatRow('Confirmadas', stats['confirmadas']),
                      _buildMiniStatRow('Pendientes', stats['pendientes']),
                      _buildMiniStatRow('Finalizadas', stats['finalizadas']),
                      _buildMiniStatRow('Canceladas', stats['canceladas']),
                      
                      if (stats['tasaAsistencia'] != null) ...[
                        const Divider(height: 16),
                        _buildMiniStatRow(
                          'Tasa de Asistencia',
                          stats['tasaAsistencia'],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMiniStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value?.toString() ?? '0',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}