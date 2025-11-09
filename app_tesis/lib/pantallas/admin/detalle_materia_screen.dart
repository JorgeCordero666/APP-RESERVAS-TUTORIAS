// lib/pantallas/admin/detalle_materia_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/materia.dart';
import '../../servicios/materia_service.dart';
import 'package:intl/intl.dart';

class DetalleMateriaScreen extends StatefulWidget {
  final String materiaId;

  const DetalleMateriaScreen({super.key, required this.materiaId});

  @override
  State<DetalleMateriaScreen> createState() => _DetalleMateriaScreenState();
}

class _DetalleMateriaScreenState extends State<DetalleMateriaScreen> {
  Materia? _materia;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _isLoading = true);
    
    final materia = await MateriaService.obtenerMateria(widget.materiaId);
    
    setState(() {
      _materia = materia;
      _isLoading = false;
    });

    if (materia == null && mounted) {
      _mostrarError('Error al cargar detalle de la materia');
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

  String _formatearFecha(DateTime fecha) {
    return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Materia'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materia == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error al cargar datos',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cargarDetalle,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarDetalle,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Header con código
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: _materia!.activa 
                                ? const Color(0xFF1565C0).withOpacity(0.1)
                                : Colors.grey.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _materia!.codigo,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _materia!.activa 
                                    ? const Color(0xFF1565C0)
                                    : Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      Text(
                        _materia!.nombre,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Estado
                      Center(
                        child: Chip(
                          label: Text(
                            _materia!.activa ? 'Activa' : 'Inactiva',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _materia!.activa 
                              ? Colors.green 
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información académica
                      _buildSeccion('Información Académica', [
                        _buildItem('Código', _materia!.codigo),
                        _buildItem('Semestre', _materia!.semestre),
                        _buildItem('Créditos', '${_materia!.creditos}'),
                        if (_materia!.descripcion != null && 
                            _materia!.descripcion!.isNotEmpty)
                          _buildItemLargo('Descripción', _materia!.descripcion!),
                      ]),
                      const SizedBox(height: 16),

                      // Información del sistema
                      _buildSeccion('Información del Sistema', [
                        _buildItem('Fecha de creación', 
                          _formatearFecha(_materia!.creadaEn)),
                        _buildItem('Última actualización', 
                          _formatearFecha(_materia!.actualizadaEn)),
                        _buildItem('ID', _materia!.id),
                      ]),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSeccion(String titulo, List<Widget> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemLargo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}