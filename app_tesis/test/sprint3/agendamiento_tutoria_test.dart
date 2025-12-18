// ============================================
// PRUEBA UNITARIA - AGENDAMIENTO DE TUTORÍA
// Figura 3.39: Conclusión de la prueba de software unitaria – Agendamiento de tutoría
// HU-007: Agendar turnos de 20 minutos
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-007: Agendamiento de Tutoría', () {
    
    // ========================================
    // VALIDACIONES DE DURACIÓN DE TURNO
    // ========================================
    
    test('✓ Validación de duración exacta de 20 minutos - válido', () {
      final resultado = validarDuracionTurno('08:00', '08:20');
      expect(resultado, null);
    });

    test('✓ Validación de duración mayor a 20 minutos - inválido', () {
      final resultado = validarDuracionTurno('08:00', '08:30');
      expect(resultado, 'La duración del turno no puede exceder 20 minutos');
    });

    test('✓ Validación de duración menor a 20 minutos - inválido', () {
      final resultado = validarDuracionTurno('08:00', '08:15');
      expect(resultado, 'La duración debe ser exactamente 20 minutos');
    });

    test('✓ Validación de hora fin antes de hora inicio - inválido', () {
      final resultado = validarDuracionTurno('08:30', '08:00');
      expect(resultado, 'Horario inválido: hora de fin debe ser posterior a hora de inicio');
    });

    // ========================================
    // GENERACIÓN DE TURNOS DE 20 MINUTOS
    // ========================================

    test('✓ Generar turnos de 20 minutos - bloque de 1 hora', () {
      final turnos = generarTurnos20Min('08:00', '09:00');
      expect(turnos.length, 3);
      expect(turnos[0], {'horaInicio': '08:00', 'horaFin': '08:20'});
      expect(turnos[1], {'horaInicio': '08:20', 'horaFin': '08:40'});
      expect(turnos[2], {'horaInicio': '08:40', 'horaFin': '09:00'});
    });

    test('✓ Generar turnos de 20 minutos - bloque de 40 minutos', () {
      final turnos = generarTurnos20Min('14:00', '14:40');
      expect(turnos.length, 2);
      expect(turnos[0], {'horaInicio': '14:00', 'horaFin': '14:20'});
      expect(turnos[1], {'horaInicio': '14:20', 'horaFin': '14:40'});
    });

    test('✓ Generar turnos de 20 minutos - bloque de 20 minutos exactos', () {
      final turnos = generarTurnos20Min('10:00', '10:20');
      expect(turnos.length, 1);
      expect(turnos[0], {'horaInicio': '10:00', 'horaFin': '10:20'});
    });

    test('✓ Generar turnos de 20 minutos - bloque de 2 horas', () {
      final turnos = generarTurnos20Min('08:00', '10:00');
      expect(turnos.length, 6);
    });

    // ========================================
    // VALIDACIÓN DE SOLAPAMIENTOS
    // ========================================

    test('✓ Detectar solapamiento - turnos consecutivos sin conflicto', () {
      final turnoNuevo = {'horaInicio': '08:20', 'horaFin': '08:40'};
      final turnosExistentes = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
      ];
      final resultado = validarSolapamiento(turnoNuevo, turnosExistentes);
      expect(resultado, true); // true = disponible
    });

    test('✓ Detectar solapamiento - conflicto total', () {
      final turnoNuevo = {'horaInicio': '08:00', 'horaFin': '08:20'};
      final turnosExistentes = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
      ];
      final resultado = validarSolapamiento(turnoNuevo, turnosExistentes);
      expect(resultado, false); // false = ocupado
    });

    test('✓ Detectar solapamiento - conflicto parcial inicio', () {
      final turnoNuevo = {'horaInicio': '08:10', 'horaFin': '08:30'};
      final turnosExistentes = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
      ];
      final resultado = validarSolapamiento(turnoNuevo, turnosExistentes);
      expect(resultado, false);
    });

    test('✓ Detectar solapamiento - conflicto parcial fin', () {
      final turnoNuevo = {'horaInicio': '07:50', 'horaFin': '08:10'};
      final turnosExistentes = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
      ];
      final resultado = validarSolapamiento(turnoNuevo, turnosExistentes);
      expect(resultado, false);
    });

    // ========================================
    // CONTEO DE TURNOS DISPONIBLES
    // ========================================

    test('✓ Calcular estadísticas de turnos - todos disponibles', () {
      final turnos = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
        {'horaInicio': '08:20', 'horaFin': '08:40'},
        {'horaInicio': '08:40', 'horaFin': '09:00'},
      ];
      final ocupados = <Map<String, dynamic>>[];
      
      final stats = calcularEstadisticasTurnos(turnos, ocupados);
      
      expect(stats['total'], 3);
      expect(stats['disponibles'], 3);
      expect(stats['ocupados'], 0);
    });

    test('✓ Calcular estadísticas de turnos - algunos ocupados', () {
      final turnos = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
        {'horaInicio': '08:20', 'horaFin': '08:40'},
        {'horaInicio': '08:40', 'horaFin': '09:00'},
      ];
      final ocupados = [
        {'horaInicio': '08:00', 'horaFin': '08:20'},
      ];
      
      final stats = calcularEstadisticasTurnos(turnos, ocupados);
      
      expect(stats['total'], 3);
      expect(stats['disponibles'], 2);
      expect(stats['ocupados'], 1);
    });

    // ========================================
    // VALIDACIÓN DE FECHA Y HORARIO
    // ========================================

    test('✓ Validación de fecha futura - válida', () {
      final fecha = DateTime.now().add(const Duration(days: 1));
      final resultado = validarFechaFutura(fecha);
      expect(resultado, null);
    });

    test('✓ Validación de fecha futura - fecha pasada', () {
      final fecha = DateTime.now().subtract(const Duration(days: 1));
      final resultado = validarFechaFutura(fecha);
      expect(resultado, 'La fecha debe ser futura');
    });

    test('✓ Validación de fecha futura - hoy mismo', () {
      final fecha = DateTime.now();
      final resultado = validarFechaFutura(fecha);
      expect(resultado, 'La fecha debe ser futura');
    });

    // ========================================
    // FORMATO DE DATOS PARA ENVÍO
    // ========================================

    test('✓ Preparar datos de agendamiento - formato correcto', () {
      final datos = prepararDatosAgendamiento(
        docenteId: '123abc',
        fecha: '2025-12-20',
        horaInicio: '08:00',
        horaFin: '08:20',
      );
      
      expect(datos['docente'], '123abc');
      expect(datos['fecha'], '2025-12-20');
      expect(datos['horaInicio'], '08:00');
      expect(datos['horaFin'], '08:20');
    });

    test('✓ Convertir hora a minutos - casos múltiples', () {
      expect(convertirAMinutos('08:00'), 480);
      expect(convertirAMinutos('08:20'), 500);
      expect(convertirAMinutos('14:30'), 870);
      expect(convertirAMinutos('00:00'), 0);
      expect(convertirAMinutos('23:59'), 1439);
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - AGENDAMIENTO
// ============================================

String? validarDuracionTurno(String horaInicio, String horaFin) {
  final minutosInicio = convertirAMinutos(horaInicio);
  final minutosFin = convertirAMinutos(horaFin);
  final duracion = minutosFin - minutosInicio;
  
  if (duracion <= 0) {
    return 'Horario inválido: hora de fin debe ser posterior a hora de inicio';
  }
  
  if (duracion > 20) {
    return 'La duración del turno no puede exceder 20 minutos';
  }
  
  if (duracion < 20) {
    return 'La duración debe ser exactamente 20 minutos';
  }
  
  return null;
}

List<Map<String, String>> generarTurnos20Min(String inicio, String fin) {
  final minutosInicio = convertirAMinutos(inicio);
  final minutosFin = convertirAMinutos(fin);
  final duracionTurno = 20;
  
  List<Map<String, String>> turnos = [];
  int actual = minutosInicio;
  
  while (actual + duracionTurno <= minutosFin) {
    turnos.add({
      'horaInicio': formatearHora(actual),
      'horaFin': formatearHora(actual + duracionTurno),
    });
    actual += duracionTurno;
  }
  
  return turnos;
}

bool validarSolapamiento(
  Map<String, dynamic> turnoNuevo,
  List<Map<String, dynamic>> turnosExistentes,
) {
  final nuevoInicio = convertirAMinutos(turnoNuevo['horaInicio']);
  final nuevoFin = convertirAMinutos(turnoNuevo['horaFin']);
  
  for (var turno in turnosExistentes) {
    final existenteInicio = convertirAMinutos(turno['horaInicio']);
    final existenteFin = convertirAMinutos(turno['horaFin']);
    
    // Hay solapamiento si NO están completamente separados
    if (!(nuevoFin <= existenteInicio || nuevoInicio >= existenteFin)) {
      return false; // Ocupado
    }
  }
  
  return true; // Disponible
}

Map<String, int> calcularEstadisticasTurnos(
  List<Map<String, dynamic>> turnos,
  List<Map<String, dynamic>> ocupados,
) {
  int disponibles = 0;
  
  for (var turno in turnos) {
    if (validarSolapamiento(turno, ocupados)) {
      disponibles++;
    }
  }
  
  return {
    'total': turnos.length,
    'disponibles': disponibles,
    'ocupados': turnos.length - disponibles,
  };
}

String? validarFechaFutura(DateTime fecha) {
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
  
  if (fechaSinHora.isBefore(hoy) || fechaSinHora.isAtSameMomentAs(hoy)) {
    return 'La fecha debe ser futura';
  }
  
  return null;
}

Map<String, dynamic> prepararDatosAgendamiento({
  required String docenteId,
  required String fecha,
  required String horaInicio,
  required String horaFin,
}) {
  return {
    'docente': docenteId,
    'fecha': fecha,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
  };
}

int convertirAMinutos(String hora) {
  final partes = hora.split(':');
  final horas = int.parse(partes[0]);
  final minutos = int.parse(partes[1]);
  return horas * 60 + minutos;
}

String formatearHora(int minutos) {
  final horas = minutos ~/ 60;
  final mins = minutos % 60;
  return '${horas.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
}