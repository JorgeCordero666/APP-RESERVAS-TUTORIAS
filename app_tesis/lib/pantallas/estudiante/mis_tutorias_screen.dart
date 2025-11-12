// lib/pantallas/estudiante/mis_tutorias_screen.dart

import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/tutoria_service.dart';

class MisTutoriasScreen extends StatefulWidget {
  final Usuario usuario;

  const MisTutoriasScreen({super.key, required this.usuario});

  @override
  State<MisTutoriasScreen> createState() => _MisTutoriasScreenState();
}

class _MisTutoriasScreenState extends State<MisTutoriasScreen> {
  List<Map<String, dynamic>> _tutorias = [];
  bool _isLoading = true;
  String _filtroEstado = 'todas'; // todas, pendiente, confirmada, rechazada
  String _rangoTemporal = 'todas'; // todas, semana_actual, mes_actual

  @override
  void initState() {
    super.initState();
    _cargarTutorias();
  }


Future<void> _cargarTutorias() async {
  setState(() => _isLoading = true);
  
  try {
    print('🔄 Cargando tutorías del estudiante...');
    
    final tutorias = await TutoriaService.listarTutorias(
      incluirCanceladas: false,
      soloSemanaActual: _rangoTemporal == 'semana_actual',
    );
    
    print('📦 Tutorías recibidas: ${tutorias.length}');
    
    // Filtrar por mes si es necesario
    List<Map<String, dynamic>> tutoriasFiltradas = tutorias;
    if (_rangoTemporal == 'mes_actual') {
      final ahora = DateTime.now();
      final inicioMes = DateTime(ahora.year, ahora.month, 1);
      final finMes = DateTime(ahora.year, ahora.month + 1, 0);
      
      tutoriasFiltradas = tutorias.where((t) {
        try {
          final fecha = DateTime.parse(t['fecha']);
          return fecha.isAfter(inicioMes.subtract(const Duration(days: 1))) &&
                 fecha.isBefore(finMes.add(const Duration(days: 1)));
        } catch (e) {
          return false;
        }
      }).toList();
      
      print('📅 Tutorías filtradas por mes: ${tutoriasFiltradas.length}');
    }
    
    if (mounted) {
      setState(() {
        _tutorias = tutoriasFiltradas;
        _isLoading = false;
      });
      
      // Debug: Mostrar estados
      if (tutoriasFiltradas.isNotEmpty) {
        final estados = <String, int>{};
        for (var t in tutoriasFiltradas) {
          final estado = t['estado'] as String;
          estados[estado] = (estados[estado] ?? 0) + 1;
        }
        print('📊 Estados de tutorías: $estados');
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

  List<Map<String, dynamic>> _tutoriasFiltradas() {
    if (_filtroEstado == 'todas') {
      return _tutorias;
    }
    return _tutorias.where((t) => t['estado'] == _filtroEstado).toList();
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
        return 'CANCELADA POR DOCENTE';
      default:
        return estado.toUpperCase();
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

    setState(() => _isLoading = true);

    final resultado = await TutoriaService.cancelarTutoria(
      tutoriaId: tutoriaId,
      motivo: motivo.isEmpty ? 'Sin motivo especificado' : motivo,
      canceladaPor: 'Estudiante',
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      _mostrarExito('Tutoría cancelada exitosamente');
      _cargarTutorias();
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
        title: const Text('Mis Tutorías'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTutorias,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'todas', label: Text('Todas')),
                      ButtonSegment(value: 'pendiente', label: Text('Pendientes')),
                      ButtonSegment(value: 'confirmada', label: Text('Confirmadas')),
                    ],
                    selected: {_filtroEstado},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _filtroEstado = newSelection.first;
                      });
                    },
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
                  : _tutoriasFiltradas().isEmpty
                      ? Center(
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
                                'No tienes tutorías ${_filtroEstado == "todas" ? "" : _filtroEstado}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _tutoriasFiltradas().length,
                          itemBuilder: (context, index) {
                            final tutoria = _tutoriasFiltradas()[index];
                            final docente = tutoria['docente'] as Map<String, dynamic>?;
                            final estado = tutoria['estado'] as String;
                            
                            // ✅ CORRECCIÓN: Variable sin espacio
                            final puedeCancelar = estado == 'pendiente' || estado == 'confirmada';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              elevation: 3,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header con docente y estado
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

                                    // Información de fecha y hora
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatearFecha(tutoria['fecha']),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${tutoria['horaInicio']} - ${tutoria['horaFin']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),

                                    // Motivo de rechazo si aplica
                                    if (estado == 'rechazada' && tutoria['motivoRechazo'] != null) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.info_outline, color: Colors.red, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Motivo: ${tutoria['motivoRechazo']}',
                                                style: const TextStyle(fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    // Botón de cancelar
                                    // ✅ CORRECCIÓN: Variable sin espacio
                                    if (puedeCancelar) ...[
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          onPressed: () => _cancelarTutoria(tutoria['_id']),
                                          icon: const Icon(Icons.cancel, size: 18),
                                          label: const Text('Cancelar Tutoría'),
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
                                  ],
                                ),
                              ),
                            );
                          },
                        )
            ),
          ),
        ],
      ),
    );
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
}