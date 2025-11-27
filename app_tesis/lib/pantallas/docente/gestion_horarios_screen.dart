// lib/pantallas/docente/gestion_horarios_screen.dart - CON RECARGA AUTOMÁTICA
import 'package:app_tesis/servicios/auth_service.dart';
import 'package:app_tesis/servicios/docente_service.dart';
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/horario_service.dart';
import '../../servicios/notification_service.dart';
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
    '07:00',
    '07:40',
    '08:20',
    '09:00',
    '09:40',
    '10:20',
    '11:00',
    '11:40',
    '12:20',
    '13:00',
    '13:40',
    '14:20',
    '15:00',
    '15:40',
    '16:20',
    '17:00',
    '17:40',
    '18:20',
    '19:00',
    '19:40',
    '20:20',
    '21:00',
  ];

  Map<String, List<Map<String, dynamic>>> _horariosPorMateria = {};
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

    _materiasSubscription = notificationService.materiasActualizadas.listen((
      _,
    ) {
      print(
        '🔔 GestionHorarios: Recibida notificación de materias actualizadas',
      );
      if (mounted) {
        _cargarMateriasDocente();
      }
    });
  }

  @override
  void dispose() {
    _materiasSubscription?.cancel();
    super.dispose();
  }

  Future<void> refrescarMaterias() async {
    _cargarMateriasDocente();
  }

  Future<void> _cargarMateriasDocente() async {
    print('🔄 Recargando materias del docente...');

    final validacion = await DocenteService.validarMaterias(widget.usuario.id);

    if (validacion != null && !validacion.containsKey('error')) {
      if (validacion['fueronEliminadas'] == true) {
        print('⚠️ Materias desactualizadas detectadas, sincronizando...');
        _mostrarError('Algunas materias fueron eliminadas del sistema');
      }
    }

    final usuarioActualizado = await AuthService.getUsuarioActual();

    if (usuarioActualizado != null && mounted) {
      final materiasActualizadas = usuarioActualizado.asignaturas ?? [];

      print('📚 Materias actualizadas: ${materiasActualizadas.join(", ")}');

      final materiasAntiguas = Set.from(_materiasDocente);
      final materiasNuevas = Set.from(materiasActualizadas);

      final materiasEliminadas = materiasAntiguas.difference(materiasNuevas);
      final materiasAgregadas = materiasNuevas.difference(materiasAntiguas);

      if (materiasEliminadas.isNotEmpty) {
        print('🗑️ Materias eliminadas: ${materiasEliminadas.join(", ")}');
      }
      if (materiasAgregadas.isNotEmpty) {
        print('➕ Materias agregadas: ${materiasAgregadas.join(", ")}');
      }

      setState(() {
        _materiasDocente = List.from(materiasActualizadas);

        _horariosPorMateria.removeWhere(
          (materia, _) => !_materiasDocente.contains(materia),
        );

        for (var materia in _materiasDocente) {
          if (!_horariosPorMateria.containsKey(materia)) {
            _horariosPorMateria[materia] = [];
          }
        }

        if (_materiaSeleccionada != null &&
            !_materiasDocente.contains(_materiaSeleccionada)) {
          print('⚠️ Materia "$_materiaSeleccionada" ya no está disponible');
          _materiaSeleccionada = _materiasDocente.isNotEmpty
              ? _materiasDocente.first
              : null;
          _hasChanges = false;
        }

        if (_materiaSeleccionada == null && _materiasDocente.isNotEmpty) {
          _materiaSeleccionada = _materiasDocente.first;
        }
      });

      if (_materiaSeleccionada != null) {
        _cargarHorariosExistentes();
      }
    }
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
            (b) =>
                b['dia'] == dia &&
                b['horaInicio'] == horaInicio &&
                b['horaFin'] == horaFin,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red[400]!, Colors.red[600]!],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Eliminar bloque',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '¿Eliminar el bloque ${bloque['dia']} ${bloque['horaInicio']}-${bloque['horaFin']}?',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red[400]!, Colors.red[600]!],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _horariosPorMateria[_materiaSeleccionada!]!.removeAt(index);
                  _hasChanges = true;
                });
                print('🗑️ Bloque eliminado');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
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
      print(
        '   Total bloques: ${_horariosPorMateria[_materiaSeleccionada!]!.length}',
      );

      final resultado = await HorarioService.actualizarHorarios(
        docenteId: widget.usuario.id,
        materia: _materiaSeleccionada!,
        bloques: _horariosPorMateria[_materiaSeleccionada!]!,
        validarAntes: true,
      );

      if (mounted) {
        if (resultado['success'] == true) {
          _mostrarExito(
            resultado['mensaje'] ?? 'Horarios guardados correctamente',
          );

          if (resultado.containsKey('eliminados') &&
              resultado.containsKey('creados')) {
            print(
              '   📊 Eliminados: ${resultado['eliminados']}, Creados: ${resultado['creados']}',
            );
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

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        duration: const Duration(seconds: 4),
        elevation: 6,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        elevation: 6,
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1976D2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_materiasDocente.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Gestión de Horarios',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 21,
              letterSpacing: 0.3,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _isLoading ? null : _cargarMateriasDocente,
                  tooltip: 'Actualizar materias',
                ),
              ),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.orange[100]!,
                        Colors.orange[50]!,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 90,
                    color: Colors.orange[500],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'No has seleccionado materias',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A5F),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ve a "Mis Materias" para seleccionar las asignaturas que impartes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1565C0).withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.book_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Ir a Mis Materias',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Gestión de Horarios',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 21,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _isLoading ? null : () async {
                  print('🔄 Recarga manual solicitada');
                  await _cargarMateriasDocente();
                },
                tooltip: 'Actualizar materias',
              ),
            ),
          ),
          if (_hasChanges && !_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.save_rounded, color: Colors.white),
                  onPressed: _guardarCambios,
                  tooltip: 'Guardar cambios',
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Selector de materia mejorado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF1565C0),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Materia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A5F),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_materiasDocente.length} ${_materiasDocente.length == 1 ? "materia" : "materias"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                
                // Dropdown mejorado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _materiaSeleccionada,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: Color(0xFF1565C0),
                        size: 28,
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A5F),
                      ),
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
                
                // Advertencia mejorada
                if (_hasChanges) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange[50]!,
                          Colors.orange[100]!.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.orange[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange[700],
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tienes cambios sin guardar',
                            style: TextStyle(
                              fontSize: 13,
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

          // Tabs de días mejorados
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _diasSemana.map((dia) {
                  final isSelected = _diaSeleccionado == dia;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _diaSeleccionado = dia),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF1565C0).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            dia,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 0.3,
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

          // Lista de bloques mejorada
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1565C0).withOpacity(0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1565C0)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Cargando horarios...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A5F),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  )
                : _materiaSeleccionada == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(26),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[100]!,
                                      Colors.grey[50]!,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  size: 85,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 26),
                              Text(
                                'Selecciona una materia',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : () {
                        final bloques = _obtenerBloquesPorDia(_diaSeleccionado);
                        
                        if (bloques.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(26),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.blue[50]!,
                                          Colors.blue[100]!.withOpacity(0.3),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.event_busy_rounded,
                                      size: 85,
                                      color: Colors.blue[300],
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  Text(
                                    'No hay horarios para $_diaSeleccionado',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey[700],
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Presiona el botón + para agregar',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: bloques.length,
                          itemBuilder: (context, index) {
                            final bloque = bloques[index];
                            final indexGlobal = _horariosPorMateria[
                                    _materiaSeleccionada!]!
                                .indexOf(bloque);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFF1565C0).withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {},
                                  borderRadius: BorderRadius.circular(18),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Ícono mejorado
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF42A5F5).withOpacity(0.15),
                                                const Color(0xFF1565C0).withOpacity(0.15),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: const Icon(
                                            Icons.access_time_rounded,
                                            color: Color(0xFF1565C0),
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        
                                        // Contenido
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: Color(0xFF1E3A5F),
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF1565C0).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  bloque['dia'],
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1565C0),
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        
                                        // Botón eliminar mejorado
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            onPressed: () => _eliminarBloque(indexGlobal),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
              elevation: 8,
              child: const Icon(Icons.add_rounded, size: 28),
            ),
    );
  }

  List<Map<String, dynamic>> _obtenerBloquesPorDia(String dia) {
    if (_materiaSeleccionada == null) return [];

    return _horariosPorMateria[_materiaSeleccionada!]!
        .where((bloque) => bloque['dia'] == dia)
        .toList()
      ..sort((a, b) => a['horaInicio'].compareTo(b['horaInicio']));
  }
}

