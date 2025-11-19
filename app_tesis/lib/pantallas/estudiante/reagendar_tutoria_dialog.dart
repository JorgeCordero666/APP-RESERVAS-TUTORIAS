// lib/pantallas/estudiante/reagendar_tutoria_dialog.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import '../../servicios/tutoria_service.dart';
import '../../servicios/horario_service.dart';

class ReagendarTutoriaDialog extends StatefulWidget {
  final Map<String, dynamic> tutoria;
  final String nombreDocente;

  const ReagendarTutoriaDialog({
    super.key,
    required this.tutoria,
    required this.nombreDocente,
  });

  @override
  State<ReagendarTutoriaDialog> createState() => _ReagendarTutoriaDialogState();
}

class _ReagendarTutoriaDialogState extends State<ReagendarTutoriaDialog> {
  DateTime? _fechaSeleccionada;
  String? _horaInicio;
  String? _horaFin;
  final _motivoController = TextEditingController();
  bool _isLoading = false;
  
  // ✅ NUEVO: Variables para disponibilidad
  bool _cargandoDisponibilidad = false;
  List<Map<String, dynamic>> _bloquesDisponibles = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Inicializar con la fecha actual de la tutoría
    try {
      _fechaSeleccionada = DateTime.parse(widget.tutoria['fecha']);
    } catch (e) {
      _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
    }
    
    _horaInicio = widget.tutoria['horaInicio'];
    _horaFin = widget.tutoria['horaFin'];
    
