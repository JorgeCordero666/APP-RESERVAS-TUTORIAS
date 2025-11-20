// app_tesis/lib/pantallas/estudiante/reagendar_tutoria_dialog.dart
// ✅ VERSIÓN COMPLETAMENTE MEJORADA CON VALIDACIÓN DE MATERIA ESPECÍFICA

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

  // Disponibilidad
  bool _cargandoDisponibilidad = false;
  List<Map<String, dynamic>> _bloquesDisponibles = [];
  String? _error;

  // Días disponibles del docente
  Set<int> _diasDisponiblesDocente = {};
  bool _cargandoDias = true;
  
  // Materia identificada
  String? _materiaOriginal;

  @override
  void initState() {
    super.initState();

    // Validar si la tutoría ya pasó
    DateTime fechaTutoria;
    try {
      fechaTutoria = DateTime.parse(widget.tutoria['fecha']);
    } catch (e) {
      fechaTutoria = DateTime.now().add(const Duration(days: 1));
    }

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    // Si la fecha de la tutoría es anterior a hoy, usar el próximo día disponible
    if (fechaTutoria.isBefore(hoy)) {
      _fechaSeleccionada = null;
      print('⚠️ Tutoría pasada detectada. Se buscará próximo día disponible.');
    } else {
      _fechaSeleccionada = fechaTutoria;
    }

    _horaInicio = widget.tutoria['horaInicio'];
    _horaFin = widget.tutoria['horaFin'];

    // CRÍTICO: Cargar días disponibles PRIMERO
    _cargarDiasDisponiblesDocente();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  // ✅ Buscar el próximo día disponible del docente
  DateTime _buscarProximoDiaDisponible() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    // Buscar en los próximos 90 días
    for (int i = 1; i <= 90; i++) {
      final fecha = hoy.add(Duration(days: i));
      final diaSemana = fecha.weekday;
      
      if (_diasDisponiblesDocente.contains(diaSemana)) {
        return fecha;
      }
    }
    
    // Si no encuentra ninguno, devolver mañana (fallback)
    return hoy.add(const Duration(days: 1));
  }

  // ✅ MÉTODO MEJORADO: Identificar la materia original de forma robusta
  String? _identificarMateriaOriginal(
    Map<String, List<Map<String, dynamic>>> disponibilidad,
  ) {
    // PRIORIDAD 1: Buscar por bloqueDocenteId si existe
    if (widget.tutoria['bloqueDocenteId'] != null) {
      final bloqueId = widget.tutoria['bloqueDocenteId'];
      
      for (var entrada in disponibilidad.entries) {
        final materia = entrada.key;
        final bloques = entrada.value;
        
        for (var bloque in bloques) {
          if (bloque['_id'] == bloqueId) {
            print('✅ Materia encontrada por bloqueDocenteId: $materia');
            return materia;
          }
        }
      }
    }
    
    // PRIORIDAD 2: Buscar por coincidencia exacta de horario
    final fechaOriginal = DateTime.parse(widget.tutoria['fecha']);
    final diaOriginal = _obtenerDiaSemana(fechaOriginal);
    final horaInicioOriginal = widget.tutoria['horaInicio'];
    final horaFinOriginal = widget.tutoria['horaFin'];
    
    print('🔍 Buscando materia por horario:');
    print('   Día: $diaOriginal');
    print('   Hora: $horaInicioOriginal - $horaFinOriginal');
    
    // Lista de coincidencias (puede haber múltiples)
    List<String> materiasCoincidentes = [];
    
    for (var entrada in disponibilidad.entries) {
      final materia = entrada.key;
      final bloques = entrada.value;
      
      for (var bloque in bloques) {
        if (bloque['dia'] == diaOriginal) {
          final bloqueInicio = _convertirAMinutos(bloque['horaInicio']);
          final bloqueFin = _convertirAMinutos(bloque['horaFin']);
          final tutoriaInicio = _convertirAMinutos(horaInicioOriginal);
          final tutoriaFin = _convertirAMinutos(horaFinOriginal);
          
          // Verificar si el horario de la tutoría está contenido en el bloque
          if (tutoriaInicio >= bloqueInicio && tutoriaFin <= bloqueFin) {
            materiasCoincidentes.add(materia);
          }
        }
      }
    }
    
    if (materiasCoincidentes.isEmpty) {
      print('❌ No se encontró ninguna materia coincidente');
      return null;
    }
    
    if (materiasCoincidentes.length > 1) {
      print('⚠️ Múltiples materias coincidentes: ${materiasCoincidentes.join(", ")}');
      // Si hay múltiples, intentar usar el campo 'materia' de la tutoría como desempate
      if (widget.tutoria['materia'] != null) {
        final materiaTutoria = widget.tutoria['materia'];
        if (materiasCoincidentes.contains(materiaTutoria)) {
          print('✅ Usando materia del registro de tutoría: $materiaTutoria');
          return materiaTutoria;
        }
      }
    }
    
    print('✅ Materia identificada: ${materiasCoincidentes.first}');
    return materiasCoincidentes.first;
  }

  // ✅ Cargar días disponibles SOLO para la materia de la tutoría
  Future<void> _cargarDiasDisponiblesDocente() async {
    setState(() => _cargandoDias = true);

    try {
      final docenteId = widget.tutoria['docente']['_id'];

      print('📅 Cargando días disponibles del docente: $docenteId');

      // PASO 1: Obtener la disponibilidad COMPLETA del docente
      final disponibilidad = await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: docenteId,
      );

      if (disponibilidad == null || disponibilidad.isEmpty) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error = 'El docente no tiene disponibilidad registrada';
          });
        }
        return;
      }

      print('📚 Materias disponibles: ${disponibilidad.keys.join(", ")}');

      // PASO 2: Identificar la MATERIA ORIGINAL de la tutoría
      _materiaOriginal = _identificarMateriaOriginal(disponibilidad);

      if (_materiaOriginal == null) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error = 'No se pudo determinar la materia de esta tutoría. '
                     'Por favor, contacta al docente para reagendar.';
          });
        }
        return;
      }

      print('✅ Materia original de la tutoría: $_materiaOriginal');

      // PASO 3: Extraer SOLO los días de esa materia específica
      final bloquesMateria = disponibilidad[_materiaOriginal] ?? [];
      
      if (bloquesMateria.isEmpty) {
        if (mounted) {
          setState(() {
            _cargandoDias = false;
            _error = 'El docente no tiene disponibilidad para la materia "$_materiaOriginal"';
          });
        }
        return;
      }

      Set<String> diasDisponibles = {};

      for (var bloque in bloquesMateria) {
        diasDisponibles.add(bloque['dia']);
      }

      print('📅 Días disponibles para "$_materiaOriginal": ${diasDisponibles.join(", ")}');

      // PASO 4: Convertir nombres de días a números (1=Lunes, 7=Domingo)
      final mapaDias = {
        'Lunes': 1,
        'Martes': 2,
        'Miércoles': 3,
        'Jueves': 4,
        'Viernes': 5,
        'Sábado': 6,
        'Domingo': 7,
      };

      Set<int> diasNumericos = {};
      for (var dia in diasDisponibles) {
        if (mapaDias.containsKey(dia)) {
          diasNumericos.add(mapaDias[dia]!);
        }
      }

      if (mounted) {
        setState(() {
          _diasDisponiblesDocente = diasNumericos;
          _cargandoDias = false;
        });

        // Si la fecha seleccionada no es válida, buscar próximo día disponible
        if (_fechaSeleccionada == null || 
            _fechaSeleccionada!.isBefore(DateTime.now()) ||
            !_diasDisponiblesDocente.contains(_fechaSeleccionada!.weekday)) {
          _fechaSeleccionada = _buscarProximoDiaDisponible();
          print('📅 Usando próximo día disponible: $_fechaSeleccionada');
        }

        // Cargar disponibilidad del día inicial
        _cargarDisponibilidadDelDia();
      }
    } catch (e) {
      print('❌ Error cargando días disponibles: $e');
      if (mounted) {
        setState(() {
          _cargandoDias = false;
          _error = 'Error al cargar disponibilidad: $e';
        });
      }
    }
  }

  // ✅ Método auxiliar para convertir hora a minutos
  int _convertirAMinutos(String hora) {
    try {
      final partes = hora.split(':');
      final horas = int.parse(partes[0]);
      final minutos = int.parse(partes[1]);
      return horas * 60 + minutos;
    } catch (e) {
      print('⚠️ Error convirtiendo hora: $hora');
      return 0;
    }
  }

  // ✅ Obtener día de la semana en español
  String _obtenerDiaSemana(DateTime fecha) {
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    return dias[fecha.weekday - 1];
  }

  // ✅ Cargar bloques disponibles del día seleccionado SOLO DE LA MATERIA ORIGINAL
  Future<void> _cargarDisponibilidadDelDia() async {
    if (_fechaSeleccionada == null || _materiaOriginal == null) return;

    setState(() {
      _cargandoDisponibilidad = true;
      _error = null;
      _bloquesDisponibles = [];
    });

    try {
      final docenteId = widget.tutoria['docente']['_id'];

      const dias = [
        'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
      ];
      final diaSemana = dias[_fechaSeleccionada!.weekday - 1];

      print('🔍 Buscando disponibilidad para: $diaSemana en materia $_materiaOriginal');

      // Obtener disponibilidad completa
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

      // Extraer bloques SOLO de la materia original para el día seleccionado
      final bloquesMateria = disponibilidad[_materiaOriginal] ?? [];
      List<Map<String, dynamic>> bloquesDelDia = [];

      for (var bloque in bloquesMateria) {
        if (bloque['dia'] == diaSemana) {
          bloquesDelDia.add(bloque);
        }
      }

      print('📦 Bloques encontrados para $_materiaOriginal en $diaSemana: ${bloquesDelDia.length}');

      if (bloquesDelDia.isEmpty) {
        setState(() {
          _cargandoDisponibilidad = false;
          _bloquesDisponibles = [];
        });
        return;
      }

      // Verificar turnos ocupados
      final fechaStr = _fechaSeleccionada!.toIso8601String().split('T')[0];
      final bloquesOcupados = await TutoriaService.listarTutorias(
        incluirCanceladas: false,
      );

      final ocupadosEnFecha = bloquesOcupados.where((t) {
        return t['docente']['_id'] == docenteId &&
            t['fecha'] == fechaStr &&
            t['_id'] != widget.tutoria['_id'] &&
            (t['estado'] == 'pendiente' || t['estado'] == 'confirmada');
      }).toList();

      // Generar turnos de 20 minutos para cada bloque
      List<Map<String, dynamic>> turnosDisponibles = [];

      for (var bloque in bloquesDelDia) {
        final turnos = _generarTurnos20Min(
          bloque['horaInicio'],
          bloque['horaFin'],
        );

        for (var turno in turnos) {
          // Verificar si el turno está ocupado
          final ocupado = ocupadosEnFecha.any((tutoria) {
            return !(
              turno['horaFin'] <= tutoria['horaInicio'] ||
              turno['horaInicio'] >= tutoria['horaFin']
            );
          });

          if (!ocupado) {
            turnosDisponibles.add(turno);
          }
        }
      }

      setState(() {
        _bloquesDisponibles = turnosDisponibles;
        _cargandoDisponibilidad = false;

        // Validar si el horario actual sigue disponible
        final horarioActualDisponible = turnosDisponibles.any((t) =>
            t['horaInicio'] == _horaInicio && t['horaFin'] == _horaFin);

        if (!horarioActualDisponible) {
          _horaInicio = null;
          _horaFin = null;
        }
      });

      print('✅ Turnos disponibles para reagendar: ${turnosDisponibles.length}');
    } catch (e) {
      setState(() {
        _cargandoDisponibilidad = false;
        _error = 'Error al cargar disponibilidad: $e';
      });
    }
  }

  // ✅ Generar turnos de 20 minutos
  List<Map<String, dynamic>> _generarTurnos20Min(String inicio, String fin) {
    final convertirAMinutos = (String hora) {
      final partes = hora.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    };

    final formatearHora = (int minutos) {
      final horas = minutos ~/ 60;
      final mins = minutos % 60;
      return '${horas.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    };

    final minutosInicio = convertirAMinutos(inicio);
    final minutosFin = convertirAMinutos(fin);
    final duracionTurno = 20;

    List<Map<String, dynamic>> turnos = [];
    int actual = minutosInicio;

    while (actual + duracionTurno <= minutosFin) {
      turnos.add({
        'horaInicio': formatearHora(actual),
        'horaFin': formatearHora(actual + duracionTurno),
      });
      actual += duracionTurno;
    }

    return turnos;
  }

  // ✅ Selector de fecha con validación de días disponibles
  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    // Asegurar que initialDate sea válida (no anterior a hoy)
    DateTime fechaInicial;
    if (_fechaSeleccionada != null && !_fechaSeleccionada!.isBefore(hoy)) {
      fechaInicial = _fechaSeleccionada!;
    } else {
      fechaInicial = hoy.add(const Duration(days: 1));
    }

    final fecha = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: hoy,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es', 'ES'),
      // CRÍTICO: Solo permitir días en los que el docente tiene disponibilidad
      selectableDayPredicate: (DateTime date) {
        final diaSemana = date.weekday;
        return _diasDisponiblesDocente.contains(diaSemana);
      },
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

      _cargarDisponibilidadDelDia();
    }
  }

  // ✅ Reagendar con validaciones completas
  Future<void> _reagendar() async {
    if (_fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha');
      return;
    }

    if (_horaInicio == null || _horaFin == null) {
      _mostrarError('Selecciona un turno disponible');
      return;
    }

    // Validar que el turno sigue disponible
    final turnoValido = _bloquesDisponibles.any((t) =>
        t['horaInicio'] == _horaInicio && t['horaFin'] == _horaFin);

    if (!turnoValido) {
      _mostrarError('El turno seleccionado ya no está disponible');
      return;
    }

    // Validación: No reagendar a menos de 2 horas
    final fechaHoraNueva = DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      int.parse(_horaInicio!.split(':')[0]),
      int.parse(_horaInicio!.split(':')[1]),
    );

    final diferencia = fechaHoraNueva.difference(DateTime.now());

    if (diferencia.inHours < 2) {
      _mostrarError('Debes reagendar con al menos 2 horas de anticipación');
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
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    final dia = dias[fecha.weekday - 1];
    return '$dia ${fecha.day}/${fecha.month}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar loading mientras se cargan los días disponibles
    if (_cargandoDias) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Verificando disponibilidad del docente...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Mostrar error si no hay días disponibles
    if (_error != null && _diasDisponiblesDocente.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
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
              child: Row(
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
                              Icon(Icons.info_outline,
                                  color: Colors.orange[700], size: 20),
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
                          
                          // ✅ Mostrar materia identificada
                          if (_materiaOriginal != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.book, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Materia: $_materiaOriginal',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ] else if (widget.tutoria['materia'] != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.book, size: 16, color: Colors.orange),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Materia: ${widget.tutoria['materia']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                          ],
                          
                          Text(
                            '📅 ${widget.tutoria['fecha'] != null 
                                ? _formatearFecha(DateTime.parse(widget.tutoria['fecha'])) 
                                : 'Fecha no disponible'}',
                          ),
                          Text(
                            '🕐 ${widget.tutoria['horaInicio'] ?? '--:--'} - ${widget.tutoria['horaFin'] ?? '--:--'}',
                          ),
                          
                          // Advertencia si la fecha ya pasó
                          if (widget.tutoria['fecha'] != null &&
                              DateTime.parse(widget.tutoria['fecha'])
                                  .isBefore(DateTime.now())) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red, size: 16),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Esta fecha ya pasó. Selecciona una fecha futura.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
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
                            const Icon(Icons.calendar_today,
                                color: Color(0xFF1565C0)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Fecha',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
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

                    // Bloques disponibles
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
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber,
                                    color: Colors.orange, size: 24),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'No hay turnos disponibles para ${_formatearFecha(_fechaSeleccionada!)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'El docente no tiene horarios libres en este día para la materia "$_materiaOriginal". Por favor, elige otro día de la semana.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _seleccionarFecha,
                              icon: const Icon(Icons.calendar_today, size: 18),
                              label: const Text('Elegir otro día'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Turnos Disponibles (${_bloquesDisponibles.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // ✅ Badge indicando que son solo de la materia específica
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF1565C0).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _materiaOriginal ?? 'Materia',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._bloquesDisponibles.map((turno) {
                            final isSelected = _horaInicio == turno['horaInicio'] &&
                                _horaFin == turno['horaFin'];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _horaInicio = turno['horaInicio'];
                                    _horaFin = turno['horaFin'];
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
                                        '${turno['horaInicio']} - ${turno['horaFin']}',
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

            // Footer
            Container(
              padding: const EdgeInsets.all(20),
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
                            color: Colors.white,
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