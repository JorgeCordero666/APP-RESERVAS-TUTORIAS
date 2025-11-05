// lib/pantallas/admin/detalle_estudiante_screen.dart
import 'package:flutter/material.dart';
import '../../servicios/estudiante_service.dart';

class DetalleEstudianteScreen extends StatefulWidget {
  final String estudianteId;

  const DetalleEstudianteScreen({super.key, required this.estudianteId});

  @override
  State<DetalleEstudianteScreen> createState() => _DetalleEstudianteScreenState();
}

class _DetalleEstudianteScreenState extends State<DetalleEstudianteScreen> {
  Map<String, dynamic>? _estudiante;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDetalle();
  }

  Future<void> _cargarDetalle() async {
    setState(() => _isLoading = true);
    
    final resultado = await EstudianteService.detalleEstudiante(widget.estudianteId);
    
    setState(() {
      _estudiante = resultado;
      _isLoading = false;
    });

    if (resultado != null && resultado.containsKey('error')) {
      _mostrarError(resultado['error']);
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

  String _formatearFecha(String? fecha) {
    if (fecha == null) return 'No especificado';
    try {
      final date = DateTime.parse(fecha);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Estudiante'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _estudiante == null || _estudiante!.containsKey('error')
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 80, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _estudiante?['error'] ?? 'Error al cargar datos',
                        style: const TextStyle(fontSize: 16),
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
                      // Foto de perfil
                      Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: NetworkImage(
                            _estudiante!['fotoPerfil'] ??
                                'https://cdn-icons-png.flaticon.com/512/4715/4715329.png',
                          ),
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      Text(
                        _estudiante!['nombreEstudiante'] ?? 'Sin nombre',
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
                            _estudiante!['status'] == true ? 'Activo' : 'Inactivo',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: _estudiante!['status'] == true
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Email confirmado
                      Center(
                        child: Chip(
                          label: Text(
                            _estudiante!['confirmEmail'] == true 
                                ? 'Email Confirmado' 
                                : 'Email Pendiente',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          backgroundColor: _estudiante!['confirmEmail'] == true
                              ? Colors.blue
                              : Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Información personal
                      _buildSeccion('Información Personal', [
                        _buildItem('Email', _estudiante!['emailEstudiante']),
                        _buildItem('Teléfono', _estudiante!['telefono'] ?? 'No especificado'),
                        _buildItem('Rol', _estudiante!['rol']),
                      ]),
                      const SizedBox(height: 16),

                      // Información de cuenta
                      _buildSeccion('Información de Cuenta', [
                        _buildItem('Fecha de registro', _formatearFecha(_estudiante!['createdAt'])),
                        _buildItem('Última actualización', _formatearFecha(_estudiante!['updatedAt'])),
                        _buildItem('Método de registro', 
                          _estudiante!['isOAuth'] == true 
                            ? 'OAuth (${_estudiante!['oauthProvider'] ?? 'N/A'})' 
                            : 'Email y contraseña'
                        ),
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

  Widget _buildItem(String label, String? value) {
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
              value ?? 'No especificado',
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
}