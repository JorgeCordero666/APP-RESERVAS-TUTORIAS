// lib/pantallas/docente/gestion_horarios_screen.dart - VERSIÓN CORREGIDA
import 'package:app_tesis/servicios/auth_service.dart';
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
  List<String> _materiasDocente = [];

  @override
  void initState() {
    super.initState();
    _cargarMateriasDocente();
  }

  void _cargarMateriasDocente() {
    AuthService.getUsuarioActual().then((usuarioActualizado) {
      if (usuarioActualizado != null && mounted) {
        final materiasActualizadas = usuarioActualizado.asignaturas ?? [];
        
        if (materiasActualizadas.isNotEmpty) {
          setState(() {
            _materiasDocente = List.from(materiasActualizadas);
            
            for (var materia in _materiasDocente) {
              _horariosPorMateria[materia] = [];
            }
            
            _materiaSeleccionada = _materiasDocente.first;
            _cargarHorariosExistentes();
          });
          
          print('✅ Materias recargadas en GestionHorariosScreen');
          print('   Materias: ${_materiasDocente.join(", ")}');
        }
      }
    });
  }

  Future<void> _cargarHorariosExistentes() async {
    if (_materiaSeleccionada == null) return;

    setState(() => _isLoading = true);

    try {
      print('📥 Cargando horarios de: $_materiaSeleccionada');
      
      final horarios = await HorarioService.obtenerHorariosPorMateria(
        docenteId: widget.usuario.id,
        materia: _materiaSeleccionada!,
      );

      if (horarios != null && mounted) {
        setState(() {
          _horariosPorMateria[_materiaSeleccionada!] = horarios;
          _hasChanges = false;
        });
        
        print('✅ Horarios cargados: ${horarios.length} bloques');
      } else {
        print('ℹ️ No hay horarios previos o hubo error');
        setState(() {
          _horariosPorMateria[_materiaSeleccionada!] = [];
        });
      }
    } catch (e) {
      print('❌ Error cargando horarios: $e');
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
          final yaExiste = _horariosPorMateria[_materiaSeleccionada!]!.any(
            (b) => b['dia'] == dia && 
                   b['horaInicio'] == horaInicio && 
                   b['horaFin'] == horaFin
          );
          
          if (yaExiste) {
            _mostrarError('Este bloque ya existe en tu horario');
            return;
          }
          
          setState(() {
            _horariosPorMateria[_materiaSeleccionada!]!.add({
              'dia': dia,
              'horaInicio': horaInicio,
              'horaFin': horaFin,
            });
            _hasChanges = true;
          });
          
          print('➕ Bloque agregado: $dia $horaInicio-$horaFin');
        },
      ),
    );
  }

  void _eliminarBloque(int index) {
    final bloque = _horariosPorMateria[_materiaSeleccionada!]![index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar bloque'),
        content: Text(
          '¿Eliminar el bloque ${bloque['dia']} ${bloque['horaInicio']}-${bloque['horaFin']}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _horariosPorMateria[_materiaSeleccionada!]!.removeAt(index);
                _hasChanges = true;
              });
              print('🗑️ Bloque eliminado');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarCambios() async {
    if (!_hasChanges) {
      _mostrarInfo('No hay cambios para guardar');
      return;
    }

    if (_horariosPorMateria[_materiaSeleccionada!]!.isEmpty) {
      _mostrarError('Debes agregar al menos un bloque de horario');
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('💾 Guardando horarios de: $_materiaSeleccionada');
      print('   Total bloques: ${_horariosPorMateria[_materiaSeleccionada!]!.length}');
      
      // ✅ CORRECCIÓN: actualizarHorarios ahora retorna Map<String, dynamic>
      final resultado = await HorarioService.actualizarHorarios(
        docenteId: widget.usuario.id,
        materia: _materiaSeleccionada!,
        bloques: _horariosPorMateria[_materiaSeleccionada!]!,
        validarAntes: true, // ✅ Validar antes de guardar
      );

      if (mounted) {
        // ✅ Verificar el campo 'success' en lugar de usar bool directamente
        if (resultado['success'] == true) {
          _mostrarExito(resultado['mensaje'] ?? 'Horarios guardados correctamente');
          
          // ✅ Mostrar estadísticas opcionales
          if (resultado.containsKey('eliminados') && resultado.containsKey('creados')) {
            print('   📊 Eliminados: ${resultado['eliminados']}, Creados: ${resultado['creados']}');
          }
          
          setState(() => _hasChanges = false);
        } else {
          _mostrarError(resultado['mensaje'] ?? 'Error al guardar horarios');
        }
      }
    } catch (e) {
      print('❌ Error guardando: $e');
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
        duration: const Duration(seconds: 4),
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
    if (_materiasDocente.isEmpty) {
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
                'No has seleccionado materias',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Ve a "Mis Materias" para seleccionar las asignaturas que impartes',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.book),
                label: const Text('Ir a Mis Materias'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                ),
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
                      items: _materiasDocente.map((materia) {
                        return DropdownMenuItem(
                          value: materia,
                          child: Text(materia),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && value != _materiaSeleccionada) {
                          setState(() {
                            _materiaSeleccionada = value;
                            _hasChanges = false;
                          });
                          _cargarHorariosExistentes();
                        }
                      },
                    ),
                  ),
                ),
                if (_hasChanges) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tienes cambios sin guardar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[900],
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
                    ? const Center(child: Text('Selecciona una materia'))
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

// =====================================================
// ✅ Dialog para agregar bloque
// =====================================================
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
  String? _error;

  void _validarYAgregar() {
    setState(() => _error = null);

    if (_diaSeleccionado == null || _horaInicio == null || _horaFin == null) {
      setState(() => _error = 'Todos los campos son obligatorios');
      return;
    }

    final [hIni, mIni] = _horaInicio!.split(':').map(int.parse).toList();
    final [hFin, mFin] = _horaFin!.split(':').map(int.parse).toList();
    final inicioMinutos = hIni * 60 + mIni;
    final finMinutos = hFin * 60 + mFin;

    if (finMinutos <= inicioMinutos) {
      setState(() => _error = 'La hora de fin debe ser mayor que la de inicio');
      return;
    }

    widget.onAgregar(_diaSeleccionado!, _horaInicio!, _horaFin!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Horario'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _validarYAgregar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}