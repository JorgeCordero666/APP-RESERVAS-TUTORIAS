// lib/servicios/estudiante_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class EstudianteService {
  /// Listar todos los estudiantes (solo Admin)
  static Future<List<Map<String, dynamic>>> listarEstudiantes() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiantes'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> estudiantes = data['estudiantes'] ?? [];
        return estudiantes.map((est) => est as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error en listarEstudiantes: $e');
      return [];
    }
  }

  /// Obtener detalle de un estudiante
  static Future<Map<String, dynamic>?> detalleEstudiante(String id) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/estudiante/detalle/$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al obtener estudiante'};
      }
    } catch (e) {
      print('Error en detalleEstudiante: $e');
      return {'error': 'Error de conexión.'};
    }
  }

  /// Actualizar estudiante (Admin)
  static Future<Map<String, dynamic>?> actualizarEstudiante({
    required String id,
    required String nombreEstudiante,
    required String emailEstudiante,
    String? telefono,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/estudiante/actualizar/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'nombreEstudiante': nombreEstudiante,
          'emailEstudiante': emailEstudiante,
          if (telefono != null && telefono.isNotEmpty) 'telefono': telefono,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al actualizar estudiante'};
      }
    } catch (e) {
      print('Error en actualizarEstudiante: $e');
      return {'error': 'Error de conexión.'};
    }
  }

  /// Eliminar estudiante (deshabilitar)
  static Future<Map<String, dynamic>?> eliminarEstudiante({
    required String id,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/estudiante/eliminar/$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final error = jsonDecode(response.body);
        return {'error': error['msg'] ?? 'Error al eliminar estudiante'};
      }
    } catch (e) {
      print('Error en eliminarEstudiante: $e');
      return {'error': 'Error de conexión.'};
    }
  }
}