// lib/pantallas/estudiante/seleccionar_turno_dialog.dart
import 'package:flutter/material.dart';
import '../../servicios/tutoria_service.dart';

class SeleccionarTurnoDialog extends StatefulWidget {
  final String docenteId;
  final String nombreDocente;
  final DateTime fecha;
  final String bloqueInicio;
  final String bloqueFin;

  const SeleccionarTurnoDialog({
    super.key,
    required this.docenteId,
    required this.nombreDocente,
    required this.fecha,
    required this.bloqueInicio,
    required this.bloqueFin,
  });

  @override
  State<SeleccionarTurnoDialog> createState() => _SeleccionarTurnoDialogState();
}

class _SeleccionarTurnoDialogState extends State<SeleccionarTurnoDialog> {
  bool _isLoading = true;
  Map<String, dynamic>? _turnosData;
  String? _turnoSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarTurnos();
  }

  Future<void> _cargarTurnos() async {
    setState(() => _isLoading = true);

    final fechaStr = widget.fecha.toIso8601String().split('T')[0];

    final resultado = await TutoriaService.obtenerTurnosDisponibles(
      docenteId: widget.docenteId,
      fecha: fechaStr,
      horaInicio: widget.bloqueInicio,
      horaFin: widget.bloqueFin,
    );

    if (!mounted) return;

    if (resultado != null && !resultado.containsKey('error')) {
      setState(() {
        _turnosData = resultado;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      _mostrarError(resultado?['error'] ?? 'Error al cargar turnos');
    }
  }

  Future<void> _agendarTurno() async {
    if (_turnoSeleccionado == null) {
      _mostrarError('Debes seleccionar un turno');
      return;
    }

    // Extraer horas del turno seleccionado
    final partes = _turnoSeleccionado!.split(' - ');
    if (partes.length != 2) {
      _mostrarError('Turno inválido');
      return;
    }

    final horaInicio = partes[0];
    final horaFin = partes[1];

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Turno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Docente: ${widget.nombreDocente}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatearFecha(widget.fecha)}'),
            const SizedBox(height: 8),
            Text('Turno: $horaInicio - $horaFin'),
            const SizedBox(height: 8),
            Text('Duración: 20 minutos',
                style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Mostrar loading
    _mostrarCargando();

    final fechaStr = widget.fecha.toIso8601String().split('T')[0];

    final resultado = await TutoriaService.agendarTurno(
      docenteId: widget.docenteId,
      fecha: fechaStr,
      horaInicio: horaInicio,
      horaFin: horaFin,
    );

    if (!mounted) return;
    Navigator.pop(context); // Cerrar loading

    if (resultado != null && !resultado.containsKey('error')) {
      _mostrarExito('¡Turno agendado! El docente revisará tu solicitud');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context, true); // Cerrar diálogo con éxito
    } else {
      _mostrarError(resultado?['error'] ?? 'Error al agendar turno');
    }
  }

  String _formatearFecha(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final dia = dias[fecha.weekday - 1];
    return '$dia ${fecha.day}/${fecha.month}/${fecha.year}';
  }

  void _mostrarCargando() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Agendando turno...'),
              ],
            ),
          ),
        ),
      ),
    );
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
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
                      const Icon(Icons.schedule, color: Colors.white),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Seleccionar Turno',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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
                    'Turnos de 20 minutos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Info del bloque
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 20, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.nombreDocente,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(_formatearFecha(widget.fecha)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text('${widget.bloqueInicio} - ${widget.bloqueFin}'),
                    ],
                  ),
                ],
              ),
            ),

            // Lista de turnos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Cargando turnos disponibles...'),
                        ],
                      ),
                    )
                  : _turnosData == null
                      ? const Center(
                          child: Text('Error al cargar turnos'),
                        )
                      : _buildListaTurnos(),
            ),

            // Footer con botón
            if (!_isLoading && _turnosData != null)
              Container(
                padding: const EdgeInsets.all(16),
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
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _turnoSeleccionado != null ? _agendarTurno : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _turnoSeleccionado != null
                          ? 'Agendar Turno'
                          : 'Selecciona un turno',
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

  Widget _buildListaTurnos() {
    final turnos = _turnosData!['turnos'];
    final disponibles = turnos['disponibles'] as int;
    final total = turnos['total'] as int;
    final lista = turnos['lista'] as List;

    if (disponibles == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay turnos disponibles',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Todos los turnos ($total) están ocupados',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Estadísticas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Disponibles',
                disponibles.toString(),
                Colors.green,
                Icons.check_circle,
              ),
              _buildStat(
                'Ocupados',
                (total - disponibles).toString(),
                Colors.red,
                Icons.cancel,
              ),
              _buildStat(
                'Total',
                total.toString(),
                Colors.blue,
                Icons.schedule,
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Lista de turnos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lista.length,
            itemBuilder: (context, index) {
              final turno = lista[index];
              final horaInicio = turno['horaInicio'];
              final horaFin = turno['horaFin'];
              final turnoKey = '$horaInicio - $horaFin';
              final isSelected = _turnoSeleccionado == turnoKey;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: isSelected ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF1565C0)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _turnoSeleccionado = turnoKey;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.access_time,
                            color: isSelected ? Colors.white : Colors.green,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                turnoKey,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '20 minutos',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF1565C0),
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}