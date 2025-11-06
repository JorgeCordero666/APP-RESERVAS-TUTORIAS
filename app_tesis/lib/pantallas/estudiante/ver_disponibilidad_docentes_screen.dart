// lib/pantallas/estudiante/ver_disponibilidad_docentes_screen.dart - VERSIÓN CORREGIDA
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
    print('📥 Cargando disponibilidad de: ${docente['nombreDocente']}');
    print('   ID: ${docente['_id']}');

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
        // ✅ Normalizar días a formato consistente (Capitalizado)
        Map<String, List<Map<String, dynamic>>>? disponibilidadNormalizada;
        
        if (disponibilidad != null && disponibilidad.isNotEmpty) {
          disponibilidadNormalizada = {};
          
          disponibilidad.forEach((materia, bloques) {
            print('📚 Materia: $materia - ${bloques.length} bloques');
            
            // Normalizar cada bloque
            List<Map<String, dynamic>> bloquesNormalizados = bloques.map((bloque) {
              // ✅ Capitalizar día (lunes -> Lunes)
              String diaOriginal = bloque['dia'] ?? '';
              String diaNormalizado = _capitalizarDia(diaOriginal);
              
              if (diaOriginal != diaNormalizado) {
                print('🔄 Capitalización: "$diaOriginal" -> "$diaNormalizado"');
              }
              
              return {
                'dia': diaNormalizado,
                'horaInicio': bloque['horaInicio'],
                'horaFin': bloque['horaFin'],
              };
            }).toList();
            
            disponibilidadNormalizada![materia] = bloquesNormalizados;
          });
        }

        setState(() {
          _disponibilidad = disponibilidadNormalizada;
          _isLoadingDisponibilidad = false;
          
          // Seleccionar primera materia si existe
          if (_disponibilidad != null && _disponibilidad!.isNotEmpty) {
            _materiaSeleccionada = _disponibilidad!.keys.first;
            print('✅ Materia seleccionada: $_materiaSeleccionada');
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

  // ✅ Capitalizar día correctamente
  String _capitalizarDia(String dia) {
    if (dia.isEmpty) return dia;
    
    final diaLower = dia.toLowerCase().trim();
    
    // Mapa de días en español
    final mapaCapitalizacion = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miércoles': 'Miércoles',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sábado': 'Sábado',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };
    
    return mapaCapitalizacion[diaLower] ?? 
           (dia[0].toUpperCase() + dia.substring(1).toLowerCase());
  }

  // ✅ Obtener bloques por día (con normalización case-insensitive)
  List<Map<String, dynamic>> _obtenerBloquesPorDia(String dia) {
    if (_disponibilidad == null || _materiaSeleccionada == null) {
      return [];
    }

    final bloques = _disponibilidad![_materiaSeleccionada!] ?? [];
    final diaNormalizado = _capitalizarDia(dia);
    
    print('🔍 Filtrando bloques para día: "$diaNormalizado"');
    print('   Total bloques disponibles: ${bloques.length}');
    
    final resultado = bloques.where((bloque) {
      final bloqueNormalizado = _capitalizarDia(bloque['dia'] ?? '');
      final coincide = bloqueNormalizado == diaNormalizado;
      
      if (!coincide) {
        print('   ❌ No coincide: "$bloqueNormalizado" vs "$diaNormalizado"');
      }
      
      return coincide;
    }).toList();
    
    // Ordenar por hora de inicio
    resultado.sort((a, b) => (a['horaInicio'] ?? '').compareTo(b['horaInicio'] ?? ''));
    
    print('📋 Bloques encontrados: ${resultado.length}');
    
    return resultado;
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
                                          if (value != null) {
                                            print('🔄 Cambiando materia a: $value');
                                            setState(() {
                                              _materiaSeleccionada = value;
                                            });
                                          }
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
                                            // Header del día
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
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.calendar_today,
                                                    size: 18,
                                                    color: const Color(0xFF1565C0),
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
                                            
                                            // Lista de bloques
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
                                                  contentPadding: const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  leading: Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.withOpacity(0.1),
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
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  subtitle: const Text(
                                                    'Disponible para tutoría',
                                                    style: TextStyle(fontSize: 12),
                                                  ),
                                                  // ✅ TRAILING SIMPLIFICADO (sin OutlinedButton que causa error)
                                                  trailing: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
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