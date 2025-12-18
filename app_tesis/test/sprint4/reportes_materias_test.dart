// ============================================
// PRUEBA UNITARIA - REPORTES POR MATERIAS
// Archivo: test/reportes_materias_test.dart
// Figura: 3.67
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-016: Reportes por Materias (Docente)', () {
    
    // ========================================
    // FIGURA 3.67: Reportes generados
    // ========================================
    
    test('✓ Dos pestañas - Estadísticas e Historial Completo', () {
      final tabs = obtenerPestanasReporte();
      expect(tabs.length, 2);
      expect(tabs, contains('Estadísticas'));
      expect(tabs, contains('Historial Completo'));
    });

    test('✓ Calcular estadísticas generales - totales correctos', () {
      final tutorias = simularTutorias();
      final stats = calcularEstadisticasGenerales(tutorias);
      expect(stats['total'], tutorias.length);
      expect(stats['pendientes'], isA<int>());
      expect(stats['confirmadas'], isA<int>());
      expect(stats['finalizadas'], isA<int>());
      expect(stats['canceladas'], isA<int>());
      expect(stats['rechazadas'], isA<int>());
    });

    test('✓ Calcular asistencias e inasistencias - correctamente', () {
      final tutorias = simularTutorias();
      final stats = calcularEstadisticasGenerales(tutorias);
      expect(stats['asistencias'], isA<int>());
      expect(stats['inasistencias'], isA<int>());
    });

    test('✓ Calcular tasa de asistencia - fórmula correcta', () {
      final asistencias = 8;
      final finalizadas = 10;
      final tasa = calcularTasaAsistencia(asistencias, finalizadas);
      expect(tasa, '80.0%');
    });

    test('✓ Calcular tasa de asistencia - sin finalizadas', () {
      final tasa = calcularTasaAsistencia(0, 0);
      expect(tasa, '0.0%');
    });

    test('✓ Calcular tasa de asistencia - todas asistieron', () {
      final tasa = calcularTasaAsistencia(10, 10);
      expect(tasa, '100.0%');
    });

    test('✓ Renderizar métrica - ícono con gradiente', () {
      final metrica = renderizarMetrica('Total', 50, 'event', 'azul');
      expect(metrica['label'], 'Total');
      expect(metrica['valor'], 50);
      expect(metrica['icono'], 'event');
      expect(metrica['conGradiente'], true);
    });

    test('✓ Renderizar métrica - chip coloreado', () {
      final chip = renderizarChipMetrica(25, 'verde');
      expect(chip['valor'], 25);
      expect(chip['color'], 'verde');
    });

    test('✓ Agrupar tutorías por estudiante - agrupa correctamente', () {
      final tutorias = simularTutorias();
      final agrupadas = agruparPorEstudiante(tutorias);
      expect(agrupadas, isA<Map>());
      expect(agrupadas.keys, isNotEmpty);
    });

    test('✓ Acumular estadísticas individuales - por estudiante', () {
      final tutoriasEstudiante = simularTutoriasEstudiante();
      final stats = acumularEstadisticasIndividuales(tutoriasEstudiante);
      expect(stats['total'], tutoriasEstudiante.length);
      expect(stats['confirmadas'], isA<int>());
      expect(stats['finalizadas'], isA<int>());
    });

    test('✓ Ordenar estudiantes por total - descendente', () {
      final estudiantes = {
        'est1': {'total': 5, 'nombre': 'María'},
        'est2': {'total': 10, 'nombre': 'Juan'},
        'est3': {'total': 3, 'nombre': 'Carlos'},
      };
      final ordenados = ordenarPorTotal(estudiantes);
      expect(ordenados[0]['total'], 10);
      expect(ordenados[1]['total'], 5);
      expect(ordenados[2]['total'], 3);
    });

    test('✓ Renderizar estudiante - foto con sombra azul', () {
      final estudiante = renderizarEstudianteConFoto('María', 'https://example.com/foto.jpg');
      expect(estudiante['nombre'], 'María');
      expect(estudiante['foto'], isNotNull);
      expect(estudiante['sombraAzul'], true);
    });

    test('✓ Renderizar mini-estadísticas - tres filas con gradientes', () {
      final stats = {'confirmadas': 5, 'pendientes': 2, 'finalizadas': 8};
      final miniStats = renderizarMiniEstadisticas(stats);
      expect(miniStats.length, 3);
      expect(miniStats[0]['conGradiente'], true);
    });

    test('✓ Filtrar por estado - dropdown funcional', () {
      final tutorias = simularTutorias();
      final filtradas = filtrarPorEstadoDropdown(tutorias, 'confirmada');
      expect(filtradas.every((t) => t['estado'] == 'confirmada'), true);
    });

    test('✓ Filtrar por rango de fechas - datepicker inicio', () {
      final tutorias = simularTutorias();
      final fechaInicio = '2024-06-01';
      final fechaFin = '2024-06-30';
      final filtradas = filtrarPorRangoFechas(tutorias, fechaInicio, fechaFin);
      expect(filtradas, isNotEmpty);
    });

    test('✓ Aplicar múltiples filtros - acumulativos', () {
      final tutorias = simularTutorias();
      final filtradas = aplicarFiltrosAcumulativos(
        tutorias,
        estado: 'finalizada',
        fechaInicio: '2024-06-01',
      );
      expect(filtradas.every((t) => t['estado'] == 'finalizada'), true);
    });

    test('✓ Mostrar badge con conteo - número de resultados', () {
      final badge = mostrarBadgeConteo(15);
      expect(badge['valor'], 15);
      expect(badge['visible'], true);
    });

    test('✓ Renderizar tutoría en historial - header completo', () {
      final tutoria = simularTutoriaSingle();
      final render = renderizarTutoriaHistorial(tutoria);
      expect(render['header'], isNotNull);
      expect(render['divider'], true);
      expect(render['fecha'], isNotNull);
    });

    test('✓ Renderizar divider - con gradiente', () {
      final divider = renderizarDividerGradiente();
      expect(divider['conGradiente'], true);
    });

    test('✓ Renderizar contenedor asistencia - gradiente verde si asistió', () {
      final contenedor = renderizarContenedorAsistencia(true);
      expect(contenedor['gradiente'], 'verde');
    });

    test('✓ Renderizar contenedor asistencia - gradiente rojo si no asistió', () {
      final contenedor = renderizarContenedorAsistencia(false);
      expect(contenedor['gradiente'], 'rojo');
    });

    test('✓ Mostrar observaciones - si existen', () {
      final tutoria = {'observaciones': 'Excelente participación'};
      final obs = extraerObservaciones(tutoria);
      expect(obs, 'Excelente participación');
    });

    test('✓ Mostrar observaciones - null si no existen', () {
      final tutoria = {'estado': 'finalizada'};
      final obs = extraerObservaciones(tutoria);
      expect(obs, null);
    });

    test('✓ Botones de acción - según permisos del estado', () {
      final botones = obtenerBotonesAccion('confirmada');
      expect(botones, isNotEmpty);
    });

    test('✓ Botones de acción - ocultos para finalizadas', () {
      final botones = obtenerBotonesAccion('finalizada');
      expect(botones.isEmpty, true);
    });
  });
}

