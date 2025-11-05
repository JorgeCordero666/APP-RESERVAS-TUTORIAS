// lib/servicios/horario_service.dart - VERSIÓN CORREGIDA COMPLETA
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class HorarioService {
  /// ✅ Obtener horarios de una materia específica del docente
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

      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-materia/$docenteId/$materia';
      
      print('🔍 Obteniendo horarios:');
      print('   URL: $url');
      print('   Docente: $docenteId');
      print('   Materia: $materia');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> disponibilidad = data['disponibilidad'] ?? [];
        
        // ✅ Convertir estructura del backend a formato plano para la app
        List<Map<String, dynamic>> todosLosBloques = [];
        
        for (var disp in disponibilidad) {
          final dia = disp['diaSemana'];
          final bloques = disp['bloques'] as List;
          
          for (var bloque in bloques) {
            todosLosBloques.add({
              'dia': _capitalizarDia(dia), // ✅ Capitalizar al recibir
              'horaInicio': bloque['horaInicio'],
              'horaFin': bloque['horaFin'],
            });
          }
        }
        
        print('✅ Horarios obtenidos: ${todosLosBloques.length} bloques');
        print('📋 Bloques por día:');
        for (var bloque in todosLosBloques) {
          print('   ${bloque['dia']}: ${bloque['horaInicio']}-${bloque['horaFin']}');
        }
        
        return todosLosBloques;
        
      } else if (response.statusCode == 404) {
        print('ℹ️ No hay horarios registrados para esta materia');
        return [];
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Error obteniendo horarios: $e');
      return null;
    }
  }

  /// ✅ Actualizar horarios de una materia
  static Future<bool> actualizarHorarios({
    required String docenteId,
    required String materia,
    required List<Map<String, dynamic>> bloques,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token de autenticación');
        return false;
      }

      // ✅ AGRUPACIÓN: Por día de la semana (NORMALIZAR A MINÚSCULAS)
      Map<String, List<Map<String, String>>> bloquesPorDia = {};
      
      for (var bloque in bloques) {
        final dia = (bloque['dia'] as String).toLowerCase(); // ✅ Normalizar aquí
        
        if (!bloquesPorDia.containsKey(dia)) {
          bloquesPorDia[dia] = [];
        }
        
        bloquesPorDia[dia]!.add({
          'horaInicio': bloque['horaInicio'] as String,
          'horaFin': bloque['horaFin'] as String,
        });
      }

      print('📝 Actualizando horarios:');
      print('   Docente: $docenteId');
      print('   Materia: $materia');
      print('   Días con bloques: ${bloquesPorDia.keys.join(", ")}');

      // ✅ Guardar cada día por separado
      final url = '${ApiConfig.baseUrl}/tutorias/registrar-disponibilidad-materia';
      
      for (var entrada in bloquesPorDia.entries) {
        final dia = entrada.key;
        final bloquesDelDia = entrada.value;
        
        final body = {
          'materia': materia,
          'diaSemana': dia, // Ya está en minúsculas
          'bloques': bloquesDelDia,
        };

        print('📤 Enviando: $dia con ${bloquesDelDia.length} bloques');
        print('   Body: ${jsonEncode(body)}');

        final response = await http.post(
          Uri.parse(url),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode(body),
        );

        print('📬 Respuesta: ${response.statusCode}');
        print('📄 Body: ${response.body}');

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          print('❌ Error guardando $dia: ${error['msg']}');
          return false;
        }
      }

      print('✅ Todos los horarios guardados exitosamente');
      return true;
      
    } catch (e) {
      print('❌ Error actualizando horarios: $e');
      return false;
    }
  }

  /// ✅ Obtener disponibilidad completa de un docente (todas las materias)
  static Future<Map<String, List<Map<String, dynamic>>>?> obtenerDisponibilidadCompleta({
    required String docenteId,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token de autenticación');
        return null;
      }

      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-completa/$docenteId';

      print('🔍 Obteniendo disponibilidad completa:');
      print('   URL: $url');
      print('   Docente: $docenteId');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> materias = data['materias'] ?? {};
        
        // ✅ Convertir estructura del backend a formato esperado por la app
        Map<String, List<Map<String, dynamic>>> resultado = {};
        
        materias.forEach((materia, diasList) {
          List<Map<String, dynamic>> bloquesMat = [];
          
          for (var diaData in diasList) {
            final dia = diaData['diaSemana'];
            final bloques = diaData['bloques'] as List;
            
            for (var bloque in bloques) {
              bloquesMat.add({
                'dia': _capitalizarDia(dia), // ✅ Capitalizar al recibir
                'horaInicio': bloque['horaInicio'],
                'horaFin': bloque['horaFin'],
              });
            }
          }
          
          resultado[materia] = bloquesMat;
          
          // ✅ LOG DETALLADO
          print('📚 Materia: $materia');
          print('   Total bloques: ${bloquesMat.length}');
          for (var bloque in bloquesMat) {
            print('   - ${bloque['dia']}: ${bloque['horaInicio']}-${bloque['horaFin']}');
          }
        });
        
        print('✅ Disponibilidad completa obtenida: ${resultado.keys.length} materias');
        return resultado;
        
      } else {
        print('❌ Error del servidor: ${response.statusCode}');
        return null;
      }
      
    } catch (e) {
      print('❌ Error obteniendo disponibilidad completa: $e');
      return null;
    }
  }

  /// ✅ Método auxiliar para capitalizar día (CRUCIAL)
  static String _capitalizarDia(String dia) {
    if (dia.isEmpty) return dia;
    
    final diaLower = dia.toLowerCase().trim(); // ✅ Trim agregado
    
    // ✅ Mapa de normalización completo
    final mapaCapitalizacion = {
      'lunes': 'Lunes',
      'martes': 'Martes',
      'miércoles': 'Miércoles',
      'miercoles': 'Miércoles', // Sin acento también
      'jueves': 'Jueves',
      'viernes': 'Viernes',
      'sábado': 'Sábado',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };
    
    final resultado = mapaCapitalizacion[diaLower] ?? 
                      dia[0].toUpperCase() + dia.substring(1).toLowerCase();
    
    print('🔄 Capitalización: "$dia" -> "$resultado"');
    return resultado;
  }
}