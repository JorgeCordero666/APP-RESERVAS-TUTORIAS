// lib/servicios/horario_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class HorarioService {
  /// Obtener horarios de una materia específica del docente
  static Future<List<Map<String, dynamic>>?> obtenerHorariosPorMateria({
    required String docenteId,
    required String materia,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return null;
      }

      // ⭐ Usando endpoint existente modificado
      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-materia/$docenteId/$materia';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> disponibilidad = data['disponibilidad'] ?? [];
        
        // Aplanar la estructura: convertir [{diaSemana, bloques[]}] a una lista plana
        List<Map<String, dynamic>> todosLosBloques = [];
        for (var disp in disponibilidad) {
          final dia = disp['diaSemana'];
          final bloques = disp['bloques'] as List;
          for (var bloque in bloques) {
            todosLosBloques.add({
              'dia': dia,
              'horaInicio': bloque['horaInicio'],
              'horaFin': bloque['horaFin'],
            });
          }
        }
        
        return todosLosBloques;
      } else if (response.statusCode == 404) {
        return [];
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo horarios: $e');
      return null;
    }
  }

  /// Actualizar horarios de una materia
  static Future<bool> actualizarHorarios({
    required String docenteId,
    required String materia,
    required List<Map<String, dynamic>> bloques,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return false;
      }

      // Agrupar bloques por día
      Map<String, List<Map<String, String>>> bloquesPorDia = {};
      for (var bloque in bloques) {
        final dia = bloque['dia'] as String;
        if (!bloquesPorDia.containsKey(dia)) {
          bloquesPorDia[dia] = [];
        }
        bloquesPorDia[dia]!.add({
          'horaInicio': bloque['horaInicio'] as String,
          'horaFin': bloque['horaFin'] as String,
        });
      }

      // Guardar cada día por separado
      for (var dia in bloquesPorDia.keys) {
        final url = '${ApiConfig.baseUrl}/tutorias/registrar-disponibilidad-materia';

        final response = await http.post(
          Uri.parse(url),
          headers: ApiConfig.getHeaders(token: token),
          body: jsonEncode({
            'materia': materia,
            'diaSemana': dia.toLowerCase(),
            'bloques': bloquesPorDia[dia],
          }),
        );

        if (response.statusCode != 200) {
          print('Error guardando día $dia: ${response.body}');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Error actualizando horarios: $e');
      return false;
    }
  }

  /// Obtener disponibilidad completa de un docente (todas las materias)
  static Future<Map<String, List<Map<String, dynamic>>>?> obtenerDisponibilidadCompleta({
    required String docenteId,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return null;
      }

      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-completa/$docenteId';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final Map<String, dynamic> materias = data['materias'] ?? {};
        
        // Convertir estructura del backend a formato esperado
        Map<String, List<Map<String, dynamic>>> resultado = {};
        
        materias.forEach((materia, diasList) {
          List<Map<String, dynamic>> bloquesMat = [];
          
          for (var diaData in diasList) {
            final dia = diaData['diaSemana'];
            final bloques = diaData['bloques'] as List;
            
            for (var bloque in bloques) {
              bloquesMat.add({
                'dia': dia,
                'horaInicio': bloque['horaInicio'],
                'horaFin': bloque['horaFin'],
              });
            }
          }
          
          resultado[materia] = bloquesMat;
        });
        
        return resultado;
      }
      
      return null;
    } catch (e) {
      print('Error obteniendo disponibilidad completa: $e');
      return null;
    }
  }
}