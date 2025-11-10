// lib/servicios/materia_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';
import '../modelos/materia.dart';

class MateriaService {
  
  /// Listar todas las materias
  static Future<List<Materia>> listarMaterias({
    bool? soloActivas,
    String? semestre,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token');
        return [];
      }

      String url = '${ApiConfig.baseUrl}/materias';
      
      // Agregar parámetros de consulta
      List<String> params = [];
      if (soloActivas == true) params.add('activas=true');
      if (semestre != null) params.add('semestre=$semestre');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print('🔍 Listando materias: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> materiasJson = data['materias'] ?? [];
        
        final materias = materiasJson
            .map((json) => Materia.fromJson(json))
            .toList();
        
        return materias;
      }
      
      print('⚠️ Status code diferente de 200: ${response.statusCode}');
      return [];
    } catch (e) {
      print('❌ Error listando materias: $e');
      return [];
    }
  }

  /// Crear nueva materia
  static Future<Map<String, dynamic>?> crearMateria({
    required String nombre,
    required String codigo,
    required String semestre,
    required int creditos,
    String? descripcion,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/materias'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'nombre': nombre,
          'codigo': codigo.toUpperCase(),
          'semestre': semestre,
          'creditos': creditos,
          'descripcion': descripcion ?? '',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['msg'] ?? 'Error al crear materia'};
      }
    } catch (e) {
      print('❌ Error creando materia: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Actualizar materia
  static Future<Map<String, dynamic>?> actualizarMateria({
    required String id,
    String? nombre,
    String? codigo,
    String? semestre,
    int? creditos,
    String? descripcion,
    bool? activa,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final body = <String, dynamic>{};
      if (nombre != null) body['nombre'] = nombre;
      if (codigo != null) body['codigo'] = codigo.toUpperCase();
      if (semestre != null) body['semestre'] = semestre;
      if (creditos != null) body['creditos'] = creditos;
      if (descripcion != null) body['descripcion'] = descripcion;
      if (activa != null) body['activa'] = activa;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/materias/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['msg'] ?? 'Error al actualizar materia'};
      }
    } catch (e) {
      print('❌ Error actualizando materia: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Eliminar (desactivar) materia
  static Future<Map<String, dynamic>?> eliminarMateria(String id) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/materias/$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else {
        return {'error': data['msg'] ?? 'Error al eliminar materia'};
      }
    } catch (e) {
      print('❌ Error eliminando materia: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// Obtener detalle de materia
  static Future<Materia?> obtenerMateria(String id) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token');
        return null;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/materias/$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Materia.fromJson(data['materia']);
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo materia: $e');
      return null;
    }
  }

  /// Buscar materias
  static Future<List<Materia>> buscarMaterias(String query) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null || query.trim().isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/materias/buscar?q=$query'),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> materiasJson = data['materias'] ?? [];
        
        return materiasJson
            .map((json) => Materia.fromJson(json))
            .toList();
      }
      
      return [];
    } catch (e) {
      print('❌ Error buscando materias: $e');
      return [];
    }
  }

  /// Obtener materias agrupadas por semestre (solo activas)
  static Future<Map<String, List<String>>> obtenerMateriasAgrupadas() async {
    try {
      final materias = await listarMaterias(soloActivas: true);
      
      // Agrupar por semestre
      Map<String, List<String>> materiasPorSemestre = {};
      
      for (var materia in materias) {
        if (!materiasPorSemestre.containsKey(materia.semestre)) {
          materiasPorSemestre[materia.semestre] = [];
        }
        materiasPorSemestre[materia.semestre]!.add(materia.nombre);
      }
      
      // Ordenar las materias alfabéticamente dentro de cada semestre
      materiasPorSemestre.forEach((semestre, materias) {
        materias.sort();
      });
      
      print('✅ Materias agrupadas por semestre: ${materiasPorSemestre.keys.join(", ")}');
      
      return materiasPorSemestre;
    } catch (e) {
      print('❌ Error agrupando materias: $e');
      return {};
    }
  }
}
