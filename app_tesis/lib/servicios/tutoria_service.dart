// lib/servicios/tutoria_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';

class TutoriaService {
  
  /// ✅ NUEVO: Obtener turnos disponibles de 20 min para un bloque
  static Future<Map<String, dynamic>?> obtenerTurnosDisponibles({
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

      // Construir URL con parámetros
      final url = Uri.parse('${ApiConfig.baseUrl}/turnos-disponibles').replace(
        queryParameters: {
          'docenteId': docenteId,
          'fecha': fecha,
          'horaInicio': horaInicio,
          'horaFin': horaFin,
        }
      );

      print('📞 Obteniendo turnos disponibles: $url');

      final response = await http.get(
        url,
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Turnos disponibles: ${data['turnos']['disponibles']}/${data['turnos']['total']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error: ${error['msg']}');
        return {'error': error['msg'] ?? 'Error al obtener turnos'};
      }
    } catch (e) {
      print('❌ Error en obtenerTurnosDisponibles: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ NUEVO: Agendar tutoría con turno de 20 minutos
  static Future<Map<String, dynamic>?> agendarTurno({
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

      // Validar duración localmente
      final [hIni, mIni] = horaInicio.split(':').map(int.parse).toList();
      final [hFin, mFin] = horaFin.split(':').map(int.parse).toList();
      final duracion = (hFin * 60 + mFin) - (hIni * 60 + mIni);

      if (duracion > 20) {
        return {'error': 'La duración del turno no puede exceder 20 minutos'};
      }

      if (duracion <= 0) {
        return {'error': 'Horario inválido'};
      }

      final url = '${ApiConfig.baseUrl}/tutoria/registrar-turno';
      print('📝 Agendando turno: $horaInicio-$horaFin ($duracion min)');

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

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Turno agendado exitosamente');
        return data;
      } else {
        final data = jsonDecode(response.body);
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al agendar turno'};
      }
    } catch (e) {
      print('❌ Error en agendarTurno: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ AGENDAR TUTORÍA (ESTUDIANTE) - Función original mantenida
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

  /// ✅ LISTAR TUTORÍAS DEL USUARIO AUTENTICADO
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
  // Agregar al final del archivo tutoria_service.dart existente

  /// ✅ REAGENDAR TUTORÍA
  static Future<Map<String, dynamic>?> reagendarTutoria({
    required String tutoriaId,
    required String nuevaFecha,
    required String nuevaHoraInicio,
    required String nuevaHoraFin,
    String? motivo,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final url = '${ApiConfig.baseUrl}/tutoria/reagendar/$tutoriaId';
      print('🔄 Reagendando tutoría: $url');
      print('   Nueva fecha: $nuevaFecha');
      print('   Nuevo horario: $nuevaHoraInicio - $nuevaHoraFin');

      final response = await http.put(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'nuevaFecha': nuevaFecha,
          'nuevaHoraInicio': nuevaHoraInicio,
          'nuevaHoraFin': nuevaHoraFin,
          'motivo': motivo ?? 'Reagendada por el usuario',
        }),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Tutoría reagendada exitosamente');
        return data;
      } else {
        final data = jsonDecode(response.body);
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al reagendar tutoría'};
      }
    } catch (e) {
      print('❌ Error en reagendarTutoria: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ OBTENER HISTORIAL DE TUTORÍAS CON FILTROS
  static Future<Map<String, dynamic>?> obtenerHistorialTutorias({
    String? fechaInicio,
    String? fechaFin,
    String? estado,
    bool incluirCanceladas = true,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      // Construir URL con parámetros
      final params = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'incluirCanceladas': incluirCanceladas.toString(),
      };

      if (fechaInicio != null) params['fechaInicio'] = fechaInicio;
      if (fechaFin != null) params['fechaFin'] = fechaFin;
      if (estado != null) params['estado'] = estado;

      final uri = Uri.parse('${ApiConfig.baseUrl}/historial-tutorias')
          .replace(queryParameters: params);

      print('📊 Obteniendo historial: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Historial obtenido: ${data['total']} tutorías');
        return data;
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error: ${error['msg']}');
        return {'error': error['msg'] ?? 'Error al obtener historial'};
      }
    } catch (e) {
      print('❌ Error en obtenerHistorialTutorias: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ GENERAR REPORTE POR MATERIAS (SOLO DOCENTE)
  static Future<Map<String, dynamic>?> generarReportePorMaterias({
    String? fechaInicio,
    String? fechaFin,
    String formato = 'json', // 'json' o 'csv'
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final params = <String, String>{
        'formato': formato,
      };

      if (fechaInicio != null) params['fechaInicio'] = fechaInicio;
      if (fechaFin != null) params['fechaFin'] = fechaFin;

      final uri = Uri.parse('${ApiConfig.baseUrl}/reporte-por-materias')
          .replace(queryParameters: params);

      print('📊 Generando reporte: $uri');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (formato == 'csv') {
          // Para CSV, retornar el contenido directamente
          return {
            'success': true,
            'csv': response.body,
            'filename': 'reporte_tutorias_${DateTime.now().millisecondsSinceEpoch}.csv'
          };
        } else {
          final data = jsonDecode(response.body);
          print('✅ Reporte generado: ${data['estadisticasGlobales']['materiasActivas']} materias');
          return data;
        }
      } else {
        final error = jsonDecode(response.body);
        print('❌ Error: ${error['msg']}');
        return {'error': error['msg'] ?? 'Error al generar reporte'};
      }
    } catch (e) {
      print('❌ Error en generarReportePorMaterias: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }
}