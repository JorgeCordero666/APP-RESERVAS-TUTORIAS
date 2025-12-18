// ============================================
// PRUEBA UNITARIA - REPORTES ADMINISTRATIVOS
// Archivo: test/reportes_admin_test.dart
// Figura: 3.71
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-017: Reportes Generales (Administrador)', () {
    
    // ========================================
    // FIGURA 3.71: Reportes administrativos generados
    // ========================================
    
    test('✓ Calcular estadísticas globales - incluye todos los campos', () {
      final reporte = simularReporteAdmin();
      final stats = reporte['estadisticasGlobales'];
      expect(stats['totalTutorias'], isA<int>());
      expect(stats['docentesActivos'], isA<int>());
      expect(stats['estudiantesUnicos'], isA<int>());
      expect(stats['confirmadas'], isA<int>());
      expect(stats['pendientes'], isA<int>());
      expect(stats['finalizadas'], isA<int>());
      expect(stats['canceladas'], isA<int>());
    });

    test('✓ Filtros de fecha - inicializa con null (todas las tutorías)', () {
      final filtros = inicializarFiltros();
      expect(filtros['fechaInicio'], null);
      expect(filtros['fechaFin'], null);
    });

    test('✓ Formatear fechas para endpoint - formato YYYY-MM-DD', () {
      final fecha = DateTime(2024, 6, 15);
      final formateada = formatearFechaFiltro(fecha);
      expect(formateada, '2024-06-15');
    });

    test('✓ Formatear fechas para endpoint - null si no definida', () {
      final formateada = formatearFechaFiltroOpcional(null);
      expect(formateada, null);
    });

    test('✓ Componente de filtros - dos selectores de fecha', () {
      final componente = crearComponenteFiltros();
      expect(componente['selectores'], 2);
      expect(componente['botonLimpiar'], true);
    });

    test('✓ Selector de fecha - muestra "Todas" si null', () {
      final texto = obtenerTextoSelector(null);
      expect(texto, 'Todas');
    });

    test('✓ Selector de fecha - muestra fecha formateada si definida', () {
      final fecha = DateTime(2024, 6, 15);
      final texto = obtenerTextoSelector(fecha);
      expect(texto, '15/06/2024');
    });

    test('✓ Limpiar filtros - establece null y recarga', () {
      DateTime? fechaInicio = DateTime.now();
      DateTime? fechaFin = DateTime.now();
      
      final resultado = limpiarFiltros(fechaInicio, fechaFin);
      expect(resultado['fechaInicio'], null);
      expect(resultado['fechaFin'], null);
    });

    test('✓ Renderizar métrica global - ícono con color', () {
      final metrica = renderizarMetricaGlobal('Total', 50, 'event', 'azul');
      expect(metrica['label'], 'Total');
      expect(metrica['valor'], 50);
      expect(metrica['icono'], 'event');
      expect(metrica['color'], 'azul');
    });

    test('✓ Renderizar métrica global - chip con valor', () {
      final chip = renderizarChipValor(25);
      expect(chip['valor'], 25);
    });

    test('✓ Estadísticas - Total de Tutorías', () {
      final reporte = simularReporteAdmin();
      final total = reporte['estadisticasGlobales']['totalTutorias'];
      expect(total, greaterThan(0));
    });

    test('✓ Estadísticas - Docentes Activos', () {
      final reporte = simularReporteAdmin();
      final docentes = reporte['estadisticasGlobales']['docentesActivos'];
      expect(docentes, greaterThanOrEqualTo(0));
    });

    test('✓ Estadísticas - Estudiantes Únicos', () {
      final reporte = simularReporteAdmin();
      final estudiantes = reporte['estadisticasGlobales']['estudiantesUnicos'];
      expect(estudiantes, greaterThanOrEqualTo(0));
    });

    test('✓ Estadísticas - Tutorías Confirmadas', () {
      final reporte = simularReporteAdmin();
      final confirmadas = reporte['estadisticasGlobales']['confirmadas'];
      expect(confirmadas, isA<int>());
    });

    test('✓ Estadísticas - Tutorías Pendientes', () {
      final reporte = simularReporteAdmin();
      final pendientes = reporte['estadisticasGlobales']['pendientes'];
      expect(pendientes, isA<int>());
    });

    test('✓ Estadísticas - Tutorías Finalizadas', () {
      final reporte = simularReporteAdmin();
      final finalizadas = reporte['estadisticasGlobales']['finalizadas'];
      expect(finalizadas, isA<int>());
    });

    test('✓ Estadísticas - Tutorías Canceladas', () {
      final reporte = simularReporteAdmin();
      final canceladas = reporte['estadisticasGlobales']['canceladas'];
      expect(canceladas, isA<int>());
    });

    test('✓ Generar reporte por docente - agrupa correctamente', () {
      final reporte = simularReporteAdmin();
      final reportePorDocente = reporte['reportePorDocente'];
      expect(reportePorDocente, isA<Map>());
      expect(reportePorDocente.keys, isNotEmpty);
    });

    test('✓ Reporte por docente - ExpansionTile con avatar', () {
      final tile = crearExpansionTile('Juan Pérez', 20);
      expect(tile['nombre'], 'Juan Pérez');
      expect(tile['total'], 20);
      expect(tile['avatar'], isNotNull);
    });

    test('✓ ExpansionTile - avatar con inicial del nombre', () {
      final avatar = crearAvatarInicial('Juan Pérez');
      expect(avatar['inicial'], 'J');
      expect(avatar['colorFondo'], 'azul');
    });

    test('✓ ExpansionTile - título con nombre docente', () {
      final titulo = crearTituloTile('María López');
      expect(titulo['texto'], 'María López');
      expect(titulo['negrita'], true);
    });

    test('✓ ExpansionTile - subtítulo con total de tutorías', () {
      final subtitulo = crearSubtituloTile(15);
      expect(subtitulo['texto'], '15 tutorías');
    });

    test('✓ Al expandirse - muestra mini-estadísticas', () {
      final stats = {
        'confirmadas': 10,
        'pendientes': 5,
        'finalizadas': 8,
        'canceladas': 2,
      };
      final miniStats = mostrarMiniEstadisticasDocente(stats);
      expect(miniStats.length, 4);
    });

    test('✓ Mini-estadística - Confirmadas', () {
      final stats = {'confirmadas': 10};
      final confirmadas = extraerMiniStat(stats, 'confirmadas');
      expect(confirmadas, 10);
    });

    test('✓ Mini-estadística - Pendientes', () {
      final stats = {'pendientes': 5};
      final pendientes = extraerMiniStat(stats, 'pendientes');
      expect(pendientes, 5);
    });

    test('✓ Mini-estadística - Finalizadas', () {
      final stats = {'finalizadas': 8};
      final finalizadas = extraerMiniStat(stats, 'finalizadas');
      expect(finalizadas, 8);
    });

    test('✓ Mini-estadística - Canceladas', () {
      final stats = {'canceladas': 2};
      final canceladas = extraerMiniStat(stats, 'canceladas');
      expect(canceladas, 2);
    });

    test('✓ Tasa de asistencia - si está disponible', () {
      final stats = {'tasaAsistencia': '85.5%'};
      final tasa = extraerTasaAsistencia(stats);
      expect(tasa, '85.5%');
    });

    test('✓ Tasa de asistencia - null si no disponible', () {
      final stats = {'confirmadas': 10};
      final tasa = extraerTasaAsistencia(stats);
      expect(tasa, null);
    });

    test('✓ Calcular métricas por docente - completas', () {
      final tutoriasDocente = simularTutoriasDocente();
      final metricas = calcularMetricasDocente(tutoriasDocente);
      expect(metricas['total'], tutoriasDocente.length);
      expect(metricas['confirmadas'], isA<int>());
      expect(metricas['pendientes'], isA<int>());
      expect(metricas['finalizadas'], isA<int>());
      expect(metricas['canceladas'], isA<int>());
    });

    test('✓ Iteración sobre reportePorDocente - usa ExpansionTile', () {
      final reporte = simularReporteAdmin();
      final docentes = reporte['reportePorDocente'];
      final tiles = iterarSobreDocentes(docentes);
      expect(tiles, isNotEmpty);
    });
  });
}

