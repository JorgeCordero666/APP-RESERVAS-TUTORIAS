// lib/pantallas/estudiante/ver_disponibilidad_docentes_screen.dart - FULLY RESPONSIVE
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/docente_service.dart';
import '../../servicios/horario_service.dart';
import '../../config/responsive_helper.dart';
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
            Icon(
              Icons.error_outline, 
              color: Colors.white,
              size: context.responsiveIconSize(20),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(fontSize: context.responsiveFontSize(14)),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info_outline, 
              color: Colors.white,
              size: context.responsiveIconSize(20),
            ),
            SizedBox(width: context.responsiveSpacing),
            Text(
              mensaje,
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
            ),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(context.responsivePadding),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Agendar Tutoría',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: context.responsiveFontSize(20),
          ),
        ),
        backgroundColor: const Color(0xFF1565C0),
        elevation: 0,
        leading: (!context.isDesktop && !_mostrarListaDocentes)
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
            margin: EdgeInsets.only(right: context.isMobile ? 4 : 8),
            child: IconButton(
              icon: Container(
                padding: EdgeInsets.all(context.isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.refresh, size: context.responsiveIconSize(20)),
              ),
              onPressed: _isLoadingDisponibilidad 
                  ? null 
                  : () => _cargarDisponibilidad(_docenteSeleccionado!),
              tooltip: 'Actualizar horarios',
            ),
          ),
        ] : null,
      ),
      body: context.isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Container(
          width: ResponsiveHelper.isMobile(context) ? 280 : 320,
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
    final titleFontSize = context.isMobile ? 16.0 : 17.0;
    final subtitleFontSize = context.isMobile ? 12.0 : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(context.responsivePadding),
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
                    padding: EdgeInsets.all(context.isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_search,
                      color: const Color(0xFF1565C0),
                      size: context.responsiveIconSize(24),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paso 1: Selecciona un Docente',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(titleFontSize),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: context.responsiveSpacing * 0.3),
                        Text(
                          'Elige el docente con quien deseas agendar',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(subtitleFontSize),
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
          padding: EdgeInsets.all(context.responsiveSpacing),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar docente...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: context.responsiveFontSize(14),
              ),
              prefixIcon: Icon(
                Icons.search, 
                color: Colors.grey[600],
                size: context.responsiveIconSize(20),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear, 
                        size: context.responsiveIconSize(20),
                      ),
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
              contentPadding: EdgeInsets.symmetric(
                vertical: context.isMobile ? 10 : 12,
              ),
            ),
            style: TextStyle(fontSize: context.responsiveFontSize(14)),
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
                          Icon(
                            Icons.search_off, 
                            size: context.isMobile ? 48 : 64, 
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: context.responsiveSpacing),
                          Text(
                            'No se encontraron docentes',
                            style: TextStyle(
                              fontSize: context.responsiveFontSize(16),
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _docentesFiltrados.length,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing * 0.7,
                        vertical: context.responsiveSpacing * 0.3,
                      ),
                      itemBuilder: (context, index) {
                        final docente = _docentesFiltrados[index];
                        final isSelected =
                            _docenteSeleccionado?['_id'] == docente['_id'];

                        return Padding(
                          padding: EdgeInsets.only(bottom: context.responsiveSpacing * 0.7),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: context.isMobile ? 10 : 12,
                                vertical: context.isMobile ? 6 : 8,
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
                                  radius: context.isMobile ? 24 : 28,
                                  backgroundColor: Colors.grey[200],
                                ),
                              ),
                              title: Text(
                                docente['nombreDocente'] ?? 'Sin nombre',
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(15),
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
                                      size: context.responsiveIconSize(14),
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        docente['oficinaDocente'] ?? 'Sin oficina',
                                        style: TextStyle(
                                          fontSize: context.responsiveFontSize(12),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.all(context.isMobile ? 6 : 8),
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
                                  size: context.responsiveIconSize(24),
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
              padding: EdgeInsets.all(context.isMobile ? 24 : 32),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_search, 
                size: context.isMobile ? 60 : 80, 
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 2),
            Text(
              'Selecciona un docente',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.7),
            Text(
              'Podrás ver su disponibilidad\ny agendar una tutoría',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
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
              padding: EdgeInsets.all(context.responsivePadding),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: context.responsiveSpacing * 2),
            Text(
              'Cargando disponibilidad...',
              style: TextStyle(
                fontSize: context.responsiveFontSize(16),
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
          padding: EdgeInsets.all(context.responsivePadding),
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
                    padding: EdgeInsets.all(context.isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.event_available,
                      color: const Color(0xFF1565C0),
                      size: context.responsiveIconSize(24),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paso 2: Selecciona Horario',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(17),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        SizedBox(height: context.responsiveSpacing * 0.3),
                        Text(
                          'Elige un día y horario disponible',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(13),
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsiveSpacing),
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
              SizedBox(height: context.responsiveSpacing),
              
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
                      radius: context.isMobile ? 28 : 32,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: NetworkImage(
                        _docenteSeleccionado!['avatarDocente'] ??
                            'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                      ),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _docenteSeleccionado!['nombreDocente'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(18),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: context.responsiveSpacing * 0.5),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on, 
                              size: context.responsiveIconSize(16), 
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _docenteSeleccionado!['oficinaDocente'] ?? 'Sin oficina',
                                style: TextStyle(
                                  fontSize: context.responsiveFontSize(14),
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
                SizedBox(height: context.responsiveSpacing),
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
                SizedBox(height: context.responsiveSpacing),
                
                Row(
                  children: [
                    Icon(
                      Icons.book, 
                      size: context.responsiveIconSize(20), 
                      color: Colors.blue[700],
                    ),
                    SizedBox(width: context.responsiveSpacing * 0.7),
                    Text(
                      'Materia:',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing * 0.8),
                
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.isMobile ? 10 : 12, 
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _materiaSeleccionada,
                      isExpanded: true,
                      icon: Icon(
                        Icons.arrow_drop_down, 
                        color: Colors.blue[700],
                        size: context.responsiveIconSize(24),
                      ),
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
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
                        padding: EdgeInsets.all(context.isMobile ? 24 : 32),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.event_busy, 
                          size: context.isMobile ? 60 : 80, 
                          color: Colors.orange[300],
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing * 2),
                      Text(
                        'Sin horarios disponibles',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(18),
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: context.responsiveSpacing * 0.7),
                      Text(
                        'Este docente no tiene\nhorarios registrados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(14),
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: EdgeInsets.all(context.responsivePadding),
                  children: _diasSemana.map((dia) {
                    final bloques = _obtenerBloquesPorDia(dia);
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.getBorderRadius(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(context.responsivePadding),
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
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(
                                  ResponsiveHelper.getBorderRadius(context),
                                ),
                                topRight: Radius.circular(
                                  ResponsiveHelper.getBorderRadius(context),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(context.isMobile ? 6 : 8),
                                  decoration: BoxDecoration(
                                    color: bloques.isNotEmpty
                                        ? const Color(0xFF1565C0).withOpacity(0.2)
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today,
                                    size: context.responsiveIconSize(18),
                                    color: bloques.isNotEmpty
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey[600],
                                  ),
                                ),
                                SizedBox(width: context.responsiveSpacing),
                                Text(
                                  dia,
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(16),
                                    fontWeight: FontWeight.bold,
                                    color: bloques.isNotEmpty
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey[600],
                                  ),
                                ),
                                const Spacer(),
                                if (bloques.isNotEmpty)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.isMobile ? 8 : 10,
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
                                        Icon(
                                          Icons.check_circle,
                                          size: context.responsiveIconSize(14),
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${bloques.length} ${bloques.length == 1 ? "bloque" : "bloques"}',
                                          style: TextStyle(
                                            fontSize: context.responsiveFontSize(11),
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.isMobile ? 8 : 10,
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
                                          size: context.responsiveIconSize(14),
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sin horarios',
                                          style: TextStyle(
                                            fontSize: context.responsiveFontSize(11),
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
                              padding: EdgeInsets.all(context.responsivePadding),
                              child: Center(
                                child: Text(
                                  'No hay horarios disponibles este día',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(14),
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
                                  bottomLeft: isLast 
                                    ? Radius.circular(
                                        ResponsiveHelper.getBorderRadius(context),
                                      ) 
                                    : Radius.zero,
                                  bottomRight: isLast 
                                    ? Radius.circular(
                                        ResponsiveHelper.getBorderRadius(context),
                                      ) 
                                    : Radius.zero,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: context.responsivePadding,
                                    vertical: context.isMobile ? 12 : 14,
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
                                        padding: EdgeInsets.all(context.isMobile ? 8 : 10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.green[400]!.withOpacity(0.2),
                                              Colors.green[300]!.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.schedule,
                                          color: Colors.green,
                                          size: context.responsiveIconSize(24),
                                        ),
                                      ),
                                      SizedBox(width: context.responsiveSpacing),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: context.responsiveFontSize(16),
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                SizedBox(width: context.responsiveSpacing * 0.7),
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
                                                      fontSize: context.responsiveFontSize(10),
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
                                                  size: context.responsiveIconSize(12),
                                                  color: Colors.grey[500],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Toca para agendar tu tutoría',
                                                  style: TextStyle(
                                                    fontSize: context.responsiveFontSize(12),
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: context.responsiveSpacing * 0.7),
                                      Container(
                                        padding: EdgeInsets.all(context.isMobile ? 4 : 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1565C0).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.arrow_forward_ios,
                                          size: context.responsiveIconSize(14),
                                          color: const Color(0xFF1565C0),
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