// ====================================================
// DIALOG PARA AGREGAR BLOQUE - MEJORADO
// ====================================================
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Agregar Horario',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red[300]!, width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            
            // Dropdown Día
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _diaSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Día',
                  labelStyle: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: widget.diasDisponibles.map((dia) {
                  return DropdownMenuItem(
                    value: dia,
                    child: Text(
                      dia,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _diaSeleccionado = value),
              ),
            ),
            const SizedBox(height: 18),
            
            // Dropdown Hora Inicio
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _horaInicio,
                decoration: InputDecoration(
                  labelText: 'Hora inicio',
                  labelStyle: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(Icons.access_time_rounded, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: widget.horasDisponibles.map((hora) {
                  return DropdownMenuItem(
                    value: hora,
                    child: Text(
                      hora,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _horaInicio = value),
              ),
            ),
            const SizedBox(height: 18),
            
            // Dropdown Hora Fin
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: DropdownButtonFormField<String>(
                value: _horaFin,
                decoration: InputDecoration(
                  labelText: 'Hora fin',
                  labelStyle: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: Icon(Icons.access_time_filled_rounded, color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                items: widget.horasDisponibles.map((hora) {
                  return DropdownMenuItem(
                    value: hora,
                    child: Text(
                      hora,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _horaFin = value),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.all(20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF43A047).withOpacity(0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _validarYAgregar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 20, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'Agregar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}