    // ✅ Cargar disponibilidad inicial
    _cargarDisponibilidadDelDia();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  // ✅ NUEVA FUNCIÓN: Cargar bloques disponibles del día seleccionado
  Future<void> _cargarDisponibilidadDelDia() async {
    if (_fechaSeleccionada == null) return;

    setState(() {
      _cargandoDisponibilidad = true;
      _error = null;
      _bloquesDisponibles = [];
    });

    try {
      final docenteId = widget.tutoria['docente']['_id'];
      
      // Obtener día de la semana
      const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
      final diaSemana = dias[_fechaSeleccionada!.weekday - 1];

      print('🔍 Cargando disponibilidad para: $diaSemana');

      // Obtener disponibilidad completa del docente
      final disponibilidad = await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: docenteId,
      );

      if (disponibilidad == null || disponibilidad.isEmpty) {
        setState(() {
          _cargandoDisponibilidad = false;
          _error = 'El docente no tiene disponibilidad registrada';
        });
        return;
      }

      // Extraer todos los bloques de todas las materias para ese día
      List<Map<String, dynamic>> bloquesDelDia = [];
      
      disponibilidad.forEach((materia, bloques) {
        for (var bloque in bloques) {
          if (bloque['dia'] == diaSemana) {
            bloquesDelDia.add(bloque);
          }
        }
      });

      // Verificar bloques ocupados en esa fecha
      final fechaStr = _fechaSeleccionada!.toIso8601String().split('T')[0];
      final bloquesOcupados = await TutoriaService.listarTutorias(
        incluirCanceladas: false,
      );

      // Filtrar bloques del mismo docente y fecha
      final ocupadosEnFecha = bloquesOcupados.where((t) {
        return t['docente']['_id'] == docenteId && 
               t['fecha'] == fechaStr &&
               t['_id'] != widget.tutoria['_id'] && // Excluir la tutoría actual
               (t['estado'] == 'pendiente' || t['estado'] == 'confirmada');
      }).toList();

      print('📊 Bloques disponibles: ${bloquesDelDia.length}');
      print('📊 Bloques ocupados: ${ocupadosEnFecha.length}');

      // Filtrar bloques disponibles (sin solapamiento)
      final disponibles = bloquesDelDia.where((bloque) {
        final bloqueOcupado = ocupadosEnFecha.any((tutoria) {
          return !(
            bloque['horaFin'] <= tutoria['horaInicio'] || 
            bloque['horaInicio'] >= tutoria['horaFin']
          );
        });
        return !bloqueOcupado;
      }).toList();

      setState(() {
        _bloquesDisponibles = disponibles;
        _cargandoDisponibilidad = false;
        
        // Si el horario actual no está disponible, limpiar selección
        if (_horaInicio != null && _horaFin != null) {
          final horarioActualDisponible = disponibles.any((b) =>
            b['horaInicio'] == _horaInicio && b['horaFin'] == _horaFin
          );
          
          if (!horarioActualDisponible) {
            _horaInicio = null;
            _horaFin = null;
          }
        }
      });

      print('✅ Bloques disponibles finales: ${_bloquesDisponibles.length}');

    } catch (e) {
      print('❌ Error cargando disponibilidad: $e');
      setState(() {
        _cargandoDisponibilidad = false;
        _error = 'Error al cargar disponibilidad: $e';
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
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

    if (fecha != null && mounted) {
      setState(() {
        _fechaSeleccionada = fecha;
        _horaInicio = null;
        _horaFin = null;
      });
      
      // ✅ Recargar disponibilidad del nuevo día
      _cargarDisponibilidadDelDia();
    }
  }

  Future<void> _reagendar() async {
    // Validaciones
    if (_fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha');
      return;
    }

    if (_horaInicio == null || _horaFin == null) {
      _mostrarError('Selecciona un bloque horario disponible');
      return;
    }

    // ✅ Validar que el horario esté en los bloques disponibles
    final bloqueValido = _bloquesDisponibles.any((b) =>
      b['horaInicio'] == _horaInicio && b['horaFin'] == _horaFin
    );

    if (!bloqueValido) {
      _mostrarError('El horario seleccionado ya no está disponible');
      return;
    }

    setState(() => _isLoading = true);

    final fechaFormateada = _fechaSeleccionada!.toIso8601String().split('T')[0];

    final resultado = await TutoriaService.reagendarTutoria(
      tutoriaId: widget.tutoria['_id'],
      nuevaFecha: fechaFormateada,
      nuevaHoraInicio: _horaInicio!,
      nuevaHoraFin: _horaFin!,
      motivo: _motivoController.text.isEmpty 
          ? 'Reagendada por el estudiante' 
          : _motivoController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
    } else {
      Navigator.pop(context, {'success': true});
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

  String _formatearFecha(DateTime fecha) {
    const dias = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final dia = dias[fecha.weekday - 1];
    return '$dia ${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_repeat, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Reagendar Tutoría',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.nombreDocente,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Horario actual
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Horario Actual',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('📅 ${_formatearFecha(DateTime.parse(widget.tutoria['fecha']))}'),
                          Text('🕐 ${widget.tutoria['horaInicio']} - ${widget.tutoria['horaFin']}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Nuevo Horario',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de fecha
                    InkWell(
                      onTap: _seleccionarFecha,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFF1565C0)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _fechaSeleccionada != null
                                        ? _formatearFecha(_fechaSeleccionada!)
                                        : 'Seleccionar fecha',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, size: 16),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ✅ NUEVO: Lista de bloques disponibles
                    if (_cargandoDisponibilidad)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(child: Text(_error!)),
                          ],
                        ),
                      )
                    else if (_bloquesDisponibles.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay bloques disponibles para este día',
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bloques Disponibles (${_bloquesDisponibles.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          ..._bloquesDisponibles.map((bloque) {
                            final isSelected = 
                              _horaInicio == bloque['horaInicio'] && 
                              _horaFin == bloque['horaFin'];
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _horaInicio = bloque['horaInicio'];
                                    _horaFin = bloque['horaFin'];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                      ? const Color(0xFF1565C0).withOpacity(0.1)
                                      : Colors.grey[50],
                                    border: Border.all(
                                      color: isSelected 
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected 
                                          ? Icons.check_circle 
                                          : Icons.schedule,
                                        color: isSelected 
                                          ? const Color(0xFF1565C0)
                                          : Colors.grey,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                        style: TextStyle(
                                          fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                          color: isSelected 
                                            ? const Color(0xFF1565C0)
                                            : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Motivo
                    TextField(
                      controller: _motivoController,
                      decoration: InputDecoration(
                        labelText: 'Motivo (opcional)',
                        hintText: 'Ejemplo: Tengo un compromiso académico',
                        prefixIcon: const Icon(Icons.comment),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botón
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_isLoading || _cargandoDisponibilidad || _horaInicio == null) 
                    ? null 
                    : _reagendar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _horaInicio == null 
                            ? 'Selecciona un horario' 
                            : 'Confirmar Reagendamiento',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}