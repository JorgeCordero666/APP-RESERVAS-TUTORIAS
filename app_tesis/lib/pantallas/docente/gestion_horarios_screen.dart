// lib/pantallas/docente/gestion_horarios_screen.dart - RESPONSIVE
import 'package:app_tesis/servicios/auth_service.dart';
import 'package:app_tesis/servicios/docente_service.dart';
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/horario_service.dart';
import '../../servicios/notification_service.dart';
import '../../config/responsive_helper.dart';
import 'dart:async';

class GestionHorariosScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionHorariosScreen({super.key, required this.usuario});

  @override
  State<GestionHorariosScreen> createState() => _GestionHorariosScreenState();
}

class _GestionHorariosScreenState extends State<GestionHorariosScreen>
    with AutomaticKeepAliveClientMixin {
  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
  ];

  final List<String> _horasDisponibles = [
    '07:00', '07:40', '08:20', '09:00', '09:40', '10:20',
    '11:00', '11:40', '12:20', '13:00', '13:40', '14:20',
    '15:00', '15:40', '16:20', '17:00', '17:40', '18:20',
    '19:00', '19:40', '20:20', '21:00',
  ];

  final Map<String, List<Map<String, dynamic>>> _horariosPorMateria = {};
  String? _materiaSeleccionada;
  String _diaSeleccionado = 'Lunes';
  bool _isLoading = false;
  bool _hasChanges = false;
  List<String> _materiasDocente = [];
  StreamSubscription? _materiasSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_materiasDocente.isNotEmpty) {
      _cargarMateriasDocente();
    }
  }

  @override
  void initState() {
    super.initState();
    _cargarMateriasDocente();
    _materiasSubscription = notificationService.materiasActualizadas.listen((_, ) {
      if (mounted) _cargarMateriasDocente();
    });
  }

  @override
  void dispose() {
    _materiasSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargarMateriasDocente() async {
    final validacion = await DocenteService.validarMaterias(widget.usuario.id);

    if (validacion != null && !validacion.containsKey('error')) {
      if (validacion['fueronEliminadas'] == true && mounted) {
        _mostrarInfo('Se eliminaron materias que ya no existen');
      }
    }

    final usuarioActualizado = await AuthService.getUsuarioActual();

    if (usuarioActualizado != null && mounted) {
      setState(() {
        _materiasDocente = List.from(usuarioActualizado.asignaturas ?? []);
        _horariosPorMateria.removeWhere((m, _) => !_materiasDocente.contains(m));
        
        for (var materia in _materiasDocente) {
          if (!_horariosPorMateria.containsKey(materia)) {
            _horariosPorMateria[materia] = [];
          }
        }

        if (_materiaSeleccionada != null && !_materiasDocente.contains(_materiaSeleccionada)) {
          _materiaSeleccionada = _materiasDocente.isNotEmpty ? _materiasDocente.first : null;
          _hasChanges = false;
        }

        if (_materiaSeleccionada == null && _materiasDocente.isNotEmpty) {
          _materiaSeleccionada = _materiasDocente.first;
        }
      });

      if (_materiaSeleccionada != null) _cargarHorariosExistentes();
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
          _hasChanges = false;
        });
      } else if (mounted) {
        setState(() => _horariosPorMateria[_materiaSeleccionada!] = []);
      }
    } catch (e) {
      if (mounted) _mostrarError('Error al cargar horarios: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            (b) => b['dia'] == dia && b['horaInicio'] == horaInicio && b['horaFin'] == horaFin,
          );

          if (yaExiste) {
            _mostrarError('Este bloque ya existe');
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
        },
      ),
    );
  }

  void _eliminarBloque(int index) {
    final bloque = _horariosPorMateria[_materiaSeleccionada!]![index];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar bloque'),
        content: Text('¿Eliminar ${bloque['dia']} ${bloque['horaInicio']}-${bloque['horaFin']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _horariosPorMateria[_materiaSeleccionada!]!.removeAt(index);
                _hasChanges = true;
              });
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
      _mostrarError('Debes agregar al menos un bloque');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await HorarioService.actualizarHorarios(
        docenteId: widget.usuario.id,
        materia: _materiaSeleccionada!,
        bloques: _horariosPorMateria[_materiaSeleccionada!]!,
        validarAntes: true,
      );

      if (mounted) {
        if (resultado['success'] == true) {
          _mostrarExito(resultado['mensaje'] ?? 'Horarios guardados');
          setState(() => _hasChanges = false);
        } else {
          _mostrarError(resultado['mensaje'] ?? 'Error al guardar');
        }
      }
    } catch (e) {
      if (mounted) _mostrarError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String m) => _mostrarSnackBar(m, Colors.red, Icons.error_outline_rounded);
  void _mostrarExito(String m) => _mostrarSnackBar(m, Colors.green, Icons.check_circle_outline_rounded);
  void _mostrarInfo(String m) => _mostrarSnackBar(m, Colors.blue, Icons.info_outline_rounded);

  void _mostrarSnackBar(String mensaje, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            SizedBox(width: context.responsiveSpacing),
            Expanded(child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;
    
    if (_materiasDocente.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: _buildEmptyState('No has seleccionado materias', 
          'Ve a "Mis Materias" para seleccionar asignaturas',
          Icons.warning_amber_rounded,
          Colors.orange),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Selector de materia
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF42A5F5).withOpacity(0.12),
                  const Color(0xFF1E88E5).withOpacity(0.06),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 8 : 11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.school_rounded,
                        color: const Color(0xFF1565C0),
                        size: context.responsiveIconSize(24),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing),
                    Expanded(
                      child: Text(
                        'Materia',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_materiasDocente.length} ${_materiasDocente.length == 1 ? "materia" : "materias"}',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(12),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _materiaSeleccionada,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A5F),
                      ),
                      items: _materiasDocente.map((m) {
                        return DropdownMenuItem(value: m, child: Text(m));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null && v != _materiaSeleccionada) {
                          setState(() {
                            _materiaSeleccionada = v;
                            _hasChanges = false;
                          });
                          _cargarHorariosExistentes();
                        }
                      },
                    ),
                  ),
                ),
                if (_hasChanges) ...[
                  SizedBox(height: context.responsiveSpacing),
                  Container(
                    padding: EdgeInsets.all(context.responsiveSpacing * 0.75),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, 
                          color: Colors.orange[700],
                          size: context.responsiveIconSize(20)),
                        SizedBox(width: context.responsiveSpacing * 0.75),
                        Expanded(
                          child: Text(
                            'Cambios sin guardar',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(13),
                              color: Colors.orange[900],
                              fontWeight: FontWeight.w600,
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
              padding: EdgeInsets.symmetric(horizontal: padding * 0.75),
              child: Row(
                children: _diasSemana.map((dia) {
                  final isSelected = _diaSeleccionado == dia;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _diaSeleccionado = dia),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 20,
                            vertical: isMobile ? 10 : 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1565C0)])
                                : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isMobile ? dia.substring(0, 3) : dia,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: context.responsiveFontSize(14),
                            ),
                          ),
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
                ? Center(child: CircularProgressIndicator())
                : _materiaSeleccionada == null
                    ? _buildEmptyState('Selecciona una materia', '', Icons.school_outlined, Colors.grey)
                    : _buildBloquesList(),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton(
              onPressed: _agregarBloque,
              backgroundColor: const Color(0xFF1565C0),
              child: Icon(Icons.add_rounded, size: context.responsiveIconSize(28)),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Gestión de Horarios',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: context.responsiveFontSize(21),
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF1565C0),
      foregroundColor: Colors.white,
      actions: [
        if (!_isLoading)
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarMateriasDocente,
          ),
        if (_hasChanges && !_isLoading)
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _guardarCambios,
          ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, Color color) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: context.responsiveIconSize(90), color: color),
            SizedBox(height: context.responsiveSpacing * 2),
            Text(
              title,
              style: TextStyle(
                fontSize: context.responsiveFontSize(22),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle.isNotEmpty) ...[
              SizedBox(height: context.responsiveSpacing),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(15),
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBloquesList() {
    final bloques = _obtenerBloquesPorDia(_diaSeleccionado);
    final padding = context.responsivePadding;
    
    if (bloques.isEmpty) {
      return _buildEmptyState(
        'No hay horarios para $_diaSeleccionado',
        'Presiona + para agregar',
        Icons.event_busy_rounded,
        Colors.blue,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: bloques.length,
      itemBuilder: (context, index) {
        final bloque = bloques[index];
        final indexGlobal = _horariosPorMateria[_materiaSeleccionada!]!.indexOf(bloque);

        return Container(
          margin: EdgeInsets.only(bottom: context.responsiveSpacing),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(padding),
            leading: Container(
              padding: EdgeInsets.all(context.responsiveSpacing * 0.75),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.access_time_rounded,
                color: const Color(0xFF1565C0),
                size: context.responsiveIconSize(24),
              ),
            ),
            title: Text(
              '${bloque['horaInicio']} - ${bloque['horaFin']}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: context.responsiveFontSize(16),
              ),
            ),
            subtitle: Text(
              bloque['dia'],
              style: TextStyle(fontSize: context.responsiveFontSize(12)),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              iconSize: context.responsiveIconSize(24),
              onPressed: () => _eliminarBloque(indexGlobal),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _obtenerBloquesPorDia(String dia) {
    if (_materiaSeleccionada == null) return [];
    return _horariosPorMateria[_materiaSeleccionada!]!
        .where((b) => b['dia'] == dia)
        .toList()
      ..sort((a, b) => a['horaInicio'].compareTo(b['horaInicio']));
  }
}

// Dialog responsive
class _DialogAgregarBloque extends StatefulWidget {
  final List<String> diasDisponibles;
  final List<String> horasDisponibles;
  final Function(String, String, String) onAgregar;

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

    final inicioMinutos = _horaInicio!.split(':').map(int.parse).fold(0, (a, b) => a * 60 + b);
    final finMinutos = _horaFin!.split(':').map(int.parse).fold(0, (a, b) => a * 60 + b);

    if (finMinutos <= inicioMinutos) {
      setState(() => _error = 'Hora de fin debe ser mayor que hora de inicio');
      return;
    }

    widget.onAgregar(_diaSeleccionado!, _horaInicio!, _horaFin!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Agregar Horario',
        style: TextStyle(fontSize: context.responsiveFontSize(20)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                padding: EdgeInsets.all(padding * 0.75),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
              SizedBox(height: context.responsiveSpacing),
            ],
            DropdownButtonFormField<String>(
              value: _diaSeleccionado,
              decoration: InputDecoration(
                labelText: 'Día',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: widget.diasDisponibles.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _diaSeleccionado = v),
            ),
            SizedBox(height: context.responsiveSpacing),
            DropdownButtonFormField<String>(
              value: _horaInicio,
              decoration: InputDecoration(
                labelText: 'Hora inicio',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: widget.horasDisponibles.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: (v) => setState(() => _horaInicio = v),
            ),
            SizedBox(height: context.responsiveSpacing),
            DropdownButtonFormField<String>(
              value: _horaFin,
              decoration: InputDecoration(
                labelText: 'Hora fin',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: widget.horasDisponibles.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
              onChanged: (v) => setState(() => _horaFin = v),
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