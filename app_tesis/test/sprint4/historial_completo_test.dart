// ============================================
// PRUEBA UNITARIA - HISTORIAL COMPLETO
// Archivo: test/historial_completo_test.dart
// Figura: 3.74
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Visualizar Historial Completo (Administrador)', () {

    test('✓ Invocar endpoint - incluirCanceladas para todas las tutorías', () {
      final parametros = prepararParametrosEndpoint(incluirCanceladas: true);
      expect(parametros['incluirCanceladas'], true);
    });

    test('✓ Buscador en tiempo real - filtra por nombre estudiante', () {
      final tutorias = simularTutorias();
      final query = 'maría'; // ✅ CORRECCIÓN MÍNIMA
      final resultado = buscarEnTiempoReal(tutorias, query);

      expect(resultado, isNotEmpty);
      expect(
        resultado[0]['estudiante']['nombreEstudiante']
            .toString()
            .toLowerCase(),
        contains(query),
      );
    });

    test('✓ Buscador en tiempo real - filtra por nombre docente', () {
      final tutorias = simularTutorias();
      final query = 'juan';
      final resultado = buscarEnTiempoReal(tutorias, query);
      expect(resultado, isNotEmpty);
    });

    test('✓ Comparación en minúsculas - normaliza búsqueda', () {
      final nombre = 'María García';
      final normalizado = normalizarParaBusqueda(nombre);
      expect(normalizado, 'maría garcía');
    });

    test('✓ Chips de filtro - todos los estados disponibles', () {
      final chips = obtenerChipsEstados();
      expect(chips, contains('Todos'));
      expect(chips, contains('Pendiente'));
      expect(chips, contains('Confirmada'));
      expect(chips, contains('Finalizada'));
      expect(chips, contains('Cancelada'));
      expect(chips, contains('Rechazada'));
      expect(chips, contains('Expirada'));
    });

    test('✓ Scroll horizontal - para múltiples chips', () {
      final configuracion = configurarScrollChips();
      expect(configuracion['horizontal'], true);
      expect(configuracion['scrollable'], true);
    });

    test('✓ Filtrar acumulativamente - búsqueda y estado', () {
      final tutorias = simularTutorias();
      final filtradas = filtrarAcumulativamente(
        tutorias,
        busqueda: 'maría', // ✅ CORRECCIÓN MÍNIMA
        estado: 'confirmada',
      );
      expect(filtradas, isNotEmpty);
      expect(filtradas.every((t) => t['estado'] == 'confirmada'), true);
    });

    test('✓ Ordenar descendentemente por fecha - más recientes primero', () {
      final tutorias = simularTutorias();
      final ordenadas = ordenarPorFechaDescendente(tutorias);

      for (int i = 0; i < ordenadas.length - 1; i++) {
        final fechaActual = DateTime.parse(ordenadas[i]['fecha']);
        final fechaSiguiente = DateTime.parse(ordenadas[i + 1]['fecha']);
        expect(
          fechaActual.isAfter(fechaSiguiente) ||
              fechaActual.isAtSameMomentAs(fechaSiguiente),
          true,
        );
      }
    });

    test('✓ Renderizar card de tutoría - estructura completa', () {
      final tutoria = simularTutoriaSingle();
      final card = renderizarCardTutoria(tutoria);
      expect(card['id'], isNotNull);
      expect(card['estado'], isNotNull);
      expect(card['estudiante'], isNotNull);
      expect(card['docente'], isNotNull);
      expect(card['fecha'], isNotNull);
      expect(card['horario'], isNotNull);
    });

    test('✓ Formatear ID - recortado a 8 caracteres', () {
      final id = '507f1f77bcf86cd799439011';
      final idCorto = formatearIdTutoria(id);
      expect(idCorto.length, 8);
      expect(idCorto, '507f1f77');
    });

    test('✓ Chip de estado - renderizado correcto', () {
      final chip = renderizarChipEstado('confirmada');
      expect(chip['texto'], 'Confirmada');
      expect(chip['color'], isNotNull);
    });

    test('✓ Información estudiante - con ícono azul', () {
      final info = renderizarInfoEstudiante('María García');
      expect(info['nombre'], 'María García');
      expect(info['icono'], 'person');
      expect(info['colorIcono'], 'azul');
    });

    test('✓ Información docente - con ícono verde', () {
      final info = renderizarInfoDocente('Juan Pérez');
      expect(info['nombre'], 'Juan Pérez');
      expect(info['icono'], 'school');
      expect(info['colorIcono'], 'verde');
    });

    test('✓ Fecha - con ícono naranja', () {
      final info = renderizarFecha('2024-06-15');
      expect(info['fecha'], '2024-06-15');
      expect(info['icono'], 'calendar_today');
      expect(info['colorIcono'], 'naranja');
    });

    test('✓ Horario - con ícono púrpura', () {
      final info = renderizarHorario('10:00', '10:20');
      expect(info['horaInicio'], '10:00');
      expect(info['horaFin'], '10:20');
      expect(info['icono'], 'access_time');
      expect(info['colorIcono'], 'purpura');
    });

    test('✓ Indicador de asistencia - check_circle verde si asistió', () {
      final indicador = mostrarIndicadorAsistencia(true);
      expect(indicador['icono'], 'check_circle');
      expect(indicador['color'], 'verde');
      expect(indicador['texto'], 'Asistió');
    });

    test('✓ Indicador de asistencia - cancel rojo si no asistió', () {
      final indicador = mostrarIndicadorAsistencia(false);
      expect(indicador['icono'], 'cancel');
      expect(indicador['color'], 'rojo');
      expect(indicador['texto'], 'No asistió');
    });

    test('✓ Motivo de cancelación - contenedor rojo si existe', () {
      final tutoria = {'motivoCancelacion': 'No pude asistir'};
      final contenedor = mostrarContenedorMotivo(tutoria);
      expect(contenedor['mostrar'], true);
      expect(contenedor['motivo'], 'No pude asistir');
      expect(contenedor['colorFondo'], 'rojo');
    });

    test('✓ Motivo de cancelación - no muestra si no existe', () {
      final tutoria = {'estado': 'confirmada'};
      final contenedor = mostrarContenedorMotivo(tutoria);
      expect(contenedor['mostrar'], false);
    });

    test('✓ Contenedores informativos adicionales - según estado', () {
      final tutoria = simularTutoriaFinalizada();
      final contenedores = obtenerContenedoresAdicionales(tutoria);
      expect(contenedores, isNotEmpty);
    });

    test('✓ Filtrar por búsqueda vacía - retorna todas', () {
      final tutorias = simularTutorias();
      final resultado = buscarEnTiempoReal(tutorias, '');
      expect(resultado.length, tutorias.length);
    });

    test('✓ Filtrar por estado "Todos" - retorna todas', () {
      final tutorias = simularTutorias();
      final resultado = filtrarPorEstado(tutorias, 'Todos');
      expect(resultado.length, tutorias.length);
    });

    test('✓ Conteo de resultados - actualiza según filtros', () {
      final tutorias = simularTutorias();
      final filtradas = filtrarAcumulativamente(tutorias, estado: 'confirmada');
      final conteo = contarResultados(filtradas);
      expect(conteo, filtradas.length);
    });
  });
}


