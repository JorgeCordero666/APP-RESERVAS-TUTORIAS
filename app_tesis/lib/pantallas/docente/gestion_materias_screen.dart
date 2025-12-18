import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/perfil_service.dart';
import '../../servicios/auth_service.dart';
import '../../servicios/materia_service.dart';
import '../../servicios/docente_service.dart';
import '../../servicios/notification_service.dart';
import '../../config/responsive_helper.dart';

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
    await _validarMateriasDocente();
    await _cargarMateriasDisponibles();
  }

  Future<void> _validarMateriasDocente() async {
    final resultado = await DocenteService.validarMaterias(_usuarioActual.id);

    if (resultado != null && !resultado.containsKey('error')) {
      final List<dynamic> materiasValidas = resultado['materiasValidas'] ?? [];
      final bool fueronEliminadas = resultado['fueronEliminadas'] ?? false;

      if (fueronEliminadas) {
        _materiasSeleccionadas = materiasValidas.map((m) => m.toString()).toList();
        final usuarioActualizado = await AuthService.obtenerPerfil();

        if (usuarioActualizado != null) {
          await AuthService.actualizarUsuario(usuarioActualizado);
          _usuarioActual = usuarioActualizado;
          if (mounted) _mostrarInfo('Materias eliminadas del sistema fueron sincronizadas');
        }
      } else {
        _materiasSeleccionadas = materiasValidas.map((m) => m.toString()).toList();
      }
    } else {
      _materiasSeleccionadas = List.from(_usuarioActual.asignaturas ?? []);
    }
  }

  Future<void> _cargarMateriasDisponibles() async {
    setState(() => _cargandoMaterias = true);

    try {
      final materiasAgrupadas = await MateriaService.obtenerMateriasAgrupadas();

      if (materiasAgrupadas.isEmpty && mounted) {
        _mostrarError('No hay materias disponibles');
      } else {
        final todasLasMaterias = materiasAgrupadas.values.expand((l) => l).toSet();
        final materiasInvalidas = _materiasSeleccionadas.where((m) => !todasLasMaterias.contains(m)).toList();

        if (materiasInvalidas.isNotEmpty) {
          _materiasSeleccionadas.removeWhere((m) => materiasInvalidas.contains(m));
          if (mounted) _mostrarAdvertencia('Se eliminaron ${materiasInvalidas.length} materias no disponibles');
        }
      }

      if (mounted) {
        setState(() {
          _materiasDisponibles = materiasAgrupadas;
          _cargandoMaterias = false;
        });
      }
    } catch (e) {
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

  List<MapEntry<String, String>> _filtrarMaterias() {
    List<MapEntry<String, String>> resultado = [];
    _materiasDisponibles.forEach((semestre, materias) {
      for (var materia in materias) resultado.add(MapEntry(semestre, materia));
    });
    resultado.sort((a, b) => a.value.compareTo(b.value));

    if (_searchQuery.isEmpty) return resultado;
    return resultado.where((e) =>
        e.value.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        e.key.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  Future<void> _guardarCambios() async {
    if (_materiasSeleccionadas.isEmpty) {
      _mostrarError('Selecciona al menos una materia');
      return;
    }

    final todasLasMaterias = _materiasDisponibles.values.expand((l) => l).toSet();
    final materiasInvalidas = _materiasSeleccionadas.where((m) => !todasLasMaterias.contains(m)).toList();
    
    if (materiasInvalidas.isNotEmpty) {
      _mostrarError('Materias inválidas: ${materiasInvalidas.join(", ")}');
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
          notificationService.notificarMateriasActualizadas();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError('Error: $e');
    }
  }

  void _mostrarError(String m) => _mostrarSnackBar(m, const Color(0xFFD32F2F), Icons.error_outline_rounded);
  void _mostrarExito(String m) => _mostrarSnackBar(m, const Color(0xFF43A047), Icons.check_circle_outline_rounded);
  void _mostrarInfo(String m) => _mostrarSnackBar(m, const Color(0xFF1976D2), Icons.info_outline_rounded);
  void _mostrarAdvertencia(String m) => _mostrarSnackBar(m, const Color(0xFFF57C00), Icons.warning_rounded);

  void _mostrarSnackBar(String mensaje, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: context.responsiveIconSize(24)),
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
    final materiasFiltradas = _filtrarMaterias();
    final isMobile = context.isMobile;
    final padding = context.responsivePadding;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final confirmar = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('¿Descartar cambios?'),
              content: const Text('Tienes cambios sin guardar'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: Text(
            'Mis Materias',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: context.responsiveFontSize(21),
            ),
          ),
          centerTitle: true,
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          actions: [
            if (!_cargandoMaterias)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  _validarMateriasDocente();
                  _cargarMateriasDisponibles();
                },
              ),
            if (_hasChanges && !_isLoading)
              IconButton(
                icon: const Icon(Icons.check_rounded),
                onPressed: _guardarCambios,
              ),
          ],
        ),
        body: _cargandoMaterias
            ? _buildLoadingState()
            : _materiasDisponibles.isEmpty
                ? _buildEmptyState()
                : _buildContent(materiasFiltradas, isMobile, padding),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: context.responsiveSpacing * 2),
          Text(
            'Cargando materias...',
            style: TextStyle(
              fontSize: context.responsiveFontSize(16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsivePadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, 
              size: context.responsiveIconSize(90), 
              color: Colors.orange),
            SizedBox(height: context.responsiveSpacing * 2),
            Text(
              'No hay materias disponibles',
              style: TextStyle(
                fontSize: context.responsiveFontSize(22),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing),
            Text(
              'El administrador debe crear materias',
              style: TextStyle(
                fontSize: context.responsiveFontSize(15),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<MapEntry<String, String>> materiasFiltradas, bool isMobile, double padding) {
    return Column(
      children: [
        // Header
        Container(
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
                      Icons.info_outline_rounded,
                      color: const Color(0xFF1565C0),
                      size: context.responsiveIconSize(24),
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing),
                  Expanded(
                    child: Text(
                      'Selecciona las materias que impartes',
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.responsiveSpacing),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: context.responsiveSpacing * 0.75),
                    Text(
                      '${_materiasSeleccionadas.length} materias seleccionadas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: context.responsiveFontSize(14),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Buscador
        Padding(
          padding: EdgeInsets.all(padding),
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: context.responsiveFontSize(15)),
            decoration: InputDecoration(
              hintText: 'Buscar materia o semestre...',
              prefixIcon: Icon(Icons.search_rounded, size: context.responsiveIconSize(23)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
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
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Lista
        Expanded(
          child: materiasFiltradas.isEmpty
              ? _buildNoResults()
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                  itemCount: materiasFiltradas.length,
                  itemBuilder: (context, index) {
                    final entry = materiasFiltradas[index];
                    return _buildMateriaCard(entry.key, entry.value, padding);
                  },
                ),
        ),

        // Botón guardar
        if (_hasChanges) _buildSaveButton(padding),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, 
            size: context.responsiveIconSize(85), 
            color: Colors.grey[400]),
          SizedBox(height: context.responsiveSpacing * 2),
          Text(
            'No se encontraron materias',
            style: TextStyle(
              fontSize: context.responsiveFontSize(19),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMateriaCard(String semestre, String materia, double padding) {
    final isSelected = _materiasSeleccionadas.contains(materia);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(bottom: context.responsiveSpacing),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? const Color(0xFF1565C0) : Colors.grey[200]!,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.2), blurRadius: 16, offset: Offset(0, 6))]
            : [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleMateria(materia),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: isSelected ? const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1565C0)]) : null,
                    color: isSelected ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.grey[400]!, width: 2),
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
                SizedBox(width: context.responsiveSpacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        materia,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: context.responsiveFontSize(15.5),
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1565C0).withOpacity(0.12) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          semestre,
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(12),
                            fontWeight: FontWeight.w600,
                            color: isSelected ? const Color(0xFF1565C0) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: const Color(0xFF1565C0), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: context.responsiveFontSize(56),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _guardarCambios,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, size: 22),
                      SizedBox(width: context.responsiveSpacing * 0.75),
                      Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: context.responsiveFontSize(16),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}