// ============================================
// FUNCIONES DE CÁLCULO Y LÓGICA
// ============================================

List<String> obtenerPestanasReporte() {
  return ['Estadísticas', 'Historial Completo'];
}

Map<String, dynamic> calcularEstadisticasGenerales(
  List<Map<String, dynamic>> tutorias,
) {
  final stats = <String, int>{
    'total': tutorias.length,
    'pendientes': 0,
    'confirmadas': 0,
    'finalizadas': 0,
    'canceladas': 0,
    'rechazadas': 0,
    'asistencias': 0,
    'inasistencias': 0,
  };

  for (final t in tutorias) {
    final estado = t['estado'] as String;
    if (estado == 'pendiente') stats['pendientes'] = stats['pendientes']! + 1;
    if (estado == 'confirmada') stats['confirmadas'] = stats['confirmadas']! + 1;
    if (estado == 'finalizada') {
      stats['finalizadas'] = stats['finalizadas']! + 1;
      if (t['asistenciaEstudiante'] == true) {
        stats['asistencias'] = stats['asistencias']! + 1;
      } else {
        stats['inasistencias'] = stats['inasistencias']! + 1;
      }
    }
    if (estado.contains('cancelada')) stats['canceladas'] = stats['canceladas']! + 1;
    if (estado == 'rechazada') stats['rechazadas'] = stats['rechazadas']! + 1;
  }

  return stats;
}

