// lib/pantallas/estudiante/reagendar_tutoria_dialog.dart
import 'package:flutter/material.dart';
import '../../servicios/tutoria_service.dart';

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

  // ✅ GENERAR HORAS DINÁMICAMENTE (intervalos de 20 minutos)
  late final List<String> _horasDisponibles;

  @override
  void initState() {
    super.initState();
    
    // ✅ Generar lista de horas al inicializar
    _horasDisponibles = _generarHorasDisponibles();
    
    // Inicializar con la fecha actual de la tutoría
    try {
      _fechaSeleccionada = DateTime.parse(widget.tutoria['fecha']);
    } catch (e) {
      _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
    }
    
    _horaInicio = widget.tutoria['horaInicio'];
    _horaFin = widget.tutoria['horaFin'];
    
    // ✅ VALIDAR que las horas existan en la lista generada
    if (_horaInicio != null && !_horasDisponibles.contains(_horaInicio)) {
      print('⚠️ Hora inicio no válida: $_horaInicio, usando primera disponible');
      _horaInicio = _horasDisponibles.first;
    }
    
    if (_horaFin != null && !_horasDisponibles.contains(_horaFin)) {
      print('⚠️ Hora fin no válida: $_horaFin, calculando desde inicio');
      _horaFin = _calcularHoraFin(_horaInicio ?? _horasDisponibles.first);
    }
  }

  // ✅ FUNCIÓN PARA GENERAR HORAS (7:00 - 21:00, cada 20 min)
  List<String> _generarHorasDisponibles() {
    final List<String> horas = [];
    
    for (int hora = 7; hora <= 21; hora++) {
      for (int minuto = 0; minuto < 60; minuto += 20) {
        final horaStr = hora.toString().padLeft(2, '0');
        final minutoStr = minuto.toString().padLeft(2, '0');
        horas.add('$horaStr:$minutoStr');
      }
    }
    
    return horas;
  }

  // ✅ CALCULAR HORA FIN (20 minutos después)
  String _calcularHoraFin(String horaInicio) {
    try {
      final partes = horaInicio.split(':');
      final hora = int.parse(partes[0]);
      final minuto = int.parse(partes[1]);
      
      int totalMinutos = hora * 60 + minuto + 20;
      final nuevaHora = totalMinutos ~/ 60;
      final nuevoMinuto = totalMinutos % 60;
      
      return '${nuevaHora.toString().padLeft(2, '0')}:${nuevoMinuto.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error calculando hora fin: $e');
      return '08:00';
    }
  }

  // ✅ CONVERTIR HORA A MINUTOS (para comparaciones)
  int _convertirAMinutos(String hora) {
    try {
      final partes = hora.split(':');
      return int.parse(partes[0]) * 60 + int.parse(partes[1]);
    } catch (e) {
      print('Error convirtiendo hora a minutos: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
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

    if (fecha != null) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
    }
  }

  Future<void> _reagendar() async {
    // Validaciones
    if (_fechaSeleccionada == null) {
      _mostrarError('Selecciona una fecha');
      return;
    }

    if (_horaInicio == null || _horaFin == null) {
      _mostrarError('Selecciona el horario');
      return;
    }

    // Validar que la hora fin sea mayor que la hora inicio
    final [hIni, mIni] = _horaInicio!.split(':').map(int.parse).toList();
    final [hFin, mFin] = _horaFin!.split(':').map(int.parse).toList();
    final inicioMinutos = hIni * 60 + mIni;
    final finMinutos = hFin * 60 + mFin;

    if (finMinutos <= inicioMinutos) {
      _mostrarError('La hora de fin debe ser posterior a la hora de inicio');
      return;
    }

    // Validar duración máxima de 20 minutos
    if ((finMinutos - inicioMinutos) > 20) {
      _mostrarError('La duración máxima es de 20 minutos');
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
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: const BorderRadius.only(
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

                    // Hora inicio
                    DropdownButtonFormField<String>(
                      value: _horaInicio,
                      decoration: InputDecoration(
                        labelText: 'Hora inicio',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _horasDisponibles.map((hora) {
                        return DropdownMenuItem(
                          value: hora,
                          child: Text(hora),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _horaInicio = value;
                            // ✅ Auto-ajustar hora fin (20 min después)
                            _horaFin = _calcularHoraFin(value);
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Hora fin
                    DropdownButtonFormField<String>(
                      value: _horaFin,
                      decoration: InputDecoration(
                        labelText: 'Hora fin',
                        prefixIcon: const Icon(Icons.access_time),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _horasDisponibles
                          .where((hora) {
                            // ✅ Solo mostrar horas posteriores a la hora de inicio
                            if (_horaInicio == null) return true;
                            
                            final inicioMinutos = _convertirAMinutos(_horaInicio!);
                            final finMinutos = _convertirAMinutos(hora);
                            
                            return finMinutos > inicioMinutos && 
                                   (finMinutos - inicioMinutos) <= 20; // Máximo 20 min
                          })
                          .map((hora) => DropdownMenuItem(
                                value: hora,
                                child: Text(hora),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => _horaFin = value);
                      },
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
                  onPressed: _isLoading ? null : _reagendar,
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
                      : const Text(
                          'Confirmar Reagendamiento',
                          style: TextStyle(
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