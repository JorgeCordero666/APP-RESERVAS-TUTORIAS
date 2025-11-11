import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../servicios/auth_service.dart';
import '../../servicios/materia_service.dart';
import '../../servicios/docente_service.dart';

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

  // ✅ PASO 1: Inicialización con validación
  Future<void> _inicializarPantalla() async {
    print('\n🚀 === INICIALIZANDO PANTALLA DE MATERIAS ===');
    
    // 1. Validar materias actuales del docente
    await _validarMateriasDocente();
    
    // 2. Cargar materias disponibles de la BD
    await _cargarMateriasDisponibles();
    
    print('=== FIN INICIALIZACIÓN ===\n');
  }

  // ✅ PASO 2: Validar que las materias del docente existan
  Future<void> _validarMateriasDocente() async {
    print('🔍 Validando materias del docente...');
    
    final resultado = await DocenteService.validarMaterias(_usuarioActual.id);
    
    if (resultado != null && !resultado.containsKey('error')) {
      final List<dynamic> materiasValidas = resultado['materiasValidas'] ?? [];
      final bool fueronEliminadas = resultado['fueronEliminadas'] ?? false;
      
      if (fueronEliminadas) {
        print('⚠️ Se detectaron materias eliminadas, sincronizando...');
        
        // Actualizar localmente
        _materiasSeleccionadas = materiasValidas.map((m) => m.toString()).toList();
        
        // Obtener perfil actualizado del backend
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
      // Cargar desde el usuario actual
      _materiasSeleccionadas = List.from(_usuarioActual.asignaturas ?? []);
      print('⚠️ No se pudo validar, usando materias locales');
    }
  }

  // ✅ PASO 3: Cargar SOLO materias activas de la BD
  Future<void> _cargarMateriasDisponibles() async {
    setState(() => _cargandoMaterias = true);

    try {
      print('📚 Cargando materias activas de la BD...');
      
      // ✅ CRÍTICO: Solo traer materias ACTIVAS
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
        
        // ✅ VALIDAR: Eliminar materias seleccionadas que ya no existen
        final todasLasMaterias = materiasAgrupadas.values
            .expand((lista) => lista)
            .toSet();
        
        final materiasInvalidas = _materiasSeleccionadas
            .where((m) => !todasLasMaterias.contains(m))
            .toList();
        
        if (materiasInvalidas.isNotEmpty) {
          print('⚠️ Materias inválidas detectadas: ${materiasInvalidas.join(", ")}');
          
          _materiasSeleccionadas.removeWhere((m) => materiasInvalidas.contains(m));
          
          if (mounted) {
            _mostrarAdvertencia(
              'Se eliminaron ${materiasInvalidas.length} materia(s) que ya no están disponibles'
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

  // ✅ PASO 4: Guardar con validación final
  Future<void> _guardarCambios() async {
    if (_materiasSeleccionadas.isEmpty) {
      _mostrarError('Debes seleccionar al menos una materia');
      return;
    }

    print('\n💾 === GUARDANDO CAMBIOS ===');
    print('   Materias seleccionadas: ${_materiasSeleccionadas.join(", ")}');

    // ✅ VALIDACIÓN PRE-GUARDADO: Verificar que todas las materias existan
    final todasLasMaterias = _materiasDisponibles.values
        .expand((lista) => lista)
        .toSet();
    
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
        
        // ✅ Actualizar usuario en memoria y SharedPreferences
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
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarInfo(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarAdvertencia(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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
              title: const Text('¿Descartar cambios?'),
              content: const Text(
                'Tienes cambios sin guardar. ¿Deseas salir de todas formas?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Salir sin guardar'),
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
        appBar: AppBar(
          title: const Text('Mis Materias'),
          backgroundColor: const Color(0xFF1565C0),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _cargandoMaterias ? null : () {
                _validarMateriasDocente();
                _cargarMateriasDisponibles();
              },
              tooltip: 'Recargar materias',
            ),
            if (_hasChanges && !_isLoading)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _guardarCambios,
                tooltip: 'Guardar cambios',
              ),
          ],
        ),
        body: _cargandoMaterias
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando materias disponibles...'),
                  ],
                ),
              )
            : _materiasDisponibles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.orange[300],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No hay materias disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'El administrador debe crear materias primero',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            _validarMateriasDocente();
                            _cargarMateriasDisponibles();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        color: Colors.blue[50],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Selecciona las materias que impartes este semestre',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1565C0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_materiasSeleccionadas.length} materias seleccionadas',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Buscador
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar materia o semestre',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),

                      // Lista
                      Expanded(
                        child: materiasFiltradas.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, 
                                      size: 80, 
                                      color: Colors.grey[400]
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No se encontraron materias',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: materiasFiltradas.length,
                                itemBuilder: (context, index) {
                                  final entry = materiasFiltradas[index];
                                  final semestre = entry.key;
                                  final materia = entry.value;
                                  final isSelected = _materiasSeleccionadas.contains(materia);
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: CheckboxListTile(
                                      title: Text(
                                        materia,
                                        style: TextStyle(
                                          fontWeight: isSelected 
                                            ? FontWeight.w600 
                                            : FontWeight.normal,
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        semestre,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      value: isSelected,
                                      activeColor: const Color(0xFF1565C0),
                                      onChanged: (value) => _toggleMateria(materia),
                                      controlAffinity: ListTileControlAffinity.leading,
                                      secondary: isSelected
                                          ? Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1565C0)
                                                  .withOpacity(0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF1565C0),
                                                size: 20,
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                      ),

                      // Botón guardar
                      if (_hasChanges)
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
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _guardarCambios,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
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
                                      'Guardar Cambios',
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