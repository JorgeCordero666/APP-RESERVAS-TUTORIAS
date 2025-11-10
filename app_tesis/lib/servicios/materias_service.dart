// lib/servicios/materia_service.dart - VERSIÓN CORREGIDA
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';
import '../modelos/materia.dart';

class MateriaService {
  
  /// ✅ LISTAR MATERIAS (con validación)
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
      
      // Agregar parámetros
      List<String> params = [];
      if (soloActivas == true) params.add('activas=true');
      if (semestre != null) params.add('semestre=$semestre');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      print('🔍 [MateriaService] Listando materias: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ✅ Validar que la respuesta tenga el formato esperado
        if (!data.containsKey('materias')) {
          print('⚠️ Respuesta sin campo "materias"');
          return [];
        }
        
        final List<dynamic> materiasJson = data['materias'] ?? [];
        
        print('📦 Materias recibidas del backend: ${materiasJson.length}');
        
        // ✅ Parsear con manejo de errores
        final List<Materia> materias = [];
        
        for (var json in materiasJson) {
          try {
            final materia = Materia.fromJson(json);
            materias.add(materia);
          } catch (e) {
            print('⚠️ Error parseando materia: $e');
            print('   JSON problemático: $json');
            // Continuar con las demás materias
          }
        }
        
        print('✅ Materias parseadas: ${materias.length}');
        
        return materias;
      }
      
      print('⚠️ Status code diferente de 200: ${response.statusCode}');
      print('   Body: ${response.body}');
      return [];
    } catch (e) {
      print('❌ Error listando materias: $e');
      return [];
    }
  }

  /// ✅ CREAR MATERIA
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

      print('📝 Creando materia: $nombre ($codigo)');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/materias'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode({
          'nombre': nombre.trim(),
          'codigo': codigo.trim().toUpperCase(),
          'semestre': semestre,
          'creditos': creditos,
          'descripcion': descripcion?.trim() ?? '',
        }),
      );

      print('📬 Status: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Materia creada exitosamente');
        return data;
      } else {
        print('❌ Error: ${data['msg'] ?? 'Error desconocido'}');
        return {'error': data['msg'] ?? 'Error al crear materia'};
      }
    } catch (e) {
      print('❌ Error creando materia: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ ACTUALIZAR MATERIA
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
      if (nombre != null) body['nombre'] = nombre.trim();
      if (codigo != null) body['codigo'] = codigo.trim().toUpperCase();
      if (semestre != null) body['semestre'] = semestre;
      if (creditos != null) body['creditos'] = creditos;
      if (descripcion != null) body['descripcion'] = descripcion.trim();
      if (activa != null) body['activa'] = activa;

      print('📝 Actualizando materia: $id');

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/materias/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(body),
      );

      print('📬 Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Materia actualizada');
        return data;
      } else {
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al actualizar materia'};
      }
    } catch (e) {
      print('❌ Error actualizando materia: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ ELIMINAR MATERIA
  static Future<Map<String, dynamic>?> eliminarMateria(String id) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return {'error': 'No hay sesión activa'};
      }

      print('🗑️ Eliminando materia: $id');

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/materias/$id'),
        headers: ApiConfig.getHeaders(token: token),
      );

      print('📬 Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Materia eliminada');
        return data;
      } else {
        print('❌ Error: ${data['msg']}');
        return {'error': data['msg'] ?? 'Error al eliminar materia'};
      }
    } catch (e) {
      print('❌ Error eliminando materia: $e');
      return {'error': 'Error de conexión: $e'};
    }
  }

  /// ✅ OBTENER DETALLE DE MATERIA
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

  /// ✅ BUSCAR MATERIAS
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

  /// ✅ OBTENER MATERIAS AGRUPADAS (SOLO ACTIVAS)
  static Future<Map<String, List<String>>> obtenerMateriasAgrupadas() async {
    try {
      print('\n📚 === CARGANDO MATERIAS PARA DOCENTE ===');
      
      // ✅ Cargar solo materias activas
      final materias = await listarMaterias(soloActivas: true);
      
      print('📦 Total materias activas: ${materias.length}');
      
      if (materias.isEmpty) {
        print('⚠️ No hay materias activas en el sistema');
        return {};
      }
      
      // Agrupar por semestre
      Map<String, List<String>> materiasPorSemestre = {};
      
      for (var materia in materias) {
        if (!materiasPorSemestre.containsKey(materia.semestre)) {
          materiasPorSemestre[materia.semestre] = [];
        }
        materiasPorSemestre[materia.semestre]!.add(materia.nombre);
        
        print('   ➕ ${materia.semestre}: ${materia.nombre}');
      }
      
      // Ordenar alfabéticamente dentro de cada semestre
      materiasPorSemestre.forEach((semestre, materias) {
        materias.sort();
      });
      
      print('✅ Materias agrupadas: ${materiasPorSemestre.keys.join(", ")}');
      print('=== FIN CARGA ===\n');
      
      return materiasPorSemestre;
    } catch (e) {
      print('❌ Error agrupando materias: $e');
      return {};
    }
  }

  /// ✅ VALIDAR SI UNA MATERIA EXISTE
  static Future<bool> materiaExiste(String nombreMateria) async {
    try {
      final materias = await listarMaterias(soloActivas: true);
      return materias.any((m) => m.nombre == nombreMateria);
    } catch (e) {
      print('❌ Error validando materia: $e');
      return false;
    }
  }

  /// ✅ VALIDAR LISTA DE MATERIAS
  static Future<Map<String, bool>> validarMaterias(List<String> nombresMaterias) async {
    try {
      final materias = await listarMaterias(soloActivas: true);
      final nombresValidos = materias.map((m) => m.nombre).toSet();
      
      Map<String, bool> resultado = {};
      for (var nombre in nombresMaterias) {
        resultado[nombre] = nombresValidos.contains(nombre);
      }
      
      return resultado;
    } catch (e) {
      print('❌ Error validando materias: $e');
      return {};
    }
  }
}