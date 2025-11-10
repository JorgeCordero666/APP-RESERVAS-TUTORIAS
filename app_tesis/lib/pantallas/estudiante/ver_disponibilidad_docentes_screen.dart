// lib/pantallas/estudiante/ver_disponibilidad_docentes_screen.dart - VERSIÓN COMPLETA CON AGENDAR
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/docente_service.dart';
import '../../servicios/horario_service.dart';
import '../../servicios/tutoria_service.dart';

class VerDisponibilidadDocentesScreen extends StatefulWidget {
  final Usuario usuario;

  const VerDisponibilidadDocentesScreen({super.key, required this.usuario});

  @override
  State<VerDisponibilidadDocentesScreen> createState() =>
      _VerDisponibilidadDocentesScreenState();
}

class _VerDisponibilidadDocentesScreenState
    extends State<VerDisponibilidadDocentesScreen> {
  List<Map<String, dynamic>> _docentes = [];
  List<Map<String, dynamic>> _docentesFiltrados = [];
  Map<String, dynamic>? _docenteSeleccionado;
  Map<String, List<Map<String, dynamic>>>? _disponibilidad;
  bool _isLoadingDocentes = true;
  bool _isLoadingDisponibilidad = false;
  String? _materiaSeleccionada;
  bool _mostrarListaDocentes = true;

  final _searchController = TextEditingController();

  final List<String> _diasSemana = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes'
  ];

  @override
  void initState() {
    super.initState();
    _cargarDocentes();
  }

  Future<void> _cargarDocentes() async {
    setState(() => _isLoadingDocentes = true);

    try {
      final docentes = await DocenteService.listarDocentes();

      if (mounted) {
        setState(() {
          _docentes = docentes;
          _docentesFiltrados = docentes;
          _isLoadingDocentes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDocentes = false);
        _mostrarError('Error al cargar docentes: $e');
      }
    }
  }

  void _filtrarDocentes() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _docentesFiltrados = _docentes;
      } else {
        _docentesFiltrados = _docentes.where((docente) {
          final nombreMatch = (docente['nombreDocente'] ?? '')
              .toLowerCase()
              .contains(query);
          final oficinaMatch = (docente['oficinaDocente'] ?? '')
              .toLowerCase()
              .contains(query);
          return nombreMatch || oficinaMatch;
        }).toList();
      }
    });
  }

  Future<void> _cargarDisponibilidad(Map<String, dynamic> docente) async {
    setState(() {
      _docenteSeleccionado = docente;
      _isLoadingDisponibilidad = true;
      _disponibilidad = null;
      _materiaSeleccionada = null;
      _mostrarListaDocentes = false;
    });

    try {
      final disponibilidad =
          await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: docente['_id'],
      );

      if (mounted) {
        Map<String, List<Map<String, dynamic>>>? disponibilidadNormalizada;

        if (disponibilidad != null && disponibilidad.isNotEmpty) {
          disponibilidadNormalizada = {};
          disponibilidad.forEach((materia, bloques) {
            disponibilidadNormalizada![materia] = bloques;
          });
        }

        setState(() {
          _disponibilidad = disponibilidadNormalizada;
          _isLoadingDisponibilidad = false;

          if (_disponibilidad != null && _disponibilidad!.isNotEmpty) {
            _materiaSeleccionada = _disponibilidad!.keys.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDisponibilidad = false;
        });
        _mostrarError('Error al cargar disponibilidad: $e');
      }
    }
  }

  List<Map<String, dynamic>> _obtenerBloquesPorDia(String dia) {
    if (_disponibilidad == null || _materiaSeleccionada == null) {
      return [];
    }

    final bloques = _disponibilidad![_materiaSeleccionada!] ?? [];

    final resultado = bloques.where((bloque) {
      return bloque['dia'] == dia;
    }).toList();

    resultado.sort((a, b) =>
        (a['horaInicio'] ?? '').compareTo(b['horaInicio'] ?? ''));

    return resultado;
  }

  // ✅ FUNCIÓN PARA AGENDAR TUTORÍA
  Future<void> _agendarTutoria(Map<String, dynamic> bloque, String dia) async {
    // Paso 1: Seleccionar fecha
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _obtenerProximaFechaDelDia(dia),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es', 'ES'),
      selectableDayPredicate: (DateTime date) {
        // Solo permitir seleccionar el día de la semana correspondiente
        return _obtenerDiaSemana(date) == dia;
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

    if (fechaSeleccionada == null) return;

    // Paso 2: Confirmar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Tutoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Docente: ${_docenteSeleccionado!['nombreDocente']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Materia: $_materiaSeleccionada'),
            const SizedBox(height: 8),
            Text('Fecha: ${_formatearFecha(fechaSeleccionada)}'),
            const SizedBox(height: 8),
            Text('Hora: ${bloque['horaInicio']} - ${bloque['horaFin']}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El docente deberá aceptar tu solicitud',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
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

    // Paso 3: Agendar
    _mostrarCargando();

    try {
      final resultado = await TutoriaService.agendarTutoria(
        docenteId: _docenteSeleccionado!['_id'],
        fecha: fechaSeleccionada.toIso8601String().split('T')[0],
        horaInicio: bloque['horaInicio'],
        horaFin: bloque['horaFin'],
      );

      if (!mounted) return;
      Navigator.pop(context); // Cerrar diálogo de carga

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(resultado['error']);
      } else {
        _mostrarExito('¡Solicitud enviada! El docente revisará tu petición');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarError('Error al agendar: $e');
    }
  }

  DateTime _obtenerProximaFechaDelDia(String dia) {
    final hoy = DateTime.now();
    final diasParaSumar = _diasSemana.indexOf(dia) - (hoy.weekday - 1);
    
    if (diasParaSumar < 0) {
      return hoy.add(Duration(days: 7 + diasParaSumar));
    } else if (diasParaSumar == 0) {
      return hoy.add(const Duration(days: 7));
    } else {
      return hoy.add(Duration(days: diasParaSumar));
    }
  }

  String _obtenerDiaSemana(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return dias[fecha.weekday - 1];
  }

  String _formatearFecha(DateTime fecha) {
    final dia = _obtenerDiaSemana(fecha);
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
                Text('Agendando tutoría...'),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Tutoría'),
        backgroundColor: const Color(0xFF1565C0),
        leading: (!isLargeScreen && !_mostrarListaDocentes)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _mostrarListaDocentes = true;
                    _docenteSeleccionado = null;
                  });
                },
              )
            : null,
      ),
      body: isLargeScreen ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(right: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildListaDocentes(),
        ),
        Expanded(child: _buildDetalleDocente()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _mostrarListaDocentes
        ? _buildListaDocentes()
        : _buildDetalleDocente();
  }

  Widget _buildListaDocentes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paso 1: Selecciona un Docente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Elige el docente con quien deseas agendar',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),

        // Campo de búsqueda
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar docente por nombre u oficina',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filtrarDocentes();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            onChanged: (_) => _filtrarDocentes(),
          ),
        ),

        // Lista de docentes
        Expanded(
          child: _isLoadingDocentes
              ? const Center(child: CircularProgressIndicator())
              : _docentesFiltrados.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay docentes disponibles',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _docentesFiltrados.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final docente = _docentesFiltrados[index];
                        final isSelected =
                            _docenteSeleccionado?['_id'] == docente['_id'];

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          elevation: isSelected ? 4 : 1,
                          color: isSelected
                              ? const Color(0xFF1565C0).withOpacity(0.1)
                              : null,
                          child: ListTile(
                            onTap: () => _cargarDisponibilidad(docente),
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                docente['avatarDocente'] ??
                                    'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                              ),
                              radius: 24,
                            ),
                            title: Text(
                              docente['nombreDocente'] ?? 'Sin nombre',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              docente['oficinaDocente'] ?? 'Sin oficina',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Icon(
                              isSelected 
                                ? Icons.check_circle 
                                : Icons.chevron_right,
                              color: isSelected
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildDetalleDocente() {
    if (_docenteSeleccionado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Selecciona un docente para ver\nsu disponibilidad',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_isLoadingDisponibilidad) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando disponibilidad...'),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con info del docente
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paso 2: Selecciona Horario',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      _docenteSeleccionado!['avatarDocente'] ??
                          'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docenteSeleccionado!['nombreDocente'] ?? 'Sin nombre',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _docenteSeleccionado!['oficinaDocente'] ?? 'Sin oficina',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_disponibilidad != null && _disponibilidad!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                
                const Text(
                  'Materia:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _materiaSeleccionada,
                      isExpanded: true,
                      items: _disponibilidad!.keys.map((materia) {
                        return DropdownMenuItem(
                          value: materia,
                          child: Text(materia),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _materiaSeleccionada = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Horarios disponibles
        Expanded(
          child: _disponibilidad == null || _disponibilidad!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Este docente no tiene\nhorarios registrados',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _diasSemana.map((dia) {
                    final bloques = _obtenerBloquesPorDia(dia);
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0).withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 18,
                                  color: Color(0xFF1565C0),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dia,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                const Spacer(),
                                if (bloques.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${bloques.length} ${bloques.length == 1 ? "bloque" : "bloques"}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          if (bloques.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No hay horarios disponibles',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          else
                            ...bloques.map((bloque) {
                              return InkWell(
                                onTap: () => _agendarTutoria(bloque, dia),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey[200]!,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.schedule,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Toca para agendar',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}