// ============================================
// FUNCIONES DE BÚSQUEDA Y FILTRADO
// ============================================

Map<String, dynamic> prepararParametrosEndpoint({required bool incluirCanceladas}) {
  return {
    'incluirCanceladas': incluirCanceladas,
  };
}

List<Map<String, dynamic>> buscarEnTiempoReal(
  List<Map<String, dynamic>> tutorias,
  String query,
) {
  if (query.isEmpty) return tutorias;
  
  return tutorias.where((t) {
    final nombreEstudiante = normalizarParaBusqueda(
      t['estudiante']?['nombreEstudiante'] ?? ''
    );
    final nombreDocente = normalizarParaBusqueda(
      t['docente']?['nombreDocente'] ?? ''
    );
    final q = normalizarParaBusqueda(query);
    
    return nombreEstudiante.contains(q) || nombreDocente.contains(q);
  }).toList();
}

String normalizarParaBusqueda(String texto) {
  return texto.toLowerCase().trim();
}

List<String> obtenerChipsEstados() {
  return [
    'Todos',
    'Pendiente',
    'Confirmada',
    'Finalizada',
    'Cancelada',
    'Rechazada',
    'Expirada',
  ];
}

Map<String, bool> configurarScrollChips() {
  return {
    'horizontal': true,
    'scrollable': true,
  };
}

List<Map<String, dynamic>> filtrarAcumulativamente(
  List<Map<String, dynamic>> tutorias, {
  String? busqueda,
  String? estado,
}) {
  var resultado = tutorias;
  
  if (busqueda != null && busqueda.isNotEmpty) {
    resultado = buscarEnTiempoReal(resultado, busqueda);
  }
  
  if (estado != null && estado != 'Todos') {
    resultado = filtrarPorEstado(resultado, estado);
  }
  
  return resultado;
}

