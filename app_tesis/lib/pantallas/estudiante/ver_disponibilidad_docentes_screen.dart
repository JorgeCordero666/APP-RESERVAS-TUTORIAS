// lib/pantallas/estudiante/ver_disponibilidad_docentes_screen.dart
import 'package:flutter/material.dart';
import '../../modelos/usuario.dart';
import '../../servicios/docente_service.dart';
import '../../servicios/horario_service.dart';

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
  Map<String, dynamic>? _docenteSeleccionado;
  Map<String, List<Map<String, dynamic>>>? _disponibilidad;
  bool _isLoadingDocentes = true;
  bool _isLoadingDisponibilidad = false;
  String? _materiaSeleccionada;

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

  Future<void> _cargarDisponibilidad(Map<String, dynamic> docente) async {
    setState(() {
      _docenteSeleccionado = docente;
      _isLoadingDisponibilidad = true;
      _disponibilidad = null;
      _materiaSeleccionada = null;
    });

    try {
      final disponibilidad =
          await HorarioService.obtenerDisponibilidadCompleta(
        docenteId: docente['_id'],
      );

      if (mounted) {
        setState(() {
          _disponibilidad = disponibilidad;
          _isLoadingDisponibilidad = false;
          
          // Seleccionar primera materia si existe
          if (disponibilidad != null && disponibilidad.isNotEmpty) {
            _materiaSeleccionada = disponibilidad.keys.first;
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
    return bloques.where((bloque) => bloque['dia'] == dia).toList()
      ..sort((a, b) => a['horaInicio'].compareTo(b['horaInicio']));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad de Docentes'),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Row(
        children: [
          // Panel izquierdo: Lista de docentes
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: const Text(
                    'Docentes Disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
                Expanded(
                  child: _isLoadingDocentes
                      ? const Center(child: CircularProgressIndicator())
                      : _docentes.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay docentes disponibles',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              itemCount: _docentes.length,
                              itemBuilder: (context, index) {
                                final docente = _docentes[index];
                                final isSelected = _docenteSeleccionado?['_id'] ==
                                    docente['_id'];

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
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
                                    ),
                                    title: Text(
                                      docente['nombreDocente'] ?? 'Sin nombre',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    subtitle: Text(
                                      docente['oficinaDocente'] ?? 'Sin oficina',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
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
            ),
          ),

          // Panel derecho: Disponibilidad del docente seleccionado
          Expanded(
            child: _docenteSeleccionado == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_search,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selecciona un docente',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'para ver su disponibilidad',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _isLoadingDisponibilidad
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Header con info del docente
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _docenteSeleccionado![
                                                    'nombreDocente'] ??
                                                'Sin nombre',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Oficina: ${_docenteSeleccionado!['oficinaDocente'] ?? 'No especificada'}',
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
                                
                                // Selector de materia
                                if (_disponibilidad != null &&
                                    _disponibilidad!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Materia:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _materiaSeleccionada,
                                        isExpanded: true,
                                        items: _disponibilidad!.keys
                                            .map((materia) {
                                          return DropdownMenuItem(
                                            value: materia,
                                            child: Text(materia),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _materiaSeleccionada = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Horarios por día
                          Expanded(
                            child: _disponibilidad == null ||
                                    _disponibilidad!.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 80,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Este docente no tiene',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                        const Text(
                                          'horarios registrados',
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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF1565C0)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                dia,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1565C0),
                                                ),
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
                                                return ListTile(
                                                  leading: Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(
                                                      Icons.schedule,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  title: Text(
                                                    '${bloque['horaInicio']} - ${bloque['horaFin']}',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  subtitle: const Text(
                                                    'Disponible para tutoría',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  trailing: OutlinedButton(
                                                    onPressed: () {
                                                      // TODO: Implementar agendar tutoría
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Función de agendar próximamente',
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: const Text('Agendar'),
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
                      ),
          ),
        ],
      ),
    );
  }
}