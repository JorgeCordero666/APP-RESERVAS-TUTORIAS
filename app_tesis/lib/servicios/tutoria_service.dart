// lib/servicios/tutoria_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class TutoriaService {
  
  /// ✅ AGENDAR TUTORÍA (ESTUDIANTE)
  static Future<Map<String, dynamic>?> agendarTutoria({
    required String docenteId,
    required String fecha,
    required String horaInicio,
    required String horaFin,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final url = '${ApiConfig.baseUrl}/tutoria/registro';
      print('📝 Agendando tutoría: $url');
      print('   Docente: $docenteId');
      print('   Fecha: $fecha');
      print('   Hora: $horaInicio - $horaFin');

      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'docente': docenteId,
          'fecha': fecha,
          'horaInicio': horaInicio,
          'horaFin': horaFin,
        }),
      );

      print('📬 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Tutoría agendada exitosamente');
        return data;
      } else {
        final data = jsonDecode(response.body);
        print('❌ Error: ${data['msg'] ?? data['mensaje']}');
        return {'error': data['msg'] ?? data['mensaje'] ?? 'Error al agendar tutoría'};
      }
    } catch (e) {
      print('❌ Error en agendarTutoria: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ LISTAR TUTORÍAS (DOCENTE O ESTUDIANTE)
/// ✅ LISTAR TUTORÍAS DEL USUARIO AUTENTICADO (CORREGIDO)
static Future<List<Map<String, dynamic>>> listarTutorias({
  String? estado,
  bool incluirCanceladas = false,
  bool soloSemanaActual = false,
}) async {
  try {
    final token = await AuthService.getToken();
    
    if (token == null) {
      print('❌ No hay token');
      return [];
    }

    // Construir URL con parámetros opcionales
    String url = '${ApiConfig.baseUrl}/tutorias';
    List<String> params = [];
    
    if (estado != null && estado.isNotEmpty) {
      params.add('estado=$estado');
    }
    
    if (incluirCanceladas) {
      params.add('incluirCanceladas=true');
    }
    
    if (soloSemanaActual) {
      params.add('soloSemanaActual=true');
    }
    
    if (params.isNotEmpty) {
      url += '?${params.join('&')}';
    }

    print('📤 Solicitando tutorías: $url');

    final response = await http.get(
      Uri.parse(url),
      headers: ApiConfig.getHeaders(token: token),
    );

    print('📬 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> tutorias = data['tutorias'] ?? [];
      
      print('✅ Tutorías recibidas: ${tutorias.length}');
      
      return tutorias.map((t) => t as Map<String, dynamic>).toList();
    }
    
    print('⚠️ Error: ${response.statusCode}');
    return [];
  } catch (e) {
    print('❌ Error en listarTutorias: $e');
    return [];
  }
}

  /// ✅ LISTAR TUTORÍAS PENDIENTES (SOLO DOCENTE)
  static Future<List<Map<String, dynamic>>> listarTutoriasPendientes() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token');
        return [];
      }

      final url = '${ApiConfig.baseUrl}/tutorias/pendientes';
      print('📋 Obteniendo tutorías pendientes: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> tutorias = data['tutorias'] ?? [];
        
        print('✅ Tutorías pendientes: ${tutorias.length}');
        
        return tutorias.map((t) => t as Map<String, dynamic>).toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error en listarTutoriasPendientes: $e');
      return [];
    }
  }

  /// ✅ ACEPTAR TUTORÍA (SOLO DOCENTE)
  static Future<Map<String, dynamic>?> aceptarTutoria(String tutoriaId) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final url = '${ApiConfig.baseUrl}/tutoria/aceptar/$tutoriaId';
      print('✅ Aceptando tutoría: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Tutoría aceptada exitosamente');
        return data;
      } else {
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al aceptar tutoría'};
      }
    } catch (e) {
      print('❌ Error en aceptarTutoria: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ RECHAZAR TUTORÍA (SOLO DOCENTE)
  static Future<Map<String, dynamic>?> rechazarTutoria(
    String tutoriaId, 
    String motivo
  ) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final url = '${ApiConfig.baseUrl}/tutoria/rechazar/$tutoriaId';
      print('❌ Rechazando tutoría: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'motivoRechazo': motivo,
        }),
      );

      print('📬 Status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Tutoría rechazada exitosamente');
        return data;
      } else {
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al rechazar tutoría'};
      }
    } catch (e) {
      print('❌ Error en rechazarTutoria: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ CANCELAR TUTORÍA (ESTUDIANTE O DOCENTE)
  static Future<Map<String, dynamic>?> cancelarTutoria({
    required String tutoriaId,
    required String motivo,
    required String canceladaPor, // 'Estudiante' o 'Docente'
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final url = '${ApiConfig.baseUrl}/tutoria/cancelar/$tutoriaId';
      print('🗑️ Cancelando tutoría: $url');

      final response = await http.delete(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'motivo': motivo,
          'canceladaPor': canceladaPor,
        }),
      );

      print('📬 Status: ${response.statusCode}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Tutoría cancelada exitosamente');
        return data;
      } else {
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al cancelar tutoría'};
      }
    } catch (e) {
      print('❌ Error en cancelarTutoria: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }
}