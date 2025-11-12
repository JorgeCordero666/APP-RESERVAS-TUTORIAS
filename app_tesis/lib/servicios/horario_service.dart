// lib/servicios/horario_service.dart - VERSIÓN CORREGIDA CON VALIDACIÓN POR DOCENTE
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../servicios/auth_service.dart';
import '../servicios/materia_service.dart';
import '../servicios/docente_service.dart'; // ✅ NUEVO

class HorarioService {
  
  /// ✅ OBTENER HORARIOS DE UNA MATERIA ESPECÍFICA
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
      print('   Bloques: ${bloquesFormateados.length}');

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

  /// ✅ VALIDACIÓN LOCAL RÁPIDA
  static Map<String, dynamic> validarCrucesLocales({
    required List<Map<String, dynamic>> bloques,
  }) {
    print('🔍 Validación local de cruces');
    
    Map<String, List<Map<String, dynamic>>> bloquesPorDia = {};
    
    for (var bloque in bloques) {
      final dia = bloque['dia'].toString().toLowerCase();
      if (!bloquesPorDia.containsKey(dia)) {
        bloquesPorDia[dia] = [];
      }
      bloquesPorDia[dia]!.add(bloque);
    }
    
    for (var entrada in bloquesPorDia.entries) {
      final dia = entrada.key;
      final bloquesDelDia = entrada.value;
      
      bloquesDelDia.sort((a, b) {
        final aInicio = _convertirAMinutos(a['horaInicio']);
        final bInicio = _convertirAMinutos(b['horaInicio']);
        return aInicio.compareTo(bInicio);
      });
      
      for (int i = 0; i < bloquesDelDia.length - 1; i++) {
        final bloqueActual = bloquesDelDia[i];
        final bloqueSiguiente = bloquesDelDia[i + 1];
        
        final finActual = _convertirAMinutos(bloqueActual['horaFin']);
        final inicioSiguiente = _convertirAMinutos(bloqueSiguiente['horaInicio']);
        
        if (finActual > inicioSiguiente) {
          return {
            'valido': false,
            'mensaje': 'Cruce en $dia: ${bloqueActual['horaInicio']}-${bloqueActual['horaFin']} '
                      'se solapa con ${bloqueSiguiente['horaInicio']}-${bloqueSiguiente['horaFin']}'
          };
        }
      }
    }
    
    return {'valido': true};
  }

