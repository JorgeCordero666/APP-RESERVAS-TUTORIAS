// =====================================================
// 📊 PANTALLA DE REPORTES PARA DOCENTES
// lib/pantallas/docente/reportes_screen.dart
// =====================================================

import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';

class ReportesScreen extends StatefulWidget {
  final Usuario usuario;

  const ReportesScreen({super.key, required this.usuario});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _reporteData;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);

    try {
      final fechaInicioStr = _fechaInicio?.toIso8601String().split('T')[0];
      final fechaFinStr = _fechaFin?.toIso8601String().split('T')[0];

      final resultado = await TutoriaService.generarReportePorMaterias(
        fechaInicio: fechaInicioStr,
        fechaFin: fechaFinStr,
      );

      if (mounted) {
        setState(() {
          _reporteData = resultado;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarError('Error al cargar reporte: $e');
      }
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
      setState(() => _fechaInicio = fecha);
      _cargarReporte();
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
      setState(() => _fechaFin = fecha);
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
        title: const Text('Reportes de Tutorías'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReporte,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros de fecha
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Período del Reporte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 12),
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
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Desde',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _fechaInicio != null
                                          ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                                          : 'Seleccionar',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
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
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hasta',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _fechaFin != null
                                          ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                                          : 'Hoy',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
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
            ),
          ),

          // Contenido del reporte
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reporteData == null
                    ? const Center(
                        child: Text('No hay datos disponibles'),
                      )
                    : _buildReporteContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildReporteContent() {
    final estadisticasGlobales = _reporteData!['estadisticasGlobales'] as Map<String, dynamic>?;
    final reportePorMateria = _reporteData!['reportePorMateria'] as Map<String, dynamic>?;

    if (estadisticasGlobales == null || reportePorMateria == null) {
      return const Center(child: Text('No hay datos en el reporte'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen global
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
                _buildStatRow(
                  'Total de Tutorías',
                  '${estadisticasGlobales['totalTutorias']}',
                  Icons.event_note,
                  Colors.blue,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  'Materias Activas',
                  '${estadisticasGlobales['materiasActivas']}',
                  Icons.book,
                  Colors.green,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Reporte por materia
        const Text(
          'Detalle por Materia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),

        ...reportePorMateria.entries.map((entry) {
          final materia = entry.key;
          final datos = entry.value as Map<String, dynamic>;
          final stats = datos['estadisticas'] as Map<String, dynamic>;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                materia,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Total: ${stats['total']} tutorías',
                style: TextStyle(color: Colors.grey[600]),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'Pendientes',
                        '${stats['pendientes']}',
                        Icons.pending,
                        Colors.orange,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Confirmadas',
                        '${stats['confirmadas']}',
                        Icons.check_circle,
                        Colors.green,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Finalizadas',
                        '${stats['finalizadas']}',
                        Icons.done_all,
                        Colors.blue,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Canceladas',
                        '${stats['canceladas']}',
                        Icons.cancel,
                        Colors.red,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Reagendadas',
                        '${stats['reagendadas']}',
                        Icons.update,
                        Colors.purple,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Asistencias',
                        '${stats['asistencias']}',
                        Icons.check,
                        Colors.teal,
                      ),
                      const Divider(),
                      _buildStatRow(
                        'Tasa de Asistencia',
                        stats['tasaAsistencia'] ?? 'N/A',
                        Icons.percent,
                        Colors.indigo,
                      ),
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
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
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
    );
  }
}

// =====================================================
// 📋 AGREGAR AL HOME_SCREEN (Dashboard Docente)
// Reemplazar el método _buildDashboardDocente en home_screen.dart
// =====================================================

/*
Widget _buildDashboardDocente() {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Panel Docente'),
      backgroundColor: const Color(0xFF1565C0),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: _logout,
          tooltip: 'Cerrar sesión',
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _cargarUsuarioActualizado,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 24),
          
          _buildQuickAccessCard(
            title: 'Mis Materias',
            subtitle: 'Gestionar materias asignadas',
            icon: Icons.book,
            color: Colors.orange,
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 16),
          
          _buildQuickAccessCard(
            title: 'Horarios de Atención',
            subtitle: 'Configurar disponibilidad',
            icon: Icons.schedule,
            color: Colors.purple,
            onTap: () => setState(() => _selectedIndex = 2),
          ),
          const SizedBox(height: 16),
          
          _buildQuickAccessCard(
            title: 'Solicitudes Pendientes',
            subtitle: 'Gestionar tutorías solicitadas',
            icon: Icons.notifications_active,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SolicitudesTutoriasScreen(usuario: _usuario),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // ✅ NUEVO: Botón de Reportes
          _buildQuickAccessCard(
            title: 'Reportes de Tutorías',
            subtitle: 'Ver estadísticas por materia',
            icon: Icons.analytics,
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportesScreen(usuario: _usuario),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
*/