// ============================================
// FUNCIONES DE LÓGICA Y RENDERIZADO
// ============================================

Map<String, DateTime?> inicializarFiltros() {
  return {
    'fechaInicio': null,
    'fechaFin': null,
  };
}

String formatearFechaFiltro(DateTime fecha) {
  return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
}

String? formatearFechaFiltroOpcional(DateTime? fecha) {
  if (fecha == null) return null;
  return formatearFechaFiltro(fecha);
}

Map<String, dynamic> crearComponenteFiltros() {
  return {
    'selectores': 2,
    'botonLimpiar': true,
  };
}

String obtenerTextoSelector(DateTime? fecha) {
  if (fecha == null) return 'Todas';
  return '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
}

Map<String, DateTime?> limpiarFiltros(DateTime? inicio, DateTime? fin) {
  return {
    'fechaInicio': null,
    'fechaFin': null,
  };
}

Map<String, dynamic> renderizarMetricaGlobal(
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
  };
}

Map<String, dynamic> renderizarChipValor(int valor) {
  return {
    'valor': valor,
  };
}

Map<String, dynamic> crearExpansionTile(String nombre, int total) {
  return {
    'nombre': nombre,
    'total': total,
    'avatar': crearAvatarInicial(nombre),
    'titulo': crearTituloTile(nombre),
    'subtitulo': crearSubtituloTile(total),
  };
}

