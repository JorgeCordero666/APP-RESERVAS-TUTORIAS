// lib/servicios/horario_service.dart - VERSIÓN ULTRA CORREGIDA
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
      print('   Docente: $docenteId');
      print('   Materia: $materia');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ VALIDAR ESTRUCTURA
        if (!data.containsKey('disponibilidad')) {
          print('⚠️ Respuesta sin campo "disponibilidad"');
          return [];
        }

        final List<dynamic> disponibilidad = data['disponibilidad'] ?? [];
        
        print('📊 Registros recibidos: ${disponibilidad.length}');
        
        // ✅ CONVERTIR A FORMATO PLANO
        List<Map<String, dynamic>> todosLosBloques = [];
        
        for (var disp in disponibilidad) {
          final dia = _capitalizarDia(disp['diaSemana'] ?? '');
          final bloques = disp['bloques'] as List? ?? [];
          
          print('📅 Procesando: $dia con ${bloques.length} bloques');
          
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
        print('   Body: ${response.body}');
        return null;
      }
      
    } catch (e) {
      print('❌ Exception en obtenerHorariosPorMateria: $e');
      return null;
    }
  }

  /// ✅ MÉTODO 2: Actualizar horarios (ELIMINA ANTERIORES Y CREA NUEVOS)
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

      // ✅ PASO 1: ELIMINAR DISPONIBILIDAD ANTERIOR
      print('🗑️ Eliminando disponibilidad anterior de: $materia');
      
      final diasUnicos = bloques.map((b) => b['dia'].toString().toLowerCase()).toSet();
      
      for (var dia in diasUnicos) {
        final deleteUrl = '${ApiConfig.baseUrl}/eliminar-disponibilidad-materia/$docenteId/${Uri.encodeComponent(materia)}/$dia';
        
        print('   Eliminando: $dia');
        
        try {
          await http.delete(
            Uri.parse(deleteUrl),
            headers: ApiConfig.getHeaders(token: token),
          );
        } catch (e) {
          print('   ⚠️ No se pudo eliminar $dia (quizá no existía): $e');
        }
      }

      // ✅ PASO 2: AGRUPAR BLOQUES POR DÍA
      Map<String, List<Map<String, String>>> bloquesPorDia = {};
      
      for (var bloque in bloques) {
        final dia = bloque['dia'].toString().toLowerCase();
        
        if (!bloquesPorDia.containsKey(dia)) {
          bloquesPorDia[dia] = [];
        }
        
        bloquesPorDia[dia]!.add({
          'horaInicio': bloque['horaInicio'].toString(),
          'horaFin': bloque['horaFin'].toString(),
        });
      }

      print('📝 Guardando nueva disponibilidad:');
      print('   Materia: $materia');
      print('   Días: ${bloquesPorDia.keys.join(", ")}');

      // ✅ PASO 3: GUARDAR CADA DÍA
      final url = '${ApiConfig.baseUrl}/tutorias/registrar-disponibilidad-materia';
      
      for (var entrada in bloquesPorDia.entries) {
        final dia = entrada.key;
        final bloquesDelDia = entrada.value;
        
        final body = {
          'materia': materia,
          'diaSemana': dia,
          'bloques': bloquesDelDia,
        };

        print('📤 Enviando: $dia con ${bloquesDelDia.length} bloques');

        final response = await http.post(
          Uri.parse(url),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode(body),
        );

        print('   Status: ${response.statusCode}');

        if (response.statusCode != 200) {
          final error = jsonDecode(response.body);
          print('❌ Error guardando $dia: ${error['msg']}');
          return false;
        }
      }

      print('✅ Todos los horarios guardados exitosamente');
      return true;
      
    } catch (e) {
      print('❌ Exception en actualizarHorarios: $e');
      return false;
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

  /// ✅ MÉTODO AUXILIAR: Capitalizar día
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