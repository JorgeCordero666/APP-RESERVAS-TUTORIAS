// lib/servicios/horario_service.dart - VERSIÓN DEFINITIVA CON VALIDACIONES
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class HorarioService {
  
  /// ✅ MÉTODO 1: Obtener horarios de UNA materia específica
  static Future<List<Map<String, dynamic>>?> obtenerHorariosPorMateria({
    required String docenteId,
    required String materia,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token de autenticación');
        return null;
      }

      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-materia/$docenteId/${Uri.encodeComponent(materia)}';
      
      print('🔍 [HorarioService] Obteniendo horarios:');
      print('   URL: $url');
      print('   Materia: $materia');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!data.containsKey('disponibilidad')) {
          print('⚠️ Respuesta sin campo "disponibilidad"');
          return [];
        }

        final List<dynamic> disponibilidad = data['disponibilidad'] ?? [];
        
        print('📊 Registros recibidos: ${disponibilidad.length}');
        
        // Convertir a formato plano
        List<Map<String, dynamic>> todosLosBloques = [];
        
        for (var disp in disponibilidad) {
          final dia = _capitalizarDia(disp['diaSemana'] ?? '');
          final bloques = disp['bloques'] as List? ?? [];
          
          for (var bloque in bloques) {
            todosLosBloques.add({
              'dia': dia,
              'horaInicio': bloque['horaInicio'] ?? '',
              'horaFin': bloque['horaFin'] ?? '',
            });
          }
        }
        
        print('✅ Total bloques procesados: ${todosLosBloques.length}');
        return todosLosBloques;
        
      } else if (response.statusCode == 404) {
        print('ℹ️ No hay horarios para esta materia');
        return [];
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Exception en obtenerHorariosPorMateria: $e');
      return null;
    }
  }

  /// 🔍 VALIDAR CRUCES INTERNOS (mismo día, misma materia)
  static Future<Map<String, dynamic>> validarCrucesInternos({
    required List<Map<String, dynamic>> bloques,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {
          'valido': false,
          'mensaje': 'No hay token de autenticación'
        };
      }

      final url = '${ApiConfig.baseUrl}/validar-cruces-horarios';
      
      final bloquesFormateados = bloques.map((b) => {
        'horaInicio': b['horaInicio'].toString(),
        'horaFin': b['horaFin'].toString(),
      }).toList();

      print('🔍 Validando cruces internos: ${bloquesFormateados.length} bloques');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({'bloques': bloquesFormateados}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'valido': data['valido'] ?? false,
          'mensaje': data['msg'] ?? ''
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'valido': false,
          'mensaje': error['msg'] ?? 'Error al validar'
        };
      }
      
    } catch (e) {
      print('❌ Error validando cruces internos: $e');
      return {
        'valido': false,
        'mensaje': 'Error de conexión: $e'
      };
    }
  }

  /// 🔍 VALIDAR CRUCES ENTRE MATERIAS
  static Future<Map<String, dynamic>> validarCrucesEntreMaterias({
    required String materia,
    required String diaSemana,
    required List<Map<String, dynamic>> bloques,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {
          'valido': false,
          'mensaje': 'No hay token de autenticación'
        };
      }

      final url = '${ApiConfig.baseUrl}/validar-cruces-materias';
      
      final bloquesFormateados = bloques.map((b) => {
        'horaInicio': b['horaInicio'].toString(),
        'horaFin': b['horaFin'].toString(),
      }).toList();

      print('🔍 Validando cruces con otras materias:');
      print('   Materia: $materia');
      print('   Día: $diaSemana');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'materia': materia,
          'diaSemana': diaSemana.toLowerCase(),
          'bloques': bloquesFormateados,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'valido': data['valido'] ?? false,
          'mensaje': data['msg'] ?? ''
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'valido': false,
          'mensaje': error['msg'] ?? 'Error al validar'
        };
      }
      
    } catch (e) {
      print('❌ Error validando cruces entre materias: $e');
      return {
        'valido': false,
        'mensaje': 'Error de conexión: $e'
      };
    }
  }

  /// ✅ MÉTODO 2: Actualizar horarios CON VALIDACIÓN PREVIA
  static Future<Map<String, dynamic>> actualizarHorarios({
    required String docenteId,
    required String materia,
    required List<Map<String, dynamic>> bloques,
    bool validarAntes = true, // ✅ Opción para validar antes de guardar
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'mensaje': 'No hay token de autenticación'
        };
      }

      print('🔄 Actualizando horarios:');
      print('   Materia: $materia');
      print('   Bloques: ${bloques.length}');
      print('   Validar antes: $validarAntes');

      // ✅ VALIDACIÓN OPCIONAL ANTES DE GUARDAR
      if (validarAntes && bloques.isNotEmpty) {
        print('🔍 Ejecutando validaciones previas...');
        
        // 1. Validar cruces internos (mismo día)
        final validacionInterna = await validarCrucesInternos(bloques: bloques);
        
        if (!validacionInterna['valido']) {
          print('❌ Validación interna falló: ${validacionInterna['mensaje']}');
          return {
            'success': false,
            'mensaje': validacionInterna['mensaje']
          };
        }
        
        print('✅ Sin cruces internos');
        
        // 2. Validar cruces entre materias por día
        final bloquesPorDia = _agruparPorDia(bloques);
        
        for (var entrada in bloquesPorDia.entries) {
          final dia = entrada.key;
          final bloquesDelDia = entrada.value;
          
          final validacionMaterias = await validarCrucesEntreMaterias(
            materia: materia,
            diaSemana: dia,
            bloques: bloquesDelDia,
          );
          
          if (!validacionMaterias['valido']) {
            print('❌ Validación en $dia falló: ${validacionMaterias['mensaje']}');
            return {
              'success': false,
              'mensaje': validacionMaterias['mensaje']
            };
          }
        }
        
        print('✅ Sin cruces con otras materias');
      }

      // ✅ GUARDAR EN EL BACKEND (usa el endpoint atómico)
      final url = '${ApiConfig.baseUrl}/tutorias/actualizar-horarios-materia';
      
      final body = {
        'materia': materia,
        'bloques': bloques.map((b) => {
          'dia': b['dia'].toString().toLowerCase(),
          'horaInicio': b['horaInicio'].toString(),
          'horaFin': b['horaFin'].toString(),
        }).toList(),
      };

      print('📤 Enviando al backend...');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(body),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Horarios actualizados exitosamente');
        print('   Eliminados: ${data['registrosEliminados']}');
        print('   Creados: ${data['registrosCreados']}');
        
        return {
          'success': true,
          'mensaje': data['msg'] ?? 'Horarios actualizados correctamente',
          'eliminados': data['registrosEliminados'],
          'creados': data['registrosCreados'],
        };
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error del backend: ${error['msg']}');
        return {
          'success': false,
          'mensaje': error['msg'] ?? 'Error al actualizar horarios'
        };
      }
      
    } catch (e) {
      print('❌ Exception en actualizarHorarios: $e');
      return {
        'success': false,
        'mensaje': 'Error de conexión: $e'
      };
    }
  }

  /// ✅ MÉTODO 3: Obtener disponibilidad completa (TODAS las materias)
  static Future<Map<String, List<Map<String, dynamic>>>?> obtenerDisponibilidadCompleta({
    required String docenteId,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token');
        return null;
      }

      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-completa/$docenteId';

      print('🔍 [Disponibilidad Completa] URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (!data.containsKey('materias')) {
          print('⚠️ Respuesta sin "materias"');
          return {};
        }

        final Map<String, dynamic> materias = data['materias'] ?? {};
        
        print('📚 Materias recibidas: ${materias.keys.join(", ")}');
        
        Map<String, List<Map<String, dynamic>>> resultado = {};
        
        materias.forEach((materia, diasList) {
          List<Map<String, dynamic>> bloquesMat = [];
          
          if (diasList is List) {
            for (var diaData in diasList) {
              final dia = _capitalizarDia(diaData['diaSemana'] ?? '');
              final bloques = diaData['bloques'] as List? ?? [];
              
              for (var bloque in bloques) {
                bloquesMat.add({
                  'dia': dia,
                  'horaInicio': bloque['horaInicio'] ?? '',
                  'horaFin': bloque['horaFin'] ?? '',
                });
              }
            }
          }
          
          resultado[materia] = bloquesMat;
          print('   📖 $materia: ${bloquesMat.length} bloques');
        });
        
        return resultado;
        
      } else {
        print('❌ Error: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Exception: $e');
      return null;
    }
  }

  /// 🔧 MÉTODO AUXILIAR: Agrupar bloques por día
  static Map<String, List<Map<String, dynamic>>> _agruparPorDia(
    List<Map<String, dynamic>> bloques
  ) {
    Map<String, List<Map<String, dynamic>>> resultado = {};
    
    for (var bloque in bloques) {
      final dia = bloque['dia'].toString().toLowerCase();
      
      if (!resultado.containsKey(dia)) {
        resultado[dia] = [];
      }
      
      resultado[dia]!.add({
        'horaInicio': bloque['horaInicio'],
        'horaFin': bloque['horaFin'],
      });
    }
    
    return resultado;
  }

  /// 🔧 MÉTODO AUXILIAR: Capitalizar día
  static String _capitalizarDia(String dia) {
    if (dia.isEmpty) return '';
    
    final diaLower = dia.toLowerCase().trim();
    
    final mapa = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miércoles': 'Miércoles',
      'miercoles': 'Miércoles',
      'jueves': 'Jueves',
      'viernes': 'Viernes',
    };
    
    return mapa[diaLower] ?? dia[0].toUpperCase() + dia.substring(1).toLowerCase();
  }
}