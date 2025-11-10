// lib/servicios/horario_service_temp.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';
import '../modelos/horario.dart';

class HorarioService {
  static final HorarioService _instancia = HorarioService._internal();

  factory HorarioService() {
    return _instancia;
  }

  HorarioService._internal();

  /// Obtener horarios de UNA materia específica
  Future<List<Map<String, dynamic>>?> obtenerHorariosPorMateria({
    required String docenteId,
    required String materia,
  }) async {
    try {
      // Forzar actualización del usuario para tener las materias más recientes
      final usuarioActualizado = await AuthService.getUsuarioActual();
      if (usuarioActualizado == null) {
        print('❌ No se pudo obtener el usuario actualizado');
        return null;
      }

      // Verificar que la materia esté en la lista actualizada
      final materias = usuarioActualizado.asignaturas ?? [];
      if (!materias.contains(materia)) {
        print('⚠️ La materia $materia ya no está asignada al docente');
        return null;
      }

      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No hay token de autenticación');
        return null;
      }

      final url =
          '${ApiConfig.baseUrl}/ver-disponibilidad-materia/$docenteId/${Uri.encodeComponent(materia)}';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> disponibilidad = data['disponibilidad'] ?? [];

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

        return todosLosBloques;
      }
      return [];
    } catch (e) {
      print('❌ Error en obtenerHorariosPorMateria: $e');
      return null;
    }
  }

  /// Obtener todos los horarios del docente
  Future<List<Horario>?> obtenerHorarios() async {
    try {
      final usuario = await AuthService.getUsuarioActual();
      if (usuario == null) return null;

      final token = await AuthService.getToken();
      if (token == null) return null;

      final url = '${ApiConfig.baseUrl}/disponibilidad/${usuario.id}';

      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> disponibilidad = data['disponibilidad'] ?? [];
        return disponibilidad.map((json) => Horario.fromJson(json)).toList();
      }
      return null;
    } catch (e) {
      print('❌ Error al obtener horarios: $e');
      return null;
    }
  }

  /// Eliminar horario específico
  Future<bool> eliminarHorario(String id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final url = '${ApiConfig.baseUrl}/disponibilidad/$id';

      final response = await http.delete(
        Uri.parse(url),
        headers: ApiConfig.getHeaders(token: token),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error al eliminar horario: $e');
      return false;
    }
  }

  /// Limpiar horarios de materias no asignadas
  Future<void> limpiarHorariosHuerfanos() async {
    try {
      final usuario = await AuthService.getUsuarioActual();
      if (usuario == null) return;

      final horarios = await obtenerHorarios();
      if (horarios == null || horarios.isEmpty) return;

      final materiasAsignadas = usuario.asignaturas ?? [];

      for (var horario in horarios) {
        if (horario.materia != null &&
            !materiasAsignadas.contains(horario.materia!)) {
          await eliminarHorario(horario.id);
        }
      }
    } catch (e) {
      print('❌ Error al limpiar horarios huérfanos: $e');
    }
  }

  String _capitalizarDia(String dia) {
    if (dia.isEmpty) return dia;
    return dia[0].toUpperCase() + dia.substring(1).toLowerCase();
  }
}
