import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../servicios/auth_service.dart';

class GestionMateriasScreen extends StatefulWidget {
  final Usuario usuario;

  const GestionMateriasScreen({super.key, required this.usuario});

  @override
  State<GestionMateriasScreen> createState() => _GestionMateriasScreenState();
}

class _GestionMateriasScreenState extends State<GestionMateriasScreen> {
  // ✅ TODAS las materias disponibles (sin restricción por semestre)
  final Map<String, List<String>> _todasLasMaterias = {
    'Nivelación': [
      'Matemática Básica',
      'Física Básica',
      'Química Básica',
      'Introducción a la Programación',
      'Metodología de Estudio',
      'Comunicación Oral y Escrita',
    ],
    'Primer Semestre': [
      'Cálculo I',
      'Álgebra Lineal',
      'Física I',
      'Programación I',
      'Introducción a la Ingeniería',
      'Comunicación Técnica',
      'Fundamentos de Computación',
    ],
    'Segundo Semestre': [
      'Cálculo II',
      'Ecuaciones Diferenciales',
      'Física II',
      'Programación II',
      'Estructura de Datos',
      'Circuitos Eléctricos',
    ],
    'Tercer Semestre': [
      'Cálculo III',
      'Métodos Numéricos',
      'Electrónica Digital',
      'Base de Datos',
      'Arquitectura de Computadores',
      'Sistemas Operativos',
    ],
  };

  List<String> _materiasSeleccionadas = [];
  bool _isLoading = false;
  bool _hasChanges = false;
  late Usuario _usuarioActual;

  // ✅ Filtro de búsqueda
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _usuarioActual = widget.usuario;
    _cargarMateriasActuales();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _cargarMateriasActuales() {
    if (_usuarioActual.asignaturas != null) {
      _materiasSeleccionadas = List.from(_usuarioActual.asignaturas!);
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

  // ✅ Obtener todas las materias en una lista plana
  List<MapEntry<String, String>> _obtenerTodasLasMateriasConSemestre() {
    List<MapEntry<String, String>> resultado = [];
    
    _todasLasMaterias.forEach((semestre, materias) {
      for (var materia in materias) {
        resultado.add(MapEntry(semestre, materia));
      }
    });
    
    // Ordenar alfabéticamente por materia
    resultado.sort((a, b) => a.value.compareTo(b.value));
    
    return resultado;
  }

  // ✅ Filtrar materias por búsqueda
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

    setState(() => _isLoading = true);

    try {
      // ✅ Ya no enviamos semestre, solo las materias
      final resultado = await PerfilService.actualizarPerfilDocente(
        id: _usuarioActual.id,
        asignaturas: _materiasSeleccionadas,
        // ⭐ NO enviamos semestreAsignado
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (resultado != null && resultado.containsKey('error')) {
        _mostrarError(resultado['error']);
      } else {
        _mostrarExito('Materias actualizadas correctamente');
        
        // Actualizar usuario en SharedPreferences
        final usuarioActualizado = await AuthService.obtenerPerfil();
        
        if (usuarioActualizado != null && mounted) {
          setState(() {
            _usuarioActual = usuarioActualizado;
            _hasChanges = false;
            
            if (_usuarioActual.asignaturas != null) {
              _materiasSeleccionadas = List.from(_usuarioActual.asignaturas!);
            }
          });
          
          print('✅ Usuario actualizado en memoria y SharedPreferences');
          print('   Materias: ${_usuarioActual.asignaturas}');
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error al guardar: $e');
    }
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
            if (_hasChanges && !_isLoading)
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _guardarCambios,
                tooltip: 'Guardar cambios',
              ),
          ],
        ),
        body: Column(
          children: [
            // ✅ Header con información
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
                          'Selecciona todas las materias que impartes',
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

            // ✅ Buscador
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

            // ✅ Lista de materias
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

            // ✅ Botón guardar (siempre visible si hay cambios)
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