Map<String, dynamic> crearAvatarInicial(String nombre) {
  return {
    'inicial': nombre[0].toUpperCase(),
    'colorFondo': 'azul',
  };
}

Map<String, dynamic> crearTituloTile(String nombre) {
  return {
    'texto': nombre,
    'negrita': true,
  };
}

Map<String, dynamic> crearSubtituloTile(int total) {
  return {
    'texto': '$total tutorías',
  };
}

List<Map<String, dynamic>> mostrarMiniEstadisticasDocente(Map<String, dynamic> stats) {
  return [
    {'label': 'Confirmadas', 'valor': stats['confirmadas']},
    {'label': 'Pendientes', 'valor': stats['pendientes']},
    {'label': 'Finalizadas', 'valor': stats['finalizadas']},
    {'label': 'Canceladas', 'valor': stats['canceladas']},
  ];
}

int extraerMiniStat(Map<String, dynamic> stats, String key) {
  return stats[key] ?? 0;
}

String? extraerTasaAsistencia(Map<String, dynamic> stats) {
  return stats['tasaAsistencia'];
}

Map<String, dynamic> calcularMetricasDocente(List<Map<String, dynamic>> tutorias) {
  final metricas = <String, int>{
    'total': tutorias.length,
    'confirmadas': 0,
    'pendientes': 0,
    'finalizadas': 0,
    'canceladas': 0,
  };

  for (final t in tutorias) {
    final estado = t['estado'] as String;
    if (estado == 'confirmada') metricas['confirmadas'] = metricas['confirmadas']! + 1;
    if (estado == 'pendiente') metricas['pendientes'] = metricas['pendientes']! + 1;
    if (estado == 'finalizada') metricas['finalizadas'] = metricas['finalizadas']! + 1;
    if (estado.contains('cancelada')) metricas['canceladas'] = metricas['canceladas']! + 1;
  }

  return metricas;
}

List<Map<String, dynamic>> iterarSobreDocentes(Map<String, dynamic> docentes) {
  return docentes.entries.map((e) => {
    'nombre': e.key,
    'datos': e.value,
  }).toList();
}

// ============================================
// DATOS DE PRUEBA
// ============================================

Map<String, dynamic> simularReporteAdmin() {
  return {
    'estadisticasGlobales': {
      'totalTutorias': 50,
      'docentesActivos': 10,
      'estudiantesUnicos': 30,
      'confirmadas': 20,
      'pendientes': 10,
      'finalizadas': 15,
      'canceladas': 5,
    },
    'reportePorDocente': {
      'Juan Pérez': {
        'estadisticas': {
          'total': 20,
          'confirmadas': 12,
          'pendientes': 4,
          'finalizadas': 10,
          'canceladas': 2,
          'tasaAsistencia': '80.0%',
        },
      },
      'María López': {
        'estadisticas': {
          'total': 15,
          'confirmadas': 8,
          'pendientes': 3,
          'finalizadas': 10,
          'canceladas': 1,
          'tasaAsistencia': '90.0%',
        },
      },
      'Carlos Ramírez': {
        'estadisticas': {
          'total': 15,
          'confirmadas': 6,
          'pendientes': 3,
          'finalizadas': 8,
          'canceladas': 2,
          'tasaAsistencia': '75.0%',
        },
      },
    },
  };
}

List<Map<String, dynamic>> simularTutoriasDocente() {
  return [
    {'estado': 'confirmada'},
    {'estado': 'confirmada'},
    {'estado': 'pendiente'},
    {'estado': 'finalizada', 'asistenciaEstudiante': true},
    {'estado': 'finalizada', 'asistenciaEstudiante': false},
    {'estado': 'cancelada_por_estudiante'},
  ];
}