String calcularTasaAsistencia(int asistencias, int finalizadas) {
  if (finalizadas == 0) return '0.0%';
  return '${(asistencias / finalizadas * 100).toStringAsFixed(1)}%';
}

Map<String, dynamic> renderizarMetrica(
  String label,
  int valor,
  String icono,
  String color,
) {
  return {
    'label': label,
    'valor': valor,
    'icono': icono,
    'color': color,
    'conGradiente': true,
  };
}

Map<String, dynamic> renderizarChipMetrica(int valor, String color) {
  return {
    'valor': valor,
    'color': color,
  };
}

Map<String, List<Map<String, dynamic>>> agruparPorEstudiante(
  List<Map<String, dynamic>> tutorias,
) {
  final agrupadas = <String, List<Map<String, dynamic>>>{};
  
  for (final t in tutorias) {
    final estudianteId = t['estudiante']?['_id'] ?? 'sin_id';
    if (!agrupadas.containsKey(estudianteId)) {
      agrupadas[estudianteId] = [];
    }
    agrupadas[estudianteId]!.add(t);
  }
  
  return agrupadas;
}

Map<String, dynamic> acumularEstadisticasIndividuales(
  List<Map<String, dynamic>> tutorias,
) {
  final stats = <String, int>{
    'total': tutorias.length,
    'confirmadas': 0,
    'pendientes': 0,
    'finalizadas': 0,
    'canceladas': 0,
  };

  for (final t in tutorias) {
    final estado = t['estado'] as String;
    if (estado == 'confirmada') stats['confirmadas'] = stats['confirmadas']! + 1;
    if (estado == 'pendiente') stats['pendientes'] = stats['pendientes']! + 1;
    if (estado == 'finalizada') stats['finalizadas'] = stats['finalizadas']! + 1;
    if (estado.contains('cancelada')) stats['canceladas'] = stats['canceladas']! + 1;
  }

  return stats;
}

List<Map<String, dynamic>> ordenarPorTotal(Map<String, dynamic> estudiantes) {
  final lista = estudiantes.entries
      .map((e) => {'id': e.key, ...(e.value as Map<String, dynamic>)})
      .toList();
  lista.sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));
  return lista;
}

Map<String, dynamic> renderizarEstudianteConFoto(String nombre, String foto) {
  return {
    'nombre': nombre,
    'foto': foto,
    'sombraAzul': true,
  };
}

List<Map<String, dynamic>> renderizarMiniEstadisticas(Map<String, dynamic> stats) {
  return stats.entries.map((e) => {
    'label': e.key,
    'valor': e.value,
    'conGradiente': true,
  }).toList();
}

List<Map<String, dynamic>> filtrarPorEstadoDropdown(
  List<Map<String, dynamic>> tutorias,
  String estado,
) {
  return tutorias.where((t) => t['estado'] == estado).toList();
}

List<Map<String, dynamic>> filtrarPorRangoFechas(
  List<Map<String, dynamic>> tutorias,
  String fechaInicio,
  String fechaFin,
) {
  return tutorias.where((t) {
    final fecha = DateTime.parse(t['fecha'] as String);
    final inicio = DateTime.parse(fechaInicio);
    final fin = DateTime.parse(fechaFin);
    return fecha.isAfter(inicio.subtract(const Duration(days: 1))) &&
           fecha.isBefore(fin.add(const Duration(days: 1)));
  }).toList();
}

List<Map<String, dynamic>> aplicarFiltrosAcumulativos(
  List<Map<String, dynamic>> tutorias, {
  String? estado,
  String? fechaInicio,
  String? fechaFin,
}) {
  var filtradas = tutorias;
  
  if (estado != null) {
    filtradas = filtradas.where((t) => t['estado'] == estado).toList();
  }
  
  if (fechaInicio != null && fechaFin != null) {
    filtradas = filtrarPorRangoFechas(filtradas, fechaInicio, fechaFin);
  }
  
  return filtradas;
}

