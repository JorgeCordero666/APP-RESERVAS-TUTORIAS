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

class _ReagendarTutoriaDialogState extends State<ReagendarTutoriaDialog> 
    with SingleTickerProviderStateMixin {
  DateTime? _fechaSeleccionada;
  String? _horaInicio;
  String? _horaFin;
  final _motivoController = TextEditingController();
  bool _isLoading = false;

  bool _cargandoDisponibilidad = false;
  List<Map<String, dynamic>> _bloquesDisponibles = [];
  String? _error;

  Set<int> _diasDisponiblesDocente = {};
  bool _cargandoDias = true;
  
  String? _materiaOriginal;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();

    DateTime fechaTutoria;
    try {
      fechaTutoria = DateTime.parse(widget.tutoria['fecha']);
    } catch (e) {
      fechaTutoria = DateTime.now().add(const Duration(days: 1));
    }

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    if (fechaTutoria.isBefore(hoy)) {
      _fechaSeleccionada = null;
      print('⚠️ Tutoría pasada detectada. Se buscará próximo día disponible.');
    } else {
      _fechaSeleccionada = fechaTutoria;
    }

    _horaInicio = widget.tutoria['horaInicio'];
    _horaFin = widget.tutoria['horaFin'];

    _cargarDiasDisponiblesDocente();
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  DateTime _buscarProximoDiaDisponible() {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
    for (int i = 1; i <= 90; i++) {
      final fecha = hoy.add(Duration(days: i));
      final diaSemana = fecha.weekday;
      
      if (_diasDisponiblesDocente.contains(diaSemana)) {
        return fecha;
      }
    }
    
    return hoy.add(const Duration(days: 1));
  }

  String? _identificarMateriaOriginal(
    Map<String, List<Map<String, dynamic>>> disponibilidad,
  ) {
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
    
    final fechaOriginal = DateTime.parse(widget.tutoria['fecha']);
    final diaOriginal = _obtenerDiaSemana(fechaOriginal);
    final horaInicioOriginal = widget.tutoria['horaInicio'];
    final horaFinOriginal = widget.tutoria['horaFin'];
    
    print('🔍 Buscando materia por horario:');
    print('   Día: $diaOriginal');
    print('   Hora: $horaInicioOriginal - $horaFinOriginal');
    
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

  Future<void> _cargarDiasDisponiblesDocente() async {
    setState(() => _cargandoDias = true);

    try {
      final docenteId = widget.tutoria['docente']['_id'];
      print('📅 Cargando días disponibles del docente: $docenteId');

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

        if (_fechaSeleccionada == null || 
            _fechaSeleccionada!.isBefore(DateTime.now()) ||
            !_diasDisponiblesDocente.contains(_fechaSeleccionada!.weekday)) {
          _fechaSeleccionada = _buscarProximoDiaDisponible();
          print('📅 Usando próximo día disponible: $_fechaSeleccionada');
        }

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

  String _obtenerDiaSemana(DateTime fecha) {
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    return dias[fecha.weekday - 1];
  }

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

      List<Map<String, dynamic>> turnosDisponibles = [];

      for (var bloque in bloquesDelDia) {
        final turnos = _generarTurnos20Min(
          bloque['horaInicio'],
          bloque['horaFin'],
        );

        for (var turno in turnos) {
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

  List<Map<String, dynamic>> _generarTurnos20Min(String inicio, String fin) {
    int convertirAMinutos(String hora) {
      final partes = hora.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    }

    String formatearHora(int minutos) {
      final horas = minutos ~/ 60;
      final mins = minutos % 60;
      return '${horas.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
    }

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

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    
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
      selectableDayPredicate: (DateTime date) {
        final diaSemana = date.weekday;
        return _diasDisponiblesDocente.contains(diaSemana);
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
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

  Future<void> _reagendar() async {
    if (_fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha');
      return;
    }

    if (_horaInicio == null || _horaFin == null) {
      _mostrarError('Selecciona un turno disponible');
      return;
    }

    final turnoValido = _bloquesDisponibles.any((t) =>
        t['horaInicio'] == _horaInicio && t['horaFin'] == _horaFin);

    if (!turnoValido) {
      _mostrarError('El turno seleccionado ya no está disponible');
      return;
    }

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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
    if (_cargandoDias) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 24),
              const Text(
                'Verificando disponibilidad del docente...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _diasDisponiblesDocente.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline, size: 60, color: Colors.red[700]),
              ),
              const SizedBox(height: 20),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event_repeat,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[50]!, Colors.orange[100]!],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.orange[300]!, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Horario Actual',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            if (_materiaOriginal != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.book, size: 18, color: Colors.orange[700]),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Materia: $_materiaOriginal',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 16, color: Colors.orange[800]),
                                const SizedBox(width: 8),
                                Text(
                                  widget.tutoria['fecha'] != null 
                                    ? _formatearFecha(DateTime.parse(widget.tutoria['fecha'])) 
                                    : 'Fecha no disponible',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: Colors.orange[800]),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.tutoria['horaInicio'] ?? '--:--'} - ${widget.tutoria['horaFin'] ?? '--:--'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            
                            if (widget.tutoria['fecha'] != null &&
                                DateTime.parse(widget.tutoria['fecha'])
                                    .isBefore(DateTime.now())) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[300]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.red[700], size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Esta fecha ya pasó. Selecciona una fecha futura.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red[900],
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_calendar,
                              size: 20,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Nuevo Horario',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      InkWell(
                        onTap: _seleccionarFecha,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF1565C0),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fecha',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fechaSeleccionada != null
                                          ? _formatearFecha(_fechaSeleccionada!)
                                          : 'Seleccionar fecha',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_cargandoDisponibilidad)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Column(
                              children: [
                                CircularProgressIndicator(strokeWidth: 3),
                                SizedBox(height: 16),
                                Text(
                                  'Cargando turnos...',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red[900]),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_bloquesDisponibles.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.warning_amber, color: Colors.orange[700], size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'No hay turnos disponibles para ${_formatearFecha(_fechaSeleccionada!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'El docente no tiene horarios libres en este día para la materia "$_materiaOriginal".',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _seleccionarFecha,
                                  icon: const Icon(Icons.calendar_today, size: 18),
                                  label: const Text('Elegir otro día'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.blue[50]!, Colors.blue[100]!],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.schedule,
                                      size: 18,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Turnos Disponibles (${_bloquesDisponibles.length})',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1565C0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _materiaOriginal ?? 'Materia',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                  borderRadius: BorderRadius.circular(12),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF1565C0).withOpacity(0.15)
                                          : Colors.grey[50],
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1565C0)
                                            : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF1565C0)
                                                    .withOpacity(0.2),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF1565C0)
                                                : Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.schedule,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.green[700],
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            '${turno['horaInicio']} - ${turno['horaFin']}',
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? const Color(0xFF1565C0)
                                                  : Colors.black87,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: Color(0xFF1565C0),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: _motivoController,
                        decoration: InputDecoration(
                          labelText: 'Motivo (opcional)',
                          hintText: 'Ejemplo: Tengo un compromiso académico',
                          prefixIcon: Icon(Icons.comment, color: Colors.blue[700]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1565C0),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
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
                      disabledBackgroundColor: Colors.grey[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                _horaInicio == null
                                    ? 'Selecciona un horario'
                                    : 'Confirmar Reagendamiento',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}