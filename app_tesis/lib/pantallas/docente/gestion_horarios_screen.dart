// lib/pantallas/docente/gestion_horarios_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/horario_service.dart';

class GestionHorariosScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionHorariosScreen({super.key, required this.usuario});

  @override
  State<GestionHorariosScreen> createState() => _GestionHorariosScreenState();
}

class _GestionHorariosScreenState extends State<GestionHorariosScreen> {
  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes'
  ];

  final List<String> _horasDisponibles = [
    '07:00', '07:40', '08:20', '09:00', '09:40',
    '10:20', '11:00', '11:40', '12:20', '13:00',
    '13:40', '14:20', '15:00', '15:40', '16:20',
    '17:00', '17:40', '18:20', '19:00', '19:40',
    '20:20', '21:00'
  ];

  Map<String, List<Map<String, dynamic>>> _horariosPorMateria = {};
  String? _materiaSeleccionada;
  String _diaSeleccionado = 'Lunes';
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _cargarMaterias();
  }

  void _cargarMaterias() {
    // Obtener materias del docente
    if (widget.usuario.asignaturas != null && widget.usuario.asignaturas!.isNotEmpty) {
      setState(() {
        // Inicializar horarios para cada materia
        for (var materia in widget.usuario.asignaturas!) {
          _horariosPorMateria[materia] = [];
        }
        _materiaSeleccionada = widget.usuario.asignaturas!.first;
      });
      _cargarHorariosExistentes();
    }
  }

  Future<void> _cargarHorariosExistentes() async {
    if (_materiaSeleccionada == null) return;

    setState(() => _isLoading = true);

    try {
      final horarios = await HorarioService.obtenerHorariosPorMateria(
        docenteId: widget.usuario.id,
        materia: _materiaSeleccionada!,
      );

      if (horarios != null && mounted) {
        setState(() {
          _horariosPorMateria[_materiaSeleccionada!] = horarios;
        });
      }
    } catch (e) {
      _mostrarError('Error al cargar horarios: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _agregarBloque() {
    showDialog(
      context: context,
      builder: (context) => _DialogAgregarBloque(
        diasDisponibles: _diasSemana,
        horasDisponibles: _horasDisponibles,
        onAgregar: (dia, horaInicio, horaFin) {
          setState(() {
            _horariosPorMateria[_materiaSeleccionada!]!.add({
              'dia': dia,
              'horaInicio': horaInicio,
              'horaFin': horaFin,
            });
            _hasChanges = true;
          });
        },
      ),
    );
  }

  void _eliminarBloque(int index) {
    setState(() {
      _horariosPorMateria[_materiaSeleccionada!]!.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _guardarCambios() async {
    if (!_hasChanges) {
      _mostrarInfo('No hay cambios para guardar');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await HorarioService.actualizarHorarios(
        docenteId: widget.usuario.id,
        materia: _materiaSeleccionada!,
        bloques: _horariosPorMateria[_materiaSeleccionada!]!,
      );

      if (mounted) {
        _mostrarExito('Horarios guardados correctamente');
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      _mostrarError('Error al guardar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _obtenerBloquesPorDia(String dia) {
    if (_materiaSeleccionada == null) return [];
    return _horariosPorMateria[_materiaSeleccionada!]!
        .where((bloque) => bloque['dia'] == dia)
        .toList()
      ..sort((a, b) => a['horaInicio'].compareTo(b['horaInicio']));
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

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.usuario.asignaturas == null || widget.usuario.asignaturas!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gestión de Horarios'),
          backgroundColor: const Color(0xFF1565C0),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber, size: 80, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'No tienes materias asignadas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Contacta al administrador para que te asigne materias',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Horarios'),
        backgroundColor: const Color(0xFF1565C0),
        actions: [
          if (_hasChanges && !_isLoading)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector de materia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Materia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _materiaSeleccionada,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1565C0)),
                      items: widget.usuario.asignaturas!.map((materia) {
                        return DropdownMenuItem(
                          value: materia,
                          child: Text(materia),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _materiaSeleccionada = value;
                          _cargarHorariosExistentes();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabs de días
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _diasSemana.map((dia) {
                  final isSelected = _diaSeleccionado == dia;
                  return GestureDetector(
                    onTap: () => setState(() => _diaSeleccionado = dia),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Text(
                        dia,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista de bloques
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _materiaSeleccionada == null
                    ? const Center(
                        child: Text('Selecciona una materia'),
                      )
                    : () {
                        final bloques = _obtenerBloquesPorDia(_diaSeleccionado);
                        
                        if (bloques.isEmpty) {
                          return Center(
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
                                  'No hay horarios para $_diaSeleccionado',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Presiona el botón + para agregar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: bloques.length,
                          itemBuilder: (context, index) {
                            final bloque = bloques[index];
                            final indexGlobal = _horariosPorMateria[
                                    _materiaSeleccionada!]!
                                .indexOf(bloque);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                title: Text(
                                  '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  bloque['dia'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _eliminarBloque(indexGlobal),
                                ),
                              ),
                            );
                          },
                        );
                      }(),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _agregarBloque,
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.add),
            ),
    );
  }
}

// Dialog para agregar bloque
class _DialogAgregarBloque extends StatefulWidget {
  final List<String> diasDisponibles;
  final List<String> horasDisponibles;
  final Function(String dia, String horaInicio, String horaFin) onAgregar;

  const _DialogAgregarBloque({
    required this.diasDisponibles,
    required this.horasDisponibles,
    required this.onAgregar,
  });

  @override
  State<_DialogAgregarBloque> createState() => _DialogAgregarBloqueState();
}

class _DialogAgregarBloqueState extends State<_DialogAgregarBloque> {
  String? _diaSeleccionado;
  String? _horaInicio;
  String? _horaFin;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Horario'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _diaSeleccionado,
            decoration: const InputDecoration(labelText: 'Día'),
            items: widget.diasDisponibles.map((dia) {
              return DropdownMenuItem(value: dia, child: Text(dia));
            }).toList(),
            onChanged: (value) => setState(() => _diaSeleccionado = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _horaInicio,
            decoration: const InputDecoration(labelText: 'Hora inicio'),
            items: widget.horasDisponibles.map((hora) {
              return DropdownMenuItem(value: hora, child: Text(hora));
            }).toList(),
            onChanged: (value) => setState(() => _horaInicio = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _horaFin,
            decoration: const InputDecoration(labelText: 'Hora fin'),
            items: widget.horasDisponibles.map((hora) {
              return DropdownMenuItem(value: hora, child: Text(hora));
            }).toList(),
            onChanged: (value) => setState(() => _horaFin = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_diaSeleccionado != null &&
                _horaInicio != null &&
                _horaFin != null) {
              widget.onAgregar(_diaSeleccionado!, _horaInicio!, _horaFin!);
              Navigator.pop(context);
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}