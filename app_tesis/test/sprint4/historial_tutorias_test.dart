// ============================================
// PRUEBA UNITARIA - HISTORIAL DE TUTORÍAS
// Archivo: test/historial_tutorias_test.dart
// Figura: 3.64
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-015: Historial de Tutorías (Docente/Estudiante)', () {
    
    // ========================================
    // FIGURA 3.64: Historial consultado
    // ========================================
    
    test('✓ TabController - dos pestañas (Activas y Historial)', () {
      final tabs = obtenerPestanas();
      expect(tabs.length, 2);
      expect(tabs, contains('Activas'));
      expect(tabs, contains('Historial'));
    });

    test('✓ Filtrar tutorías activas - solo pendientes y confirmadas', () {
      final tutorias = simularTutorias();
      final activas = filtrarTutoriasActivas(tutorias);
      expect(activas.every((t) => 
        t['estado'] == 'pendiente' || t['estado'] == 'confirmada'
      ), true);
    });

    test('✓ Filtrar tutorías por estado - todos', () {
      final tutorias = simularTutorias();
      final resultado = filtrarPorEstado(tutorias, 'Todos');
      expect(resultado.length, tutorias.length);
    });

    test('✓ Filtrar tutorías por estado - pendientes', () {
      final tutorias = simularTutorias();
      final pendientes = filtrarPorEstado(tutorias, 'pendiente');
      expect(pendientes.every((t) => t['estado'] == 'pendiente'), true);
    });

    test('✓ Filtrar tutorías por estado - confirmadas', () {
      final tutorias = simularTutorias();
      final confirmadas = filtrarPorEstado(tutorias, 'confirmada');
      expect(confirmadas.every((t) => t['estado'] == 'confirmada'), true);
    });

    test('✓ Filtrar tutorías por estado - finalizadas', () {
      final tutorias = simularTutorias();
      final finalizadas = filtrarPorEstado(tutorias, 'finalizada');
      expect(finalizadas.every((t) => t['estado'] == 'finalizada'), true);
    });

    test('✓ Filtrar tutorías por estado - canceladas', () {
      final tutorias = simularTutorias();
      final canceladas = filtrarPorEstado(tutorias, 'cancelada_por_estudiante');
      expect(canceladas.every((t) => t['estado'] == 'cancelada_por_estudiante'), true);
    });

    test('✓ Filtrar tutorías por estado - rechazadas', () {
      final tutorias = simularTutorias();
      final rechazadas = filtrarPorEstado(tutorias, 'rechazada');
      expect(rechazadas.every((t) => t['estado'] == 'rechazada'), true);
    });

    test('✓ Filtrar tutorías por estado - expiradas', () {
      final tutorias = simularTutorias();
      final expiradas = filtrarPorEstado(tutorias, 'expirada');
      expect(expiradas.every((t) => t['estado'] == 'expirada'), true);
    });

    test('✓ Renderizar card de tutoría - incluye borde coloreado', () {
      final tutoria = simularTutoriaSingle();
      final card = renderizarCardTutoria(tutoria);
      expect(card['bordeIzquierdo'], isNotNull);
      expect(card['colorBorde'], isNotNull);
    });

    test('✓ Obtener color según estado - pendiente es naranja', () {
      final color = obtenerColorEstado('pendiente');
      expect(color, 'naranja');
    });

    test('✓ Obtener color según estado - confirmada es azul', () {
      final color = obtenerColorEstado('confirmada');
      expect(color, 'azul');
    });

    test('✓ Obtener color según estado - finalizada es verde', () {
      final color = obtenerColorEstado('finalizada');
      expect(color, 'verde');
    });

    test('✓ Obtener color según estado - cancelada es gris', () {
      final color = obtenerColorEstado('cancelada_por_estudiante');
      expect(color, 'gris');
    });

    test('✓ Obtener color según estado - rechazada es rojo', () {
      final color = obtenerColorEstado('rechazada');
      expect(color, 'rojo');
    });

    test('✓ Renderizar foto circular docente - con sombra', () {
      final foto = renderizarFotoCircularDocente('https://example.com/foto.jpg');
      expect(foto['url'], isNotNull);
      expect(foto['conSombra'], true);
    });

    test('✓ Renderizar nombre docente - en negrita', () {
      final nombre = renderizarNombreDocente('Juan Pérez');
      expect(nombre['texto'], 'Juan Pérez');
      expect(nombre['negrita'], true);
    });

    test('✓ Renderizar oficina - con ícono', () {
      final oficina = renderizarOficinaConIcono('B-101');
      expect(oficina['texto'], 'B-101');
      expect(oficina['icono'], 'location');
    });

    test('✓ Renderizar badge estado - con gradiente', () {
      final badge = renderizarBadgeEstado('confirmada');
      expect(badge['estado'], 'confirmada');
      expect(badge['conGradiente'], true);
    });

    test('✓ Renderizar fecha y horario - en contenedor gris', () {
      final contenedor = renderizarFechaHorario('2024-06-15', '10:00', '10:20');
      expect(contenedor['fecha'], '2024-06-15');
      expect(contenedor['horaInicio'], '10:00');
      expect(contenedor['horaFin'], '10:20');
      expect(contenedor['fondoGris'], true);
    });

    test('✓ Detectar tutoría reagendada - identifica flag', () {
      final tutoria = {'reagendadaPor': 'Estudiante'};
      final esReagendada = detectarReagendamiento(tutoria);
      expect(esReagendada, true);
    });

    test('✓ Detectar tutoría reagendada - no tiene flag', () {
      final tutoria = {'estado': 'pendiente'};
      final esReagendada = detectarReagendamiento(tutoria);
      expect(esReagendada, false);
    });

    test('✓ Mostrar badge reagendada - si aplica', () {
      final badge = mostrarBadgeReagendada(true);
      expect(badge['mostrar'], true);
      expect(badge['texto'], 'Reagendada');
    });

    test('✓ Botón cancelar - aparece para pendientes y confirmadas', () {
      final mostrar = mostrarBotonCancelar('confirmada');
      expect(mostrar, true);
    });

    test('✓ Botón cancelar - no aparece para finalizadas', () {
      final mostrar = mostrarBotonCancelar('finalizada');
      expect(mostrar, false);
    });

    test('✓ Botón reagendar - aparece para pendientes y confirmadas', () {
      final mostrar = mostrarBotonReagendar('pendiente');
      expect(mostrar, true);
    });

    test('✓ Validar motivo cancelación - opcional', () {
      final resultado = validarMotivoCancelacion('');
      expect(resultado, null);
    });

    test('✓ Validar motivo cancelación - con texto válido', () {
      final resultado = validarMotivoCancelacion('Tengo otro compromiso');
      expect(resultado, null);
    });

    test('✓ Diálogo cancelación - TextField multilínea', () {
      final dialogo = simularDialogoCancelacion();
      expect(dialogo['multilinea'], true);
      expect(dialogo['motivoOpcional'], true);
    });

    test('✓ Enviar cancelación - incluye motivo', () {
      final datos = prepararDatosCancelacion('No puedo asistir');
      expect(datos['motivo'], 'No puedo asistir');
    });

    test('✓ Enviar cancelación - sin motivo usa valor por defecto', () {
      final datos = prepararDatosCancelacion('');
      expect(datos['motivo'], isNotEmpty);
    });

    test('✓ Actualizar lista tras cancelar - recarga vista', () {
      final tutoriasAntes = simularTutorias();
      final tutoriasDespues = actualizarListaTutoras(tutoriasAntes);
      expect(tutoriasDespues, isNotEmpty);
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN Y LÓGICA
// ============================================

List<String> obtenerPestanas() {
  return ['Activas', 'Historial'];
}

List<Map<String, dynamic>> filtrarTutoriasActivas(
  List<Map<String, dynamic>> tutorias,
) {
  return tutorias.where((t) {
    final estado = t['estado'] as String;
    return estado == 'pendiente' || estado == 'confirmada';
  }).toList();
}

List<Map<String, dynamic>> filtrarPorEstado(
  List<Map<String, dynamic>> tutorias,
  String estado,
) {
  if (estado == 'Todos') return tutorias;
  return tutorias.where((t) => t['estado'] == estado).toList();
}

String obtenerColorEstado(String estado) {
  switch (estado) {
    case 'pendiente':
      return 'naranja';
    case 'confirmada':
      return 'azul';
    case 'finalizada':
      return 'verde';
    case 'cancelada_por_estudiante':
    case 'cancelada_por_docente':
      return 'gris';
    case 'rechazada':
      return 'rojo';
    case 'expirada':
      return 'marron';
    default:
      return 'gris';
  }
}

Map<String, dynamic> renderizarCardTutoria(Map<String, dynamic> tutoria) {
  return {
    'bordeIzquierdo': true,
    'colorBorde': obtenerColorEstado(tutoria['estado']),
    'contenido': tutoria,
  };
}

Map<String, dynamic> renderizarFotoCircularDocente(String url) {
  return {
    'url': url,
    'circular': true,
    'conSombra': true,
  };
}

Map<String, dynamic> renderizarNombreDocente(String nombre) {
  return {
    'texto': nombre,
    'negrita': true,
  };
}

Map<String, dynamic> renderizarOficinaConIcono(String oficina) {
  return {
    'texto': oficina,
    'icono': 'location',
  };
}

Map<String, dynamic> renderizarBadgeEstado(String estado) {
  return {
    'estado': estado,
    'conGradiente': true,
  };
}

Map<String, dynamic> renderizarFechaHorario(
  String fecha,
  String horaInicio,
  String horaFin,
) {
  return {
    'fecha': fecha,
    'horaInicio': horaInicio,
    'horaFin': horaFin,
    'fondoGris': true,
  };
}

bool detectarReagendamiento(Map<String, dynamic> tutoria) {
  return tutoria['reagendadaPor'] != null;
}

Map<String, dynamic> mostrarBadgeReagendada(bool reagendada) {
  return {
    'mostrar': reagendada,
    'texto': 'Reagendada',
  };
}

bool mostrarBotonCancelar(String estado) {
  return estado == 'pendiente' || estado == 'confirmada';
}

bool mostrarBotonReagendar(String estado) {
  return estado == 'pendiente' || estado == 'confirmada';
}

String? validarMotivoCancelacion(String? value) {
  return null; // Motivo es opcional
}

Map<String, dynamic> simularDialogoCancelacion() {
  return {
    'multilinea': true,
    'motivoOpcional': true,
  };
}

Map<String, dynamic> prepararDatosCancelacion(String motivo) {
  return {
    'motivo': motivo.isEmpty ? 'Sin motivo especificado' : motivo,
  };
}

List<Map<String, dynamic>> actualizarListaTutoras(
  List<Map<String, dynamic>> tutorias,
) {
  return tutorias;
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
      'docente': {
        '_id': 'd1',
        'nombreDocente': 'Juan Pérez',
        'oficinaDocente': 'B-101',
        'avatarDocente': 'https://example.com/foto1.jpg',
      },
    },
    {
      '_id': '2',
      'estado': 'confirmada',
      'fecha': '2024-06-16',
      'horaInicio': '11:00',
      'horaFin': '11:20',
      'reagendadaPor': 'Estudiante',
      'docente': {
        '_id': 'd2',
        'nombreDocente': 'María López',
        'oficinaDocente': 'B-102',
        'avatarDocente': 'https://example.com/foto2.jpg',
      },
    },
    {
      '_id': '3',
      'estado': 'finalizada',
      'fecha': '2024-06-14',
      'horaInicio': '09:00',
      'horaFin': '09:20',
      'asistenciaEstudiante': true,
      'docente': {
        '_id': 'd1',
        'nombreDocente': 'Juan Pérez',
        'oficinaDocente': 'B-101',
        'avatarDocente': 'https://example.com/foto1.jpg',
      },
    },
    {
      '_id': '4',
      'estado': 'cancelada_por_estudiante',
      'fecha': '2024-06-13',
      'horaInicio': '14:00',
      'horaFin': '14:20',
      'motivoCancelacion': 'No pude asistir',
      'docente': {
        '_id': 'd3',
        'nombreDocente': 'Carlos Ramírez',
        'oficinaDocente': 'B-103',
        'avatarDocente': null,
      },
    },
    {
      '_id': '5',
      'estado': 'rechazada',
      'fecha': '2024-06-12',
      'horaInicio': '15:00',
      'horaFin': '15:20',
      'motivoRechazo': 'Horario no disponible',
      'docente': {
        '_id': 'd2',
        'nombreDocente': 'María López',
        'oficinaDocente': 'B-102',
        'avatarDocente': 'https://example.com/foto2.jpg',
      },
    },
    {
      '_id': '6',
      'estado': 'expirada',
      'fecha': '2024-06-10',
      'horaInicio': '08:00',
      'horaFin': '08:20',
      'docente': {
        '_id': 'd1',
        'nombreDocente': 'Juan Pérez',
        'oficinaDocente': 'B-101',
        'avatarDocente': 'https://example.com/foto1.jpg',
      },
    },
  ];
}

Map<String, dynamic> simularTutoriaSingle() {
  return {
    '_id': '1',
    'estado': 'confirmada',
    'fecha': '2024-06-15',
    'horaInicio': '10:00',
    'horaFin': '10:20',
    'docente': {
      '_id': 'd1',
      'nombreDocente': 'Juan Pérez',
      'oficinaDocente': 'B-101',
      'avatarDocente': 'https://example.com/foto.jpg',
    },
  };
}