  /// ✅ ACTUALIZAR HORARIOS CON VALIDACIÓN COMPLETA
  static Future<Map<String, dynamic>> actualizarHorarios({
    required String docenteId,
    required String materia,
    required List<Map<String, dynamic>> bloques,
    bool validarAntes = true,
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

      if (validarAntes && bloques.isNotEmpty) {
        print('🔍 Ejecutando validaciones previas...');
        
        print('   1️⃣ Validando cruces locales...');
        final validacionLocal = validarCrucesLocales(bloques: bloques);
        
        if (!validacionLocal['valido']) {
          print('❌ Validación local falló: ${validacionLocal['mensaje']}');
          return {
            'success': false,
            'mensaje': validacionLocal['mensaje']
          };
        }
        print('   ✅ Sin cruces locales');
        
        print('   2️⃣ Validando cruces internos...');
        final validacionInterna = await validarCrucesInternos(bloques: bloques);
        
        if (!validacionInterna['valido']) {
          print('❌ Validación interna falló: ${validacionInterna['mensaje']}');
          return {
            'success': false,
            'mensaje': validacionInterna['mensaje']
          };
        }
        print('   ✅ Sin cruces internos');
        
        print('   3️⃣ Validando cruces entre materias...');
        final bloquesPorDia = _agruparPorDia(bloques);
        
        for (var entrada in bloquesPorDia.entries) {
          final dia = entrada.key;
          final bloquesDelDia = entrada.value;
          
          print('      Validando día: $dia (${bloquesDelDia.length} bloques)');
          
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
        
        print('   ✅ Sin cruces con otras materias');
      }

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

  /// ✅ OBTENER DISPONIBILIDAD COMPLETA - VALIDACIÓN CORRECTA POR DOCENTE
  static Future<Map<String, List<Map<String, dynamic>>>?> obtenerDisponibilidadCompleta({
    required String docenteId,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        print('❌ No hay token');
        return null;
      }

      // ✅ PASO 1: Obtener información actualizada del docente
      print('🔍 [Paso 1] Obteniendo información del docente...');
      final detalleDocente = await DocenteService.detalleDocente(docenteId);
      
      if (detalleDocente == null || detalleDocente.containsKey('error')) {
        print('❌ No se pudo obtener información del docente');
        return null;
      }

      // ✅ EXTRAER MATERIAS ASIGNADAS AL DOCENTE
      List<String> materiasDocente = [];
      
      if (detalleDocente['asignaturas'] != null) {
        if (detalleDocente['asignaturas'] is List) {
          materiasDocente = List<String>.from(detalleDocente['asignaturas']);
        } else if (detalleDocente['asignaturas'] is String) {
          final stringValue = detalleDocente['asignaturas'] as String;
          if (stringValue.isNotEmpty && stringValue != '[]') {
            try {
              final parsed = jsonDecode(stringValue);
              if (parsed is List) {
                materiasDocente = List<String>.from(parsed);
              }
            } catch (e) {
              print('⚠️ Error parseando asignaturas: $e');
            }
          }
        }
      }

      print('📚 Materias del docente: ${materiasDocente.isEmpty ? "ninguna" : materiasDocente.join(", ")}');

      if (materiasDocente.isEmpty) {
        print('⚠️ El docente no tiene materias asignadas');
        return {};
      }

      // ✅ PASO 2: Validar que las materias estén activas
      print('🔍 [Paso 2] Validando materias activas...');
      final materiasActivas = await MateriaService.listarMaterias(soloActivas: true);
      final nombresMateriasActivas = materiasActivas.map((m) => m.nombre).toSet();
      
      print('📚 Materias activas en el sistema: ${nombresMateriasActivas.length}');

      // ✅ FILTRAR: Solo materias que estén asignadas Y activas
      final materiasValidas = materiasDocente
          .where((m) => nombresMateriasActivas.contains(m))
          .toSet();

      if (materiasValidas.isEmpty) {
        print('⚠️ Ninguna materia del docente está activa');
        return {};
      }

      print('✅ Materias válidas para mostrar: ${materiasValidas.join(", ")}');

      // ✅ PASO 3: Obtener disponibilidad del backend
      final url = '${ApiConfig.baseUrl}/ver-disponibilidad-completa/$docenteId';
      print('🔍 [Paso 3] Solicitando disponibilidad: $url');

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
        
        print('📦 Materias recibidas del backend: ${materias.keys.join(", ")}');
        
        Map<String, List<Map<String, dynamic>>> resultado = {};
        int materiasEliminadasCount = 0;
        
        // ✅ PASO 4: Filtrar solo materias válidas (asignadas Y activas)
        materias.forEach((materia, diasList) {
          // ✅ VALIDACIÓN: Solo incluir si está en materiasValidas
          if (!materiasValidas.contains(materia)) {
            print('⚠️ Materia "$materia" NO es válida, OMITIENDO');
            materiasEliminadasCount++;
            return;
          }
          
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
          
          if (bloquesMat.isNotEmpty) {
            resultado[materia] = bloquesMat;
            print('   ✅ $materia: ${bloquesMat.length} bloques (VÁLIDA)');
          }
        });
        
        if (materiasEliminadasCount > 0) {
          print('🗑️ Se omitieron $materiasEliminadasCount materias no válidas');
        }
        
        print('✅ Total materias a mostrar: ${resultado.length}');
        
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

  /// 🔧 MÉTODO AUXILIAR: Convertir hora a minutos
  static int _convertirAMinutos(String hora) {
    try {
      final partes = hora.split(':');
      final horas = int.parse(partes[0]);
      final minutos = int.parse(partes[1]);
      return horas * 60 + minutos;
    } catch (e) {
      print('⚠️ Error convirtiendo hora: $hora');
      return 0;
    }
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