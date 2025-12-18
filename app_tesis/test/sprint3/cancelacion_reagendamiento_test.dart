// ============================================
// PRUEBA UNITARIA - CANCELACIÓN Y REAGENDAMIENTO
// Figura 3.45: Conclusión de la prueba de software unitaria – Cancelación y reagendamiento
// HU-009: Cancelar y reagendar tutorías con validación de anticipación
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-009: Cancelación y Reagendamiento de Tutorías', () {
    
    // ========================================
    // VALIDACIÓN DE ANTICIPACIÓN MÍNIMA (2 HORAS)
    // ========================================
    
    test('✓ Validación de anticipación - 3 horas antes (válido)', () {
      final fechaTutoria = DateTime.now().add(const Duration(hours: 3));
      final resultado = validarAnticipacionMinima(fechaTutoria);
      expect(resultado, null);
    });

    test('✓ Validación de anticipación - 2 horas exactas (válido)', () {
      final fechaTutoria = DateTime.now().add(const Duration(hours: 2));
      final resultado = validarAnticipacionMinima(fechaTutoria);
      expect(resultado, null);
    });

    test('✓ Validación de anticipación - 1 hora antes (inválido)', () {
      final fechaTutoria = DateTime.now().add(const Duration(hours: 1));
      final resultado = validarAnticipacionMinima(fechaTutoria);
      expect(resultado, 'Debes cancelar o reagendar con al menos 2 horas de anticipación');
    });

    test('✓ Validación de anticipación - 30 minutos antes (inválido)', () {
      final fechaTutoria = DateTime.now().add(const Duration(minutes: 30));
      final resultado = validarAnticipacionMinima(fechaTutoria);
      expect(resultado, 'Debes cancelar o reagendar con al menos 2 horas de anticipación');
    });

    test('✓ Validación de anticipación - 1 día antes (válido)', () {
      final fechaTutoria = DateTime.now().add(const Duration(days: 1));
      final resultado = validarAnticipacionMinima(fechaTutoria);
      expect(resultado, null);
    });

    // ========================================
    // CÁLCULO DE DIFERENCIA TEMPORAL
    // ========================================

    test('✓ Calcular horas de anticipación - 3 horas', () {
      final fechaTutoria = DateTime.now().add(const Duration(hours: 3));
      final horas = calcularHorasAnticipacion(fechaTutoria);
      expect(horas, greaterThanOrEqualTo(2));
      expect(horas, lessThanOrEqualTo(4));
    });

    test('✓ Calcular horas de anticipación - 24 horas', () {
      final fechaTutoria = DateTime.now().add(const Duration(hours: 24));
      final horas = calcularHorasAnticipacion(fechaTutoria);
      expect(horas, greaterThanOrEqualTo(23));
      expect(horas, lessThanOrEqualTo(25));
    });

    test('✓ Calcular horas de anticipación - 1 hora (insuficiente)', () {
      final fechaTutoria = DateTime.now().add(const Duration(hours: 1));
      final horas = calcularHorasAnticipacion(fechaTutoria);
      expect(horas, lessThan(2));
    });

    // ========================================
    // VALIDACIÓN DE MOTIVO DE CANCELACIÓN
    // ========================================

    test('✓ Validación de motivo de cancelación - con texto', () {
      final resultado = validarMotivoCancelacion('Tengo un compromiso');
      expect(resultado, null);
    });

    test('✓ Validación de motivo de cancelación - vacío (opcional)', () {
      final resultado = validarMotivoCancelacion('');
      expect(resultado, null);
    });

    test('✓ Normalizar motivo de cancelación - con espacios', () {
      final motivo = normalizarMotivoCancelacion('  Emergencia familiar  ');
      expect(motivo, 'Emergencia familiar');
    });

    test('✓ Normalizar motivo de cancelación - vacío a mensaje por defecto', () {
      final motivo = normalizarMotivoCancelacion('');
      expect(motivo, 'Sin motivo especificado');
    });

    // ========================================
    // VALIDACIÓN DE DATOS DE REAGENDAMIENTO
    // ========================================

    test('✓ Validación de nueva fecha - fecha futura válida', () {
      final nuevaFecha = DateTime.now().add(const Duration(days: 2));
      final resultado = validarNuevaFecha(nuevaFecha);
      expect(resultado, null);
    });

    test('✓ Validación de nueva fecha - fecha pasada', () {
      final nuevaFecha = DateTime.now().subtract(const Duration(days: 1));
      final resultado = validarNuevaFecha(nuevaFecha);
      expect(resultado, 'La nueva fecha debe ser futura');
    });

    test('✓ Validación de nueva fecha - hoy mismo', () {
      final nuevaFecha = DateTime.now();
      final resultado = validarNuevaFecha(nuevaFecha);
      expect(resultado, 'La nueva fecha debe ser futura');
    });

    test('✓ Validación de cambio de horario - horarios diferentes', () {
      final resultado = validarCambioHorario(
        horaActual: '08:00',
        horaActualFin: '08:20',
        horaNueva: '10:00',
        horaNuevaFin: '10:20',
      );
      expect(resultado, null);
    });

    test('✓ Validación de cambio de horario - mismo horario', () {
      final resultado = validarCambioHorario(
        horaActual: '08:00',
        horaActualFin: '08:20',
        horaNueva: '08:00',
        horaNuevaFin: '08:20',
      );
      expect(resultado, 'Debes seleccionar un horario diferente al actual');
    });

    // ========================================
    // CONSTRUCCIÓN DE FECHA-HORA COMPLETA
    // ========================================

    test('✓ Construir fecha-hora completa - válida', () {
      final fecha = DateTime(2025, 12, 20);
      final fechaHora = construirFechaHora(fecha, '14:30');
      
      expect(fechaHora.year, 2025);
      expect(fechaHora.month, 12);
      expect(fechaHora.day, 20);
      expect(fechaHora.hour, 14);
      expect(fechaHora.minute, 30);
    });

    test('✓ Construir fecha-hora completa - medianoche', () {
      final fecha = DateTime(2025, 12, 20);
      final fechaHora = construirFechaHora(fecha, '00:00');
      
      expect(fechaHora.hour, 0);
      expect(fechaHora.minute, 0);
    });

    test('✓ Construir fecha-hora completa - última hora del día', () {
      final fecha = DateTime(2025, 12, 20);
      final fechaHora = construirFechaHora(fecha, '23:59');
      
      expect(fechaHora.hour, 23);
      expect(fechaHora.minute, 59);
    });

    // ========================================
    // VALIDACIÓN COMPLETA DE REAGENDAMIENTO
    // ========================================

    test('✓ Validar reagendamiento completo - todos los datos válidos', () {
      final nuevaFecha = DateTime.now().add(const Duration(days: 3));
      final fechaTutoria = DateTime.now().add(const Duration(days: 1));
      
      final resultado = validarReagendamientoCompleto(
        fechaTutoria: fechaTutoria,
        nuevaFecha: nuevaFecha,
        nuevaHoraInicio: '10:00',
        nuevaHoraFin: '10:20',
      );
      
      expect(resultado, null);
    });

    test('✓ Validar reagendamiento completo - anticipación insuficiente', () {
      final nuevaFecha = DateTime.now().add(const Duration(days: 3));
      final fechaTutoria = DateTime.now().add(const Duration(minutes: 30));
      
      final resultado = validarReagendamientoCompleto(
        fechaTutoria: fechaTutoria,
        nuevaFecha: nuevaFecha,
        nuevaHoraInicio: '10:00',
        nuevaHoraFin: '10:20',
      );
      
      expect(resultado, contains('anticipación'));
    });

    test('✓ Validar reagendamiento completo - nueva fecha pasada', () {
      final nuevaFecha = DateTime.now().subtract(const Duration(days: 1));
      final fechaTutoria = DateTime.now().add(const Duration(days: 5));
      
      final resultado = validarReagendamientoCompleto(
        fechaTutoria: fechaTutoria,
        nuevaFecha: nuevaFecha,
        nuevaHoraInicio: '10:00',
        nuevaHoraFin: '10:20',
      );
      
      expect(resultado, contains('futura'));
    });

    // ========================================
    // PREPARACIÓN DE DATOS PARA CANCELACIÓN
    // ========================================

    test('✓ Preparar datos de cancelación - formato correcto', () {
      final datos = prepararDatosCancelacion(
        tutoriaId: 'abc123',
        motivo: 'Emergencia médica',
        canceladaPor: 'Estudiante',
      );
      
      expect(datos['tutoriaId'], 'abc123');
      expect(datos['motivo'], 'Emergencia médica');
      expect(datos['canceladaPor'], 'Estudiante');
      expect(datos['fechaCancelacion'], isNotNull);
    });

    test('✓ Preparar datos de cancelación - sin motivo', () {
      final datos = prepararDatosCancelacion(
        tutoriaId: 'abc123',
        motivo: '',
        canceladaPor: 'Docente',
      );
      
      expect(datos['motivo'], 'Sin motivo especificado');
    });

    // ========================================
    // PREPARACIÓN DE DATOS PARA REAGENDAMIENTO
    // ========================================

    test('✓ Preparar datos de reagendamiento - formato correcto', () {
      final datos = prepararDatosReagendamiento(
        tutoriaId: 'abc123',
        nuevaFecha: '2025-12-25',
        nuevaHoraInicio: '14:00',
        nuevaHoraFin: '14:20',
        motivo: 'Conflicto de horarios',
      );
      
      expect(datos['tutoriaId'], 'abc123');
      expect(datos['nuevaFecha'], '2025-12-25');
      expect(datos['nuevaHoraInicio'], '14:00');
      expect(datos['nuevaHoraFin'], '14:20');
      expect(datos['motivo'], 'Conflicto de horarios');
    });

    test('✓ Preparar datos de reagendamiento - sin motivo', () {
      final datos = prepararDatosReagendamiento(
        tutoriaId: 'abc123',
        nuevaFecha: '2025-12-25',
        nuevaHoraInicio: '14:00',
        nuevaHoraFin: '14:20',
        motivo: '',
      );
      
      expect(datos['motivo'], 'Reagendada por el usuario');
    });

    // ========================================
    // LIBERACIÓN Y RESERVA DE HORARIOS
    // ========================================

    test('✓ Verificar disponibilidad de nuevo horario - disponible', () {
      final turnosOcupados = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
        {'horaInicio': '10:00', 'horaFin': '10:20'},
      ];
      
      final disponible = verificarDisponibilidadHorario(
        '09:00',
        '09:20',
        turnosOcupados,
      );
      
      expect(disponible, true);
    });

    test('✓ Verificar disponibilidad de nuevo horario - ocupado', () {
      final turnosOcupados = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
        {'horaInicio': '09:00', 'horaFin': '09:20'},
      ];
      
      final disponible = verificarDisponibilidadHorario(
        '09:00',
        '09:20',
        turnosOcupados,
      );
      
      expect(disponible, false);
    });

    // ========================================
    // VALIDACIÓN DE ESTADO PARA MODIFICACIÓN
    // ========================================

    test('✓ Validar estado para cancelación - estado confirmada válido', () {
      final resultado = validarEstadoParaCancelacion('confirmada');
      expect(resultado, null);
    });

    test('✓ Validar estado para cancelación - estado pendiente válido', () {
      final resultado = validarEstadoParaCancelacion('pendiente');
      expect(resultado, null);
    });

    test('✓ Validar estado para cancelación - estado cancelada inválido', () {
      final resultado = validarEstadoParaCancelacion('cancelada');
      expect(resultado, 'La tutoría ya está cancelada');
    });

    test('✓ Validar estado para cancelación - estado finalizada inválido', () {
      final resultado = validarEstadoParaCancelacion('finalizada');
      expect(resultado, 'No se puede cancelar una tutoría finalizada');
    });

    test('✓ Validar estado para cancelación - estado rechazada inválido', () {
      final resultado = validarEstadoParaCancelacion('rechazada');
      expect(resultado, 'No se puede cancelar una tutoría rechazada');
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - CANCELACIÓN Y REAGENDAMIENTO
// ============================================

String? validarAnticipacionMinima(DateTime fechaTutoria) {
  final ahora = DateTime.now();
  final diferencia = fechaTutoria.difference(ahora);
  
  if (diferencia.inHours < 2) {
    return 'Debes cancelar o reagendar con al menos 2 horas de anticipación';
  }
  
  return null;
}

int calcularHorasAnticipacion(DateTime fechaTutoria) {
  final ahora = DateTime.now();
  final diferencia = fechaTutoria.difference(ahora);
  return diferencia.inHours;
}

String? validarMotivoCancelacion(String? motivo) {
  // El motivo es opcional
  return null;
}

String normalizarMotivoCancelacion(String? motivo) {
  if (motivo == null || motivo.trim().isEmpty) {
    return 'Sin motivo especificado';
  }
  return motivo.trim();
}

String? validarNuevaFecha(DateTime nuevaFecha) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final fechaSinHora = DateTime(nuevaFecha.year, nuevaFecha.month, nuevaFecha.day);
  
  if (fechaSinHora.isBefore(hoy) || fechaSinHora.isAtSameMomentAs(hoy)) {
    return 'La nueva fecha debe ser futura';
  }
  
  return null;
}

String? validarCambioHorario({
  required String horaActual,
  required String horaActualFin,
  required String horaNueva,
  required String horaNuevaFin,
}) {
  if (horaActual == horaNueva && horaActualFin == horaNuevaFin) {
    return 'Debes seleccionar un horario diferente al actual';
  }
  
  return null;
}

DateTime construirFechaHora(DateTime fecha, String hora) {
  final partes = hora.split(':');
  final horas = int.parse(partes[0]);
  final minutos = int.parse(partes[1]);
  
  return DateTime(
    fecha.year,
    fecha.month,
    fecha.day,
    horas,
    minutos,
  );
}

String? validarReagendamientoCompleto({
  required DateTime fechaTutoria,
  required DateTime nuevaFecha,
  required String nuevaHoraInicio,
  required String nuevaHoraFin,
}) {
  // Validar anticipación mínima
  final errorAnticipacion = validarAnticipacionMinima(fechaTutoria);
  if (errorAnticipacion != null) {
    return errorAnticipacion;
  }
  
  // Validar que la nueva fecha sea futura
  final errorFecha = validarNuevaFecha(nuevaFecha);
  if (errorFecha != null) {
    return errorFecha;
  }
  
  // Validar nueva fecha-hora con anticipación
  final nuevaFechaHora = construirFechaHora(nuevaFecha, nuevaHoraInicio);
  final errorAnticipacionNueva = validarAnticipacionMinima(nuevaFechaHora);
  if (errorAnticipacionNueva != null) {
    return 'La nueva fecha y hora debe ser al menos 2 horas en el futuro';
  }
  
  return null;
}

Map<String, dynamic> prepararDatosCancelacion({
  required String tutoriaId,
  required String motivo,
  required String canceladaPor,
}) {
  return {
    'tutoriaId': tutoriaId,
    'motivo': normalizarMotivoCancelacion(motivo),
    'canceladaPor': canceladaPor,
    'fechaCancelacion': DateTime.now().toIso8601String(),
  };
}

Map<String, dynamic> prepararDatosReagendamiento({
  required String tutoriaId,
  required String nuevaFecha,
  required String nuevaHoraInicio,
  required String nuevaHoraFin,
  String? motivo,
}) {
  return {
    'tutoriaId': tutoriaId,
    'nuevaFecha': nuevaFecha,
    'nuevaHoraInicio': nuevaHoraInicio,
    'nuevaHoraFin': nuevaHoraFin,
    'motivo': motivo?.trim().isEmpty ?? true 
        ? 'Reagendada por el usuario' 
        : motivo!.trim(),
    'fechaReagendamiento': DateTime.now().toIso8601String(),
  };
}

bool verificarDisponibilidadHorario(
  String horaInicio,
  String horaFin,
  List<Map<String, dynamic>> turnosOcupados,
) {
  final nuevoInicio = _convertirAMinutos(horaInicio);
  final nuevoFin = _convertirAMinutos(horaFin);
  
  for (var turno in turnosOcupados) {
    final ocupadoInicio = _convertirAMinutos(turno['horaInicio']);
    final ocupadoFin = _convertirAMinutos(turno['horaFin']);
    
    // Hay conflicto si se solapan
    if (!(nuevoFin <= ocupadoInicio || nuevoInicio >= ocupadoFin)) {
      return false;
    }
  }
  
  return true;
}

String? validarEstadoParaCancelacion(String estado) {
  if (estado == 'cancelada') {
    return 'La tutoría ya está cancelada';
  }
  
  if (estado == 'finalizada') {
    return 'No se puede cancelar una tutoría finalizada';
  }
  
  if (estado == 'rechazada') {
    return 'No se puede cancelar una tutoría rechazada';
  }
  
  return null;
}

int _convertirAMinutos(String hora) {
  final partes = hora.split(':');
  final horas = int.parse(partes[0]);
  final minutos = int.parse(partes[1]);
  return horas * 60 + minutos;
}