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
  
  DateTime? _fechaInicio;  // ✅ Ahora puede ser null
  DateTime? _fechaFin;     // ✅ Ahora puede ser null
  
  @override
  void initState() {
    super.initState();
    // Por defecto: SIN FILTRO (todas las tutorías)
    _fechaFin = null;
    _fechaInicio = null;
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);

    try {
      // ✅ CAMBIO CRÍTICO: Solo enviar fechas si están definidas
      String? fechaInicioStr;
      String? fechaFinStr;
      
      if (_fechaInicio != null) {
        fechaInicioStr = DateFormat('yyyy-MM-dd').format(_fechaInicio!);
      }
      
      if (_fechaFin != null) {
        fechaFinStr = DateFormat('yyyy-MM-dd').format(_fechaFin!);
      }

      print('📊 Cargando reporte: ${fechaInicioStr ?? "SIN FILTRO"} a ${fechaFinStr ?? "SIN FILTRO"}');

      final resultado = await TutoriaService.generarReporteGeneralAdmin(
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );

      print('📦 Resultado recibido: ${resultado?.keys.join(", ")}');

      if (resultado != null && resultado.containsKey('error')) {
        print('❌ Error: ${resultado['error']}');
        _mostrarError(resultado['error']);
        setState(() => _reporteData = null);
      } else if (resultado != null) {
        print('✅ Datos cargados exitosamente');
        print('   Estadísticas: ${resultado['estadisticasGlobales']}');
        print('   Docentes: ${resultado['reportePorDocente']?.length ?? 0}');
        setState(() => _reporteData = resultado);
      } else {
        print('⚠️ Resultado es null');
        _mostrarError('No se recibieron datos del servidor');
        setState(() => _reporteData = null);
      }
    } catch (e) {
      print('❌ Exception: $e');
      _mostrarError('Error al cargar reporte: $e');
      setState(() => _reporteData = null);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _seleccionarFecha(BuildContext context, bool esInicio) async {
    final DateTime initialDate = esInicio 
        ? (_fechaInicio ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_fechaFin ?? DateTime.now());
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtros de Fecha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                // ✅ Botón para limpiar filtros
                if (_fechaInicio != null || _fechaFin != null)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _fechaInicio = null;
                        _fechaFin = null;
                      });
                      _cargarReporte();
                    },
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
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
                        _fechaInicio == null 
                            ? 'Todas' 
                            : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _fechaInicio == null ? Colors.grey : Colors.black,
                        ),
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
                        _fechaFin == null 
                            ? 'Todas' 
                            : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _fechaFin == null ? Colors.grey : Colors.black,
                        ),
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
    // Debug: Imprimir stats recibidos
    print('📊 Stats recibidos: $stats');
    
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
              (stats['totalTutorias'] ?? 0).toString(),
              Icons.event,
              Colors.blue,
            ),
            
            _buildStatRow(
              'Docentes',
              (stats['docentesActivos'] ?? 0).toString(),
              Icons.people,
              Colors.green,
            ),
            
            _buildStatRow(
              'Estudiantes',
              (stats['estudiantesUnicos'] ?? 0).toString(),
              Icons.school,
              Colors.orange,
            ),
            
            const Divider(height: 24),
            
            _buildStatRow(
              'Confirmadas',
              (stats['confirmadas'] ?? 0).toString(),
              Icons.check_circle,
              Colors.green,
            ),
            
            _buildStatRow(
              'Pendientes',
              (stats['pendientes'] ?? 0).toString(),
              Icons.pending,
              Colors.orange,
            ),
            
            _buildStatRow(
              'Finalizadas',
              (stats['finalizadas'] ?? 0).toString(),
              Icons.done_all,
              Colors.blue,
            ),
            
            _buildStatRow(
              'Canceladas',
              (stats['canceladas'] ?? 0).toString(),
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