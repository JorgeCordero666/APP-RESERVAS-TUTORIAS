// ============================================
// PRUEBA UNITARIA - GESTIÓN DE SOLICITUDES
// Figura 3.42: Conclusión de la prueba de software unitaria – Gestión de solicitudes
// HU-008: Aceptar y rechazar tutorías
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-008: Gestión de Solicitudes de Tutorías', () {
    
    // ========================================
    // VALIDACIONES DE ESTADO DE TUTORÍA
    // ========================================
    
    test('✓ Validación de cambio de estado pendiente a confirmada - válido', () {
      final resultado = validarCambioEstado('pendiente', 'confirmada');
      expect(resultado, null);
    });

    test('✓ Validación de cambio de estado pendiente a rechazada - válido', () {
      final resultado = validarCambioEstado('pendiente', 'rechazada');
      expect(resultado, null);
    });

    test('✓ Validación de cambio de estado confirmada a confirmada - inválido', () {
      final resultado = validarCambioEstado('confirmada', 'confirmada');
      expect(resultado, 'La tutoría ya está confirmada');
    });

    test('✓ Validación de cambio de estado rechazada a confirmada - inválido', () {
      final resultado = validarCambioEstado('rechazada', 'confirmada');
      expect(resultado, 'No se puede confirmar una tutoría rechazada');
    });

    test('✓ Validación de cambio de estado cancelada a confirmada - inválido', () {
      final resultado = validarCambioEstado('cancelada', 'confirmada');
      expect(resultado, 'No se puede modificar una tutoría cancelada');
    });

    // ========================================
    // VALIDACIÓN DE MOTIVO DE RECHAZO
    // ========================================

    test('✓ Validación de motivo de rechazo - con texto válido', () {
      final resultado = validarMotivoRechazo('Horario no disponible');
      expect(resultado, null);
    });

    test('✓ Validación de motivo de rechazo - texto vacío', () {
      final resultado = validarMotivoRechazo('');
      expect(resultado, null); // Motivo opcional
    });

    test('✓ Validación de motivo de rechazo - solo espacios', () {
      final resultado = validarMotivoRechazo('   ');
      expect(resultado, null); // Se limpia y es opcional
    });

    test('✓ Normalizar motivo de rechazo - con espacios', () {
      final motivo = normalizarMotivoRechazo('  Horario ocupado  ');
      expect(motivo, 'Horario ocupado');
    });

    test('✓ Normalizar motivo de rechazo - vacío a mensaje por defecto', () {
      final motivo = normalizarMotivoRechazo('');
      expect(motivo, 'Sin motivo especificado');
    });

    // ========================================
    // CONTEO DE SOLICITUDES POR ESTADO
    // ========================================

    test('✓ Contar solicitudes por estado - múltiples estados', () {
      final tutorias = [
        {'estado': 'pendiente'},
        {'estado': 'pendiente'},
        {'estado': 'confirmada'},
        {'estado': 'pendiente'},
        {'estado': 'confirmada'},
        {'estado': 'rechazada'},
      ];
      
      final conteo = contarPorEstado(tutorias);
      
      expect(conteo['pendiente'], 3);
      expect(conteo['confirmada'], 2);
      expect(conteo['rechazada'], 1);
      expect(conteo['cancelada'], 0);
    });

    test('✓ Contar solicitudes por estado - lista vacía', () {
      final tutorias = <Map<String, dynamic>>[];
      final conteo = contarPorEstado(tutorias);
      
      expect(conteo['pendiente'], 0);
      expect(conteo['confirmada'], 0);
      expect(conteo['rechazada'], 0);
      expect(conteo['cancelada'], 0);
    });

    test('✓ Contar solicitudes por estado - solo pendientes', () {
      final tutorias = [
        {'estado': 'pendiente'},
        {'estado': 'pendiente'},
        {'estado': 'pendiente'},
      ];
      
      final conteo = contarPorEstado(tutorias);
      
      expect(conteo['pendiente'], 3);
      expect(conteo['confirmada'], 0);
    });

    // ========================================
    // FILTRADO DE TUTORÍAS
    // ========================================

    test('✓ Filtrar tutorías pendientes - resultado correcto', () {
      final tutorias = [
        {'_id': '1', 'estado': 'pendiente'},
        {'_id': '2', 'estado': 'confirmada'},
        {'_id': '3', 'estado': 'pendiente'},
      ];
      
      final pendientes = filtrarPorEstado(tutorias, 'pendiente');
      
      expect(pendientes.length, 2);
      expect(pendientes[0]['_id'], '1');
      expect(pendientes[1]['_id'], '3');
    });

    test('✓ Filtrar tutorías confirmadas - resultado correcto', () {
      final tutorias = [
        {'_id': '1', 'estado': 'pendiente'},
        {'_id': '2', 'estado': 'confirmada'},
        {'_id': '3', 'estado': 'confirmada'},
      ];
      
      final confirmadas = filtrarPorEstado(tutorias, 'confirmada');
      
      expect(confirmadas.length, 2);
      expect(confirmadas[0]['_id'], '2');
      expect(confirmadas[1]['_id'], '3');
    });

    test('✓ Filtrar tutorías - estado inexistente', () {
      final tutorias = [
        {'_id': '1', 'estado': 'pendiente'},
        {'_id': '2', 'estado': 'confirmada'},
      ];
      
      final resultado = filtrarPorEstado(tutorias, 'finalizada');
      
      expect(resultado.length, 0);
    });

    // ========================================
    // VALIDACIÓN DE DATOS DE ESTUDIANTE
    // ========================================

    test('✓ Validar datos de estudiante - completos', () {
      final estudiante = {
        'nombreEstudiante': 'Juan Pérez',
        'emailEstudiante': 'juan.perez@epn.edu.ec',
        'fotoPerfil': 'https://example.com/foto.jpg',
      };
      
      final resultado = validarDatosEstudiante(estudiante);
      expect(resultado, true);
    });

    test('✓ Validar datos de estudiante - nombre faltante', () {
      final estudiante = {
        'emailEstudiante': 'juan.perez@epn.edu.ec',
      };
      
      final resultado = validarDatosEstudiante(estudiante);
      expect(resultado, false);
    });

    test('✓ Validar datos de estudiante - email faltante', () {
      final estudiante = {
        'nombreEstudiante': 'Juan Pérez',
      };
      
      final resultado = validarDatosEstudiante(estudiante);
      expect(resultado, false);
    });

    // ========================================
    // FORMATO DE FECHA Y HORA
    // ========================================

    test('✓ Formatear fecha ISO a legible - válida', () {
      final fecha = formatearFecha('2025-12-20');
      expect(fecha, '20/12/2025');
    });

    test('✓ Formatear fecha ISO a legible - fecha nula', () {
      final fecha = formatearFecha(null);
      expect(fecha, 'Sin fecha');
    });

    test('✓ Formatear rango de horario - válido', () {
      final horario = formatearRangoHorario('08:00', '08:20');
      expect(horario, '08:00 - 08:20');
    });

    test('✓ Formatear rango de horario - horas nulas', () {
      final horario = formatearRangoHorario(null, null);
      expect(horario, '--:-- - --:--');
    });

    // ========================================
    // PREPARACIÓN DE RESPUESTA DE ACEPTACIÓN
    // ========================================

    test('✓ Preparar datos de aceptación - formato correcto', () {
      final datos = prepararDatosAceptacion(
        tutoriaId: 'abc123',
        fechaConfirmacion: DateTime(2025, 12, 20, 10, 30),
      );
      
      expect(datos['tutoriaId'], 'abc123');
      expect(datos['estado'], 'confirmada');
      expect(datos['fechaConfirmacion'], isNotNull);
    });

    // ========================================
    // PREPARACIÓN DE RESPUESTA DE RECHAZO
    // ========================================

    test('✓ Preparar datos de rechazo - con motivo', () {
      final datos = prepararDatosRechazo(
        tutoriaId: 'abc123',
        motivo: 'Horario no disponible',
        fechaRechazo: DateTime(2025, 12, 20, 10, 30),
      );
      
      expect(datos['tutoriaId'], 'abc123');
      expect(datos['estado'], 'rechazada');
      expect(datos['motivoRechazo'], 'Horario no disponible');
      expect(datos['fechaRechazo'], isNotNull);
    });

    test('✓ Preparar datos de rechazo - sin motivo', () {
      final datos = prepararDatosRechazo(
        tutoriaId: 'abc123',
        motivo: '',
        fechaRechazo: DateTime(2025, 12, 20, 10, 30),
      );
      
      expect(datos['motivoRechazo'], 'Sin motivo especificado');
    });

    // ========================================
    // ORDENAMIENTO DE SOLICITUDES
    // ========================================

    test('✓ Ordenar solicitudes por fecha - más recientes primero', () {
      final tutorias = [
        {'fecha': '2025-12-22', 'horaInicio': '10:00'},
        {'fecha': '2025-12-20', 'horaInicio': '08:00'},
        {'fecha': '2025-12-21', 'horaInicio': '14:00'},
      ];
      
      final ordenadas = ordenarPorFecha(tutorias);
      
      expect(ordenadas[0]['fecha'], '2025-12-20');
      expect(ordenadas[1]['fecha'], '2025-12-21');
      expect(ordenadas[2]['fecha'], '2025-12-22');
    });

    test('✓ Ordenar solicitudes por fecha - mismo día, por hora', () {
      final tutorias = [
        {'fecha': '2025-12-20', 'horaInicio': '14:00'},
        {'fecha': '2025-12-20', 'horaInicio': '08:00'},
        {'fecha': '2025-12-20', 'horaInicio': '10:00'},
      ];
      
      final ordenadas = ordenarPorFecha(tutorias);
      
      expect(ordenadas[0]['horaInicio'], '08:00');
      expect(ordenadas[1]['horaInicio'], '10:00');
      expect(ordenadas[2]['horaInicio'], '14:00');
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - GESTIÓN DE SOLICITUDES
// ============================================

String? validarCambioEstado(String estadoActual, String estadoNuevo) {
  if (estadoActual == 'cancelada') {
    return 'No se puede modificar una tutoría cancelada';
  }
  
  if (estadoActual == 'confirmada' && estadoNuevo == 'confirmada') {
    return 'La tutoría ya está confirmada';
  }
  
  if (estadoActual == 'rechazada' && estadoNuevo == 'confirmada') {
    return 'No se puede confirmar una tutoría rechazada';
  }
  
  if (estadoActual != 'pendiente' && 
      (estadoNuevo == 'confirmada' || estadoNuevo == 'rechazada')) {
    return 'Solo se pueden aceptar o rechazar tutorías pendientes';
  }
  
  return null;
}

String? validarMotivoRechazo(String? motivo) {
  // El motivo es opcional
  return null;
}

String normalizarMotivoRechazo(String? motivo) {
  if (motivo == null || motivo.trim().isEmpty) {
    return 'Sin motivo especificado';
  }
  return motivo.trim();
}

Map<String, int> contarPorEstado(List<Map<String, dynamic>> tutorias) {
  final conteo = {
    'pendiente': 0,
    'confirmada': 0,
    'rechazada': 0,
    'cancelada': 0,
  };
  
  for (var tutoria in tutorias) {
    final estado = tutoria['estado'];
    if (conteo.containsKey(estado)) {
      conteo[estado] = conteo[estado]! + 1;
    }
  }
  
  return conteo;
}

List<Map<String, dynamic>> filtrarPorEstado(
  List<Map<String, dynamic>> tutorias,
  String estado,
) {
  return tutorias.where((t) => t['estado'] == estado).toList();
}

bool validarDatosEstudiante(Map<String, dynamic>? estudiante) {
  if (estudiante == null) return false;
  
  return estudiante.containsKey('nombreEstudiante') &&
         estudiante.containsKey('emailEstudiante');
}

String formatearFecha(String? fecha) {
  if (fecha == null) return 'Sin fecha';
  
  try {
    final date = DateTime.parse(fecha);
    return '${date.day}/${date.month}/${date.year}';
  } catch (_) {
    return fecha;
  }
}

String formatearRangoHorario(String? inicio, String? fin) {
  final inicioStr = inicio ?? '--:--';
  final finStr = fin ?? '--:--';
  return '$inicioStr - $finStr';
}

Map<String, dynamic> prepararDatosAceptacion({
  required String tutoriaId,
  required DateTime fechaConfirmacion,
}) {
  return {
    'tutoriaId': tutoriaId,
    'estado': 'confirmada',
    'fechaConfirmacion': fechaConfirmacion.toIso8601String(),
  };
}

Map<String, dynamic> prepararDatosRechazo({
  required String tutoriaId,
  required String motivo,
  required DateTime fechaRechazo,
}) {
  return {
    'tutoriaId': tutoriaId,
    'estado': 'rechazada',
    'motivoRechazo': normalizarMotivoRechazo(motivo),
    'fechaRechazo': fechaRechazo.toIso8601String(),
  };
}

List<Map<String, dynamic>> ordenarPorFecha(
  List<Map<String, dynamic>> tutorias,
) {
  final lista = List<Map<String, dynamic>>.from(tutorias);
  
  lista.sort((a, b) {
    final fechaA = DateTime.parse(a['fecha']);
    final fechaB = DateTime.parse(b['fecha']);
    
    final comparacionFecha = fechaA.compareTo(fechaB);
    
    if (comparacionFecha != 0) {
      return comparacionFecha;
    }
    
    // Si las fechas son iguales, ordenar por hora
    final horaA = a['horaInicio'] ?? '00:00';
    final horaB = b['horaInicio'] ?? '00:00';
    return horaA.compareTo(horaB);
  });
  
  return lista;
}