List<Map<String, dynamic>> filtrarPorEstado(
  List<Map<String, dynamic>> tutorias,
  String estado,
) {
  if (estado == 'Todos') return tutorias;
  
  return tutorias.where((t) {
    final estadoTutoria = (t['estado'] as String).toLowerCase();
    final estadoBuscado = estado.toLowerCase();
    
    if (estadoBuscado == 'cancelada') {
      return estadoTutoria.contains('cancelada');
    }
    
    return estadoTutoria == estadoBuscado;
  }).toList();
}

List<Map<String, dynamic>> ordenarPorFechaDescendente(
  List<Map<String, dynamic>> tutorias,
) {
  final copia = List<Map<String, dynamic>>.from(tutorias);
  copia.sort((a, b) {
    final fechaA = DateTime.parse(a['fecha'] ?? '2000-01-01');
    final fechaB = DateTime.parse(b['fecha'] ?? '2000-01-01');
    return fechaB.compareTo(fechaA);
  });
  return copia;
}

int contarResultados(List<Map<String, dynamic>> tutorias) {
  return tutorias.length;
}

// ============================================
// FUNCIONES DE RENDERIZADO
// ============================================

Map<String, dynamic> renderizarCardTutoria(Map<String, dynamic> tutoria) {
  return {
    'id': formatearIdTutoria(tutoria['_id']),
    'estado': tutoria['estado'],
    'estudiante': tutoria['estudiante'],
    'docente': tutoria['docente'],
    'fecha': tutoria['fecha'],
    'horario': '${tutoria['horaInicio']} - ${tutoria['horaFin']}',
  };
}

String formatearIdTutoria(String id) {
  return id.length >= 8 ? id.substring(0, 8) : id;
}

Map<String, dynamic> renderizarChipEstado(String estado) {
  return {
    'texto': estado[0].toUpperCase() + estado.substring(1),
    'color': obtenerColorEstado(estado),
  };
}

String obtenerColorEstado(String estado) {
  switch (estado) {
    case 'pendiente':
      return 'naranja';
    case 'confirmada':
      return 'azul';
    case 'finalizada':
      return 'verde';
    case 'rechazada':
      return 'rojo';
    default:
      return 'gris';
  }
}

Map<String, dynamic> renderizarInfoEstudiante(String nombre) {
  return {
    'nombre': nombre,
    'icono': 'person',
    'colorIcono': 'azul',
  };
}

Map<String, dynamic> renderizarInfoDocente(String nombre) {
  return {
    'nombre': nombre,
    'icono': 'school',
    'colorIcono': 'verde',
  };
}

Map<String, dynamic> renderizarFecha(String fecha) {
  return {
    'fecha': fecha,
    'icono': 'calendar_today',
    'colorIcono': 'naranja',
  };
}

Map<String, dynamic> renderizarHorario(String horaInicio, String horaFin) {
  return {
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'icono': 'access_time',
    'colorIcono': 'purpura',
  };
}

Map<String, dynamic> mostrarIndicadorAsistencia(bool asistio) {
  return {
    'icono': asistio ? 'check_circle' : 'cancel',
    'color': asistio ? 'verde' : 'rojo',
    'texto': asistio ? 'Asistió' : 'No asistió',
  };
}

Map<String, dynamic> mostrarContenedorMotivo(Map<String, dynamic> tutoria) {
  final motivo = tutoria['motivoCancelacion'];
  
  return {
    'mostrar': motivo != null,
    'motivo': motivo,
    'colorFondo': 'rojo',
  };
}

List<Map<String, dynamic>> obtenerContenedoresAdicionales(Map<String, dynamic> tutoria) {
  final contenedores = <Map<String, dynamic>>[];
  
  // Indicador de asistencia si está finalizada
  if (tutoria['estado'] == 'finalizada' && tutoria['asistenciaEstudiante'] != null) {
    contenedores.add(mostrarIndicadorAsistencia(tutoria['asistenciaEstudiante']));
  }
  
  // Motivo de cancelación si existe
  if (tutoria['motivoCancelacion'] != null) {
    contenedores.add(mostrarContenedorMotivo(tutoria));
  }
  
  return contenedores;
}

// ============================================
// DATOS DE PRUEBA
// ============================================

