import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../servicios/auth_service.dart';
import '../../servicios/materia_service.dart';
import '../../servicios/docente_service.dart';
import '../../servicios/notification_service.dart';

class GestionMateriasScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionMateriasScreen({super.key, required this.usuario});

  @override
  State<GestionMateriasScreen> createState() => _GestionMateriasScreenState();
}

class _GestionMateriasScreenState extends State<GestionMateriasScreen> {
  Map<String, List<String>> _materiasDisponibles = {};
  List<String> _materiasSeleccionadas = [];
  bool _isLoading = false;
  bool _hasChanges = false;
  bool _cargandoMaterias = true;
  late Usuario _usuarioActual;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usuarioActual = widget.usuario;
    _inicializarPantalla();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _inicializarPantalla() async {
    print('\n🚀 === INICIALIZANDO PANTALLA DE MATERIAS ===');
    await _validarMateriasDocente();
    await _cargarMateriasDisponibles();
    print('=== FIN INICIALIZACIÓN ===\n');
  }

  Future<void> _validarMateriasDocente() async {
    print('🔍 Validando materias del docente...');

    final resultado = await DocenteService.validarMaterias(_usuarioActual.id);

    if (resultado != null && !resultado.containsKey('error')) {
      final List<dynamic> materiasValidas = resultado['materiasValidas'] ?? [];
      final bool fueronEliminadas = resultado['fueronEliminadas'] ?? false;

      if (fueronEliminadas) {
        print('⚠️ Se detectaron materias eliminadas, sincronizando...');
        _materiasSeleccionadas = materiasValidas.map((m) => m.toString()).toList();

        final usuarioActualizado = await AuthService.obtenerPerfil();

        if (usuarioActualizado != null) {
          await AuthService.actualizarUsuario(usuarioActualizado);
          _usuarioActual = usuarioActualizado;

          if (mounted) {
            _mostrarInfo('Se eliminaron materias que ya no existen en el sistema');
          }
        }
      } else {
        _materiasSeleccionadas = materiasValidas.map((m) => m.toString()).toList();
      }

      print('✅ Materias validadas: ${_materiasSeleccionadas.join(", ")}');
    } else {
      _materiasSeleccionadas = List.from(_usuarioActual.asignaturas ?? []);
      print('⚠️ No se pudo validar, usando materias locales');
    }
  }