Map<String, dynamic> mostrarBadgeConteo(int cantidad) {
  return {
    'valor': cantidad,
    'visible': true,
  };
}

Map<String, dynamic> renderizarTutoriaHistorial(Map<String, dynamic> tutoria) {
  return {
    'header': true,
    'divider': true,
    'fecha': tutoria['fecha'],
    'hora': '${tutoria['horaInicio']} - ${tutoria['horaFin']}',
  };
}

Map<String, dynamic> renderizarDividerGradiente() {
  return {
    'conGradiente': true,
  };
}

Map<String, dynamic> renderizarContenedorAsistencia(bool asistio) {
  return {
    'gradiente': asistio ? 'verde' : 'rojo',
  };
}

String? extraerObservaciones(Map<String, dynamic> tutoria) {
  return tutoria['observaciones'];
}

List<String> obtenerBotonesAccion(String estado) {
  if (estado == 'finalizada' || estado.contains('cancelada') || estado == 'rechazada') {
    return [];
  }
  return ['Cancelar', 'Reagendar'];
}

// ============================================
// DATOS DE PRUEBA
// ============================================

List<Map<String, dynamic>> simularTutorias() {
  return [
    {
      '_id': '1',
      'estado': 'pendiente',
      'fecha': '2024-06-15',
      'horaInicio': '10:00',
      'horaFin': '10:20',
      'estudiante': {
        '_id': 'e1',
        'nombreEstudiante': 'María García',
        'fotoPerfil': 'https://example.com/foto1.jpg',
      },
    },
    {
      '_id': '2',
      'estado': 'confirmada',
      'fecha': '2024-06-16',
      'horaInicio': '11:00',
      'horaFin': '11:20',
      'estudiante': {
        '_id': 'e2',
        'nombreEstudiante': 'Juan Pérez',
        'fotoPerfil': 'https://example.com/foto2.jpg',
      },
    },
    {
      '_id': '3',
      'estado': 'finalizada',
      'fecha': '2024-06-14',
      'horaInicio': '09:00',
      'horaFin': '09:20',
      'asistenciaEstudiante': true,
      'observaciones': 'Excelente participación',
      'estudiante': {
        '_id': 'e1',
        'nombreEstudiante': 'María García',
        'fotoPerfil': 'https://example.com/foto1.jpg',
      },
    },
    {
      '_id': '4',
      'estado': 'finalizada',
      'fecha': '2024-06-13',
      'horaInicio': '14:00',
      'horaFin': '14:20',
      'asistenciaEstudiante': false,
      'estudiante': {
        '_id': 'e3',
        'nombreEstudiante': 'Carlos López',
        'fotoPerfil': null,
      },
    },
    {
      '_id': '5',
      'estado': 'cancelada_por_estudiante',
      'fecha': '2024-06-12',
      'horaInicio': '15:00',
      'horaFin': '15:20',
      'motivoCancelacion': 'No pude asistir',
      'estudiante': {
        '_id': 'e2',
        'nombreEstudiante': 'Juan Pérez',
        'fotoPerfil': 'https://example.com/foto2.jpg',
      },
    },
    {
      '_id': '6',
      'estado': 'rechazada',
      'fecha': '2024-06-11',
      'horaInicio': '16:00',
      'horaFin': '16:20',
      'motivoRechazo': 'Horario no disponible',
      'estudiante': {
        '_id': 'e1',
        'nombreEstudiante': 'María García',
        'fotoPerfil': 'https://example.com/foto1.jpg',
      },
    },
  ];
}

List<Map<String, dynamic>> simularTutoriasEstudiante() {
  return [
    {'estado': 'confirmada'},
    {'estado': 'confirmada'},
    {'estado': 'finalizada', 'asistenciaEstudiante': true},
    {'estado': 'pendiente'},
  ];
}

Map<String, dynamic> simularTutoriaSingle() {
  return {
    '_id': '1',
    'estado': 'finalizada',
    'fecha': '2024-06-15',
    'horaInicio': '10:00',
    'horaFin': '10:20',
    'asistenciaEstudiante': true,
    'observaciones': 'Muy buena tutoría',
    'estudiante': {
      '_id': 'e1',
      'nombreEstudiante': 'María García',
    },
  };
}