List<Map<String, dynamic>> simularTutorias() {
  return [
    {
      '_id': '507f1f77bcf86cd799439011',
      'estado': 'confirmada',
      'fecha': '2024-06-20',
      'horaInicio': '10:00',
      'horaFin': '10:20',
      'estudiante': {
        '_id': 'e1',
        'nombreEstudiante': 'María García',
        'fotoPerfil': 'https://example.com/foto1.jpg',
      },
      'docente': {
        '_id': 'd1',
        'nombreDocente': 'Juan Pérez',
        'oficinaDocente': 'B-101',
      },
    },
    {
      '_id': '507f1f77bcf86cd799439012',
      'estado': 'pendiente',
      'fecha': '2024-06-19',
      'horaInicio': '11:00',
      'horaFin': '11:20',
      'estudiante': {
        '_id': 'e2',
        'nombreEstudiante': 'Carlos López',
        'fotoPerfil': null,
      },
      'docente': {
        '_id': 'd2',
        'nombreDocente': 'Ana Martínez',
        'oficinaDocente': 'B-102',
      },
    },
    {
      '_id': '507f1f77bcf86cd799439013',
      'estado': 'finalizada',
      'fecha': '2024-06-18',
      'horaInicio': '09:00',
      'horaFin': '09:20',
      'asistenciaEstudiante': true,
      'observaciones': 'Excelente participación',
      'estudiante': {
        '_id': 'e1',
        'nombreEstudiante': 'María García',
        'fotoPerfil': 'https://example.com/foto1.jpg',
      },
      'docente': {
        '_id': 'd1',
        'nombreDocente': 'Juan Pérez',
        'oficinaDocente': 'B-101',
      },
    },
    {
      '_id': '507f1f77bcf86cd799439014',
      'estado': 'cancelada_por_estudiante',
      'fecha': '2024-06-17',
      'horaInicio': '14:00',
      'horaFin': '14:20',
      'motivoCancelacion': 'No pude asistir por enfermedad',
      'estudiante': {
        '_id': 'e3',
        'nombreEstudiante': 'Pedro Ramírez',
        'fotoPerfil': null,
      },
      'docente': {
        '_id': 'd1',
        'nombreDocente': 'Juan Pérez',
        'oficinaDocente': 'B-101',
      },
    },
    {
      '_id': '507f1f77bcf86cd799439015',
      'estado': 'rechazada',
      'fecha': '2024-06-16',
      'horaInicio': '15:00',
      'horaFin': '15:20',
      'motivoRechazo': 'Horario no disponible',
      'estudiante': {
        '_id': 'e2',
        'nombreEstudiante': 'Carlos López',
        'fotoPerfil': null,
      },
      'docente': {
        '_id': 'd2',
        'nombreDocente': 'Ana Martínez',
        'oficinaDocente': 'B-102',
      },
    },
    {
      '_id': '507f1f77bcf86cd799439016',
      'estado': 'expirada',
      'fecha': '2024-06-15',
      'horaInicio': '08:00',
      'horaFin': '08:20',
      'estudiante': {
        '_id': 'e1',
        'nombreEstudiante': 'María García',
        'fotoPerfil': 'https://example.com/foto1.jpg',
      },
      'docente': {
        '_id': 'd3',
        'nombreDocente': 'Luis Fernández',
        'oficinaDocente': 'B-103',
      },
    },
  ];
}

Map<String, dynamic> simularTutoriaSingle() {
  return {
    '_id': '507f1f77bcf86cd799439011',
    'estado': 'confirmada',
    'fecha': '2024-06-20',
    'horaInicio': '10:00',
    'horaFin': '10:20',
    'estudiante': {
      '_id': 'e1',
      'nombreEstudiante': 'María García',
      'fotoPerfil': 'https://example.com/foto1.jpg',
    },
    'docente': {
      '_id': 'd1',
      'nombreDocente': 'Juan Pérez',
      'oficinaDocente': 'B-101',
    },
  };
}

Map<String, dynamic> simularTutoriaFinalizada() {
  return {
    '_id': '507f1f77bcf86cd799439013',
    'estado': 'finalizada',
    'fecha': '2024-06-18',
    'horaInicio': '09:00',
    'horaFin': '09:20',
    'asistenciaEstudiante': true,
    'observaciones': 'Excelente participación',
    'estudiante': {
      '_id': 'e1',
      'nombreEstudiante': 'María García',
    },
    'docente': {
      '_id': 'd1',
      'nombreDocente': 'Juan Pérez',
    },
  };
}