  Future<void> _cargarMateriasDisponibles() async {
    setState(() => _cargandoMaterias = true);

    try {
      print('📚 Cargando materias activas de la BD...');

      final materiasAgrupadas = await MateriaService.obtenerMateriasAgrupadas();

      if (materiasAgrupadas.isEmpty) {
        print('⚠️ No hay materias activas en el sistema');
        if (mounted) {
          _mostrarError('No hay materias disponibles. Contacta al administrador.');
        }
      } else {
        print('✅ Materias disponibles cargadas:');
        materiasAgrupadas.forEach((semestre, materias) {
          print('   $semestre: ${materias.length} materias');
        });

        final todasLasMaterias = materiasAgrupadas.values.expand((lista) => lista).toSet();

        final materiasInvalidas = _materiasSeleccionadas
            .where((m) => !todasLasMaterias.contains(m))
            .toList();

        if (materiasInvalidas.isNotEmpty) {
          print('⚠️ Materias inválidas detectadas: ${materiasInvalidas.join(", ")}');

          _materiasSeleccionadas.removeWhere((m) => materiasInvalidas.contains(m));

          if (mounted) {
            _mostrarAdvertencia(
              'Se eliminaron ${materiasInvalidas.length} materia(s) que ya no están disponibles',
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _materiasDisponibles = materiasAgrupadas;
          _cargandoMaterias = false;
        });
      }
    } catch (e) {
      print('❌ Error cargando materias: $e');
      if (mounted) {
        setState(() => _cargandoMaterias = false);
        _mostrarError('Error al cargar materias: $e');
      }
    }
  }

  void _toggleMateria(String materia) {
    setState(() {
      if (_materiasSeleccionadas.contains(materia)) {
        _materiasSeleccionadas.remove(materia);
      } else {
        _materiasSeleccionadas.add(materia);
      }
      _hasChanges = true;
    });
  }

  List<MapEntry<String, String>> _obtenerTodasLasMateriasConSemestre() {
    List<MapEntry<String, String>> resultado = [];

    _materiasDisponibles.forEach((semestre, materias) {
      for (var materia in materias) {
        resultado.add(MapEntry(semestre, materia));
      }
    });

    resultado.sort((a, b) => a.value.compareTo(b.value));
    return resultado;
  }

  List<MapEntry<String, String>> _filtrarMaterias() {
    final todasMaterias = _obtenerTodasLasMateriasConSemestre();

    if (_searchQuery.isEmpty) {
      return todasMaterias;
    }

    return todasMaterias.where((entry) {
      return entry.value.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _guardarCambios() async {
    if (_materiasSeleccionadas.isEmpty) {
      _mostrarError('Debes seleccionar al menos una materia');
      return;
    }

    print('\n💾 === GUARDANDO CAMBIOS ===');
    print('   Materias seleccionadas: ${_materiasSeleccionadas.join(", ")}');

    final todasLasMaterias = _materiasDisponibles.values.expand((lista) => lista).toSet();
    
    final materiasInvalidas = _materiasSeleccionadas
        .where((m) => !todasLasMaterias.contains(m))
        .toList();
    
    if (materiasInvalidas.isNotEmpty) {
      print('❌ Materias inválidas detectadas: ${materiasInvalidas.join(", ")}');
      _mostrarError(
        'Las siguientes materias ya no existen: ${materiasInvalidas.join(", ")}'
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resultado = await PerfilService.actualizarPerfilDocente(
        id: _usuarioActual.id,
        asignaturas: _materiasSeleccionadas,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(resultado['error']);
      } else {
        _mostrarExito('Materias actualizadas correctamente');
        
        final usuarioActualizado = await AuthService.obtenerPerfil();
        
        if (usuarioActualizado != null && mounted) {
          await AuthService.actualizarUsuario(usuarioActualizado);
          
          setState(() {
            _usuarioActual = usuarioActualizado;
            _hasChanges = false;
            _materiasSeleccionadas = List.from(usuarioActualizado.asignaturas ?? []);
          });
          
          print('✅ Usuario actualizado en memoria y SharedPreferences');
          print('   Materias finales: ${_usuarioActual.asignaturas}');
          
          notificationService.notificarMateriasActualizadas();
          print('🔔 Notificación enviada: materias actualizadas');
        }
        
        print('=== FIN GUARDADO ===\n');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al guardar: $e');
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

  void _mostrarAdvertencia(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
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
        backgroundColor: const Color(0xFFF57C00),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        duration: const Duration(seconds: 4),
        elevation: 6,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final materiasFiltradas = _filtrarMaterias();

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[400]!, Colors.orange[600]!],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      '¿Descartar cambios?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tienes cambios sin guardar. ¿Deseas salir de todas formas?',
                  style: TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
              actionsPadding: const EdgeInsets.all(20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
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
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Salir sin guardar',
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

          if (confirmar != true) return false;
        }

        Navigator.pop(context, _usuarioActual);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Mis Materias',
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
            if (!_cargandoMaterias)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () {
                      _validarMateriasDocente();
                      _cargarMateriasDisponibles();
                    },
                    tooltip: 'Recargar materias',
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
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    onPressed: _guardarCambios,
                    tooltip: 'Guardar cambios',
                  ),
                ),
              ),
          ],
        ),
        body: _cargandoMaterias
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
                      'Cargando materias disponibles...',
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
            : _materiasDisponibles.isEmpty
                ? Center(
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
                              Icons.error_outline_rounded,
                              size: 90,
                              color: Colors.orange[500],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'No hay materias disponibles',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E3A5F),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'El administrador debe crear materias primero',
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
                              onTap: () {
                                _validarMateriasDocente();
                                _cargarMateriasDisponibles();
                              },
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
                                    Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'Reintentar',
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
                  )
                : Column(
                    children: [
                      // Header con contador mejorado
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
                                    Icons.info_outline_rounded,
                                    color: Color(0xFF1565C0),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Text(
                                    'Selecciona las materias que impartes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1E3A5F),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 11,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1565C0).withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.25),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Text(
                                    '${_materiasSeleccionadas.length} materias seleccionadas',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Buscador mejorado
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar materia o semestre...',
                              hintStyle: TextStyle(
                                color: Colors.grey[450],
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(12),
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF42A5F5).withOpacity(0.15),
                                      const Color(0xFF1E88E5).withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFF1565C0),
                                  size: 23,
                                ),
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      color: Colors.grey[500],
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2.5),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                      ),

                      // Lista de materias mejorada
                      Expanded(
                        child: materiasFiltradas.isEmpty
                            ? Center(
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
                                        Icons.search_off_rounded,
                                        size: 85,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 26),
                                    Text(
                                      'No se encontraron materias',
                                      style: TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[700],
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Intenta con otro término de búsqueda',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                itemCount: materiasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final entry = materiasFiltradas[index];
                                  final semestre = entry.key;
                                  final materia = entry.value;
                                  final isSelected = _materiasSeleccionadas.contains(materia);

                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF1565C0)
                                            : Colors.grey[200]!,
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF1565C0).withOpacity(0.2),
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _toggleMateria(materia),
                                        borderRadius: BorderRadius.circular(18),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Checkbox personalizado
                                              AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  gradient: isSelected
                                                      ? const LinearGradient(
                                                          colors: [
                                                            Color(0xFF42A5F5),
                                                            Color(0xFF1565C0),
                                                          ],
                                                        )
                                                      : null,
                                                  color: isSelected ? null : Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? Colors.transparent
                                                        : Colors.grey[400]!,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: isSelected
                                                    ? const Icon(
                                                        Icons.check_rounded,
                                                        color: Colors.white,
                                                        size: 18,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 16),
                                              
                                              // Contenido de la materia
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      materia,
                                                      style: TextStyle(
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                        fontSize: 15.5,
                                                        color: isSelected
                                                            ? const Color(0xFF1E3A5F)
                                                            : Colors.grey[800],
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
                                                        color: isSelected
                                                            ? const Color(0xFF1565C0).withOpacity(0.12)
                                                            : Colors.grey[100],
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        semestre,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: isSelected
                                                              ? const Color(0xFF1565C0)
                                                              : Colors.grey[600],
                                                          letterSpacing: 0.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // Indicador de selección
                                              if (isSelected)
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        const Color(0xFF42A5F5).withOpacity(0.15),
                                                        const Color(0xFF1565C0).withOpacity(0.15),
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.check_circle_rounded,
                                                    color: Color(0xFF1565C0),
                                                    size: 22,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Botón guardar mejorado
                      if (_hasChanges)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isLoading ? null : _guardarCambios,
                                borderRadius: BorderRadius.circular(18),
                                child: Ink(
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: _isLoading
                                        ? LinearGradient(
                                            colors: [
                                              Colors.grey[400]!,
                                              Colors.grey[500]!,
                                            ],
                                          )
                                        : const LinearGradient(
                                            colors: [
                                              Color(0xFF43A047),
                                              Color(0xFF2E7D32),
                                            ],
                                          ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: _isLoading
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: const Color(0xFF43A047).withOpacity(0.4),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 26,
                                            width: 26,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.save_rounded,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Guardar Cambios',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
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