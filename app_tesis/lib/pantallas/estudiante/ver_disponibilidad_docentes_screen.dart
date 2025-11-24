// lib/pantallas/estudiante/ver_disponibilidad_docentes_screen.dart - ESTILOS MEJORADOS
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/docente_service.dart';
import '../../servicios/horario_service.dart';
import 'seleccionar_turno_dialog.dart';

class VerDisponibilidadDocentesScreen extends StatefulWidget {
  final Usuario usuario;

  const VerDisponibilidadDocentesScreen({super.key, required this.usuario});

  @override
  State<VerDisponibilidadDocentesScreen> createState() =>
      _VerDisponibilidadDocentesScreenState();
}

class _VerDisponibilidadDocentesScreenState
    extends State<VerDisponibilidadDocentesScreen> with AutomaticKeepAliveClientMixin {
  
  @override
  bool get wantKeepAlive => true;
  
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    if (_docenteSeleccionado != null && mounted) {
      print('🔄 Pantalla visible de nuevo, recargando disponibilidad...');
      _recargarDisponibilidadSilenciosamente();
    }
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
            if (_materiaSeleccionada == null || 
                !_disponibilidad!.containsKey(_materiaSeleccionada)) {
              _materiaSeleccionada = _disponibilidad!.keys.first;
            }
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

  Future<void> _recargarDisponibilidadSilenciosamente() async {
    if (_docenteSeleccionado == null) return;

    try {
      print('🔄 Recargando disponibilidad de ${_docenteSeleccionado!['nombreDocente']}...');
      
      final disponibilidad = await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: _docenteSeleccionado!['_id'],
      );

      if (!mounted) return;

      Map<String, List<Map<String, dynamic>>>? disponibilidadNormalizada;

      if (disponibilidad != null && disponibilidad.isNotEmpty) {
        disponibilidadNormalizada = {};
        disponibilidad.forEach((materia, bloques) {
          disponibilidadNormalizada![materia] = bloques;
        });
      }

      final hayDiferencias = _hayDiferenciasEnDisponibilidad(
        _disponibilidad, 
        disponibilidadNormalizada
      );

      if (hayDiferencias) {
        print('✅ Se detectaron cambios en la disponibilidad');
        
        setState(() {
          _disponibilidad = disponibilidadNormalizada;

          if (_materiaSeleccionada != null && 
              _disponibilidad != null &&
              !_disponibilidad!.containsKey(_materiaSeleccionada)) {
            _materiaSeleccionada = _disponibilidad!.isNotEmpty 
                ? _disponibilidad!.keys.first 
                : null;
          }
        });
        
        _mostrarInfo('Horarios actualizados');
      } else {
        print('ℹ️ No hay cambios en la disponibilidad');
      }
    } catch (e) {
      print('❌ Error recargando disponibilidad: $e');
    }
  }

  bool _hayDiferenciasEnDisponibilidad(
    Map<String, List<Map<String, dynamic>>>? anterior,
    Map<String, List<Map<String, dynamic>>>? nueva,
  ) {
    if (anterior == null && nueva == null) return false;
    if (anterior == null || nueva == null) return true;
    if (anterior.keys.length != nueva.keys.length) return true;

    for (var materia in anterior.keys) {
      if (!nueva.containsKey(materia)) return true;
      
      final bloquesAnteriores = anterior[materia]!;
      final bloquesNuevos = nueva[materia]!;
      
      if (bloquesAnteriores.length != bloquesNuevos.length) return true;
      
      for (int i = 0; i < bloquesAnteriores.length; i++) {
        if (bloquesAnteriores[i].toString() != bloquesNuevos[i].toString()) {
          return true;
        }
      }
    }

    return false;
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

  Future<void> _agendarTutoria(Map<String, dynamic> bloque, String dia) async {
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _obtenerProximaFechaDelDia(dia),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      locale: const Locale('es', 'ES'),
      selectableDayPredicate: (DateTime date) {
        return _obtenerDiaSemana(date) == dia;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1565C0),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (fechaSeleccionada == null) return;

    final bool? resultado = await showDialog<bool>(
      context: context,
      builder: (context) => SeleccionarTurnoDialog(
        docenteId: _docenteSeleccionado!['_id'],
        nombreDocente: _docenteSeleccionado!['nombreDocente'],
        fecha: fechaSeleccionada,
        bloqueInicio: bloque['horaInicio'],
        bloqueFin: bloque['horaFin'],
      ),
    );

    if (resultado == true && mounted) {
      _recargarDisponibilidadSilenciosamente();
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

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(mensaje),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Agendar Tutoría',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
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
        actions: _docenteSeleccionado != null ? [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.refresh, size: 20),
              ),
              onPressed: _isLoadingDisponibilidad 
                  ? null 
                  : () => _cargarDisponibilidad(_docenteSeleccionado!),
              tooltip: 'Actualizar horarios',
            ),
          ),
        ] : null,
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_search,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paso 1: Selecciona un Docente',
                          style: TextStyle(
                            fontSize: 17,
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
                ],
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar docente...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _filtrarDocentes();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => _filtrarDocentes(),
          ),
        ),

        Expanded(
          child: _isLoadingDocentes
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : _docentesFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron docentes',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _docentesFiltrados.length,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      itemBuilder: (context, index) {
                        final docente = _docentesFiltrados[index];
                        final isSelected =
                            _docenteSeleccionado?['_id'] == docente['_id'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            elevation: isSelected ? 4 : 1,
                            shadowColor: isSelected
                                ? const Color(0xFF1565C0).withOpacity(0.3)
                                : Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF1565C0)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              onTap: () => _cargarDisponibilidad(docente),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              leading: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF1565C0)
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    docente['avatarDocente'] ??
                                        'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                                  ),
                                  radius: 28,
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                              title: Text(
                                docente['nombreDocente'] ?? 'Sin nombre',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        docente['oficinaDocente'] ?? 'Sin oficina',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF1565C0).withOpacity(0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isSelected 
                                    ? Icons.check_circle 
                                    : Icons.chevron_right,
                                  color: isSelected
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey,
                                  size: 24,
                                ),
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

  Widget _buildDetalleDocente() {
    if (_docenteSeleccionado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search, size: 80, color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),
            Text(
              'Selecciona un docente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Podrás ver su disponibilidad\ny agendar una tutoría',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoadingDisponibilidad) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando disponibilidad...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: Color(0xFF1565C0),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paso 2: Selecciona Horario',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Elige un día y horario disponible',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[100]!,
                      Colors.grey[300]!,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withOpacity(0.2),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        _docenteSeleccionado!['avatarDocente'] ??
                            'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                      ),
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _docenteSeleccionado!['oficinaDocente'] ?? 'Sin oficina',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (_disponibilidad != null && _disponibilidad!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey[300]!,
                        Colors.grey[100]!,
                        Colors.grey[300]!,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Icon(Icons.book, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'Materia:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _materiaSeleccionada,
                      isExpanded: true,
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
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

        Expanded(
          child: _disponibilidad == null || _disponibilidad!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.event_busy, size: 80, color: Colors.orange[300]),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Sin horarios disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este docente no tiene\nhorarios registrados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
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
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: bloques.isNotEmpty
                                    ? [
                                        const Color(0xFF1565C0).withOpacity(0.15),
                                        const Color(0xFF1565C0).withOpacity(0.05),
                                      ]
                                    : [
                                        Colors.grey[100]!,
                                        Colors.grey[50]!,
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bloques.isNotEmpty
                                        ? const Color(0xFF1565C0).withOpacity(0.2)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: 18,
                                    color: bloques.isNotEmpty
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dia,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: bloques.isNotEmpty
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                if (bloques.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.green[400]!,
                                          Colors.green[600]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bloques.length} ${bloques.length == 1 ? "bloque" : "bloques"}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.cancel,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sin horarios',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          if (bloques.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: Text(
                                  'No hay horarios disponibles este día',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...bloques.asMap().entries.map((entry) {
                              final index = entry.key;
                              final bloque = entry.value;
                              final isLast = index == bloques.length - 1;
                              
                              return InkWell(
                                onTap: () => _agendarTutoria(bloque, dia),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: isLast
                                          ? BorderSide.none
                                          : BorderSide(
                                              color: Colors.grey[200]!,
                                              width: 1,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green[400]!.withOpacity(0.2),
                                              Colors.green[300]!.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.schedule,
                                          color: Colors.green,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue[50],
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'Disponible',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.blue[700],
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.touch_app,
                                                  size: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Toca para agendar tu tutoría',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1565C0).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Color(0xFF1565C0),
                                        ),
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