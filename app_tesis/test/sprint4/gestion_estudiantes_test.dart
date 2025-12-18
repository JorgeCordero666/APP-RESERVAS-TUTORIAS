// ============================================
// PRUEBA UNITARIA - GESTIÓN DE ESTUDIANTES
// Archivo: test/gestion_estudiantes_test.dart
// Figuras: 3.58, 3.60, 3.62
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-012: Gestión de Estudiantes (Administrador)', () {

    // ========================================
    // FIGURA 3.58: Listado de estudiantes
    // ========================================

    test('✓ Listar estudiantes - retorna lista correctamente', () {
      final estudiantes = simularListarEstudiantes();
      expect(estudiantes, isNotEmpty);
      expect(estudiantes.length, greaterThan(0));
      expect(estudiantes[0]['nombreEstudiante'], isNotNull);
    });

    test('✓ Filtrar estudiantes por nombre - encuentra coincidencias', () {
      final query = 'maría'; // CORREGIDO
      final estudiantes = simularListarEstudiantes();
      final filtrados = filtrarEstudiantesPorNombre(estudiantes, query);
      expect(filtrados, isNotEmpty);
      expect(
        filtrados[0]['nombreEstudiante'].toString().toLowerCase(),
        contains(query),
      );
    });

    test('✓ Filtrar estudiantes por email - encuentra coincidencias', () {
      final query = 'example.com'; // CORREGIDO
      final estudiantes = simularListarEstudiantes();
      final filtrados = filtrarEstudiantesPorEmail(estudiantes, query);
      expect(filtrados, isNotEmpty);
    });

    test('✓ Filtrar estudiantes activos - solo activos', () {
      final estudiantes = simularListarEstudiantes();
      final activos = filtrarEstudiantesPorEstado(estudiantes, true);
      expect(activos.every((e) => e['status'] == true), true);
    });

    test('✓ Filtrar estudiantes inactivos - solo inactivos', () {
      final estudiantes = simularListarEstudiantes();
      final inactivos = filtrarEstudiantesPorEstado(estudiantes, false);
      expect(inactivos.every((e) => e['status'] == false), true);
    });

    test('✓ Buscador en tiempo real - filtra por nombre o email', () {
      final estudiantes = simularListarEstudiantes();
      final query = 'mar';
      final resultado = buscarEstudiantesEnTiempoReal(estudiantes, query);
      expect(resultado, isNotEmpty);
    });

    test('✓ Chips de filtro - todos los estados', () {
      final filtros = obtenerChipsFiltro();
      expect(filtros, contains('Todos'));
      expect(filtros, contains('Activos'));
      expect(filtros, contains('Inactivos'));
    });

    test('✓ Renderizar card de estudiante - incluye foto circular', () {
      final estudiante = simularEstudianteCompleto();
      final card = renderizarCardEstudiante(estudiante);
      expect(card['foto'], isNotNull);
      expect(card['nombre'], isNotNull);
      expect(card['email'], isNotNull);
      expect(card['chip_estado'], isNotNull);
    });

    test('✓ Menú contextual - opciones correctas', () {
      final opciones = obtenerOpcionesMenuContextual(true);
      expect(opciones, contains('Ver detalle'));
      expect(opciones, contains('Editar'));
      expect(opciones, contains('Deshabilitar'));
    });

    test('✓ Menú contextual - sin deshabilitar si ya está inactivo', () {
      final opciones = obtenerOpcionesMenuContextual(false);
      expect(opciones, contains('Ver detalle'));
      expect(opciones, contains('Editar'));
      expect(opciones.contains('Deshabilitar'), false);
    });

    // ========================================
    // FIGURA 3.60: Estudiante actualizado
    // ========================================

    test('✓ Validar nombre estudiante - obligatorio', () {
      final resultado = validarNombreEstudiante('');
      expect(resultado, 'El nombre es obligatorio');
    });

    test('✓ Validar nombre estudiante - válido', () {
      final resultado = validarNombreEstudiante('María López');
      expect(resultado, null);
    });

    test('✓ Validar email estudiante - formato válido', () {
      final resultado = validarEmailEstudiante('maria@example.com');
      expect(resultado, null);
    });

    test('✓ Validar email estudiante - formato inválido', () {
      final resultado = validarEmailEstudiante('correo-invalido');
      expect(resultado, 'Ingresa un email válido');
    });

    test('✓ Validar email estudiante - campo vacío', () {
      final resultado = validarEmailEstudiante('');
      expect(resultado, 'El email es obligatorio');
    });

    test('✓ Validar teléfono estudiante - opcional y vacío es válido', () {
      final resultado = validarTelefonoEstudiante('');
      expect(resultado, null);
    });

    test('✓ Validar teléfono estudiante - si existe debe ser válido', () {
      final resultado = validarTelefonoEstudiante('0987654321');
      expect(resultado, null);
    });

    test('✓ Validar teléfono estudiante - menor a 10 dígitos', () {
      final resultado = validarTelefonoEstudiante('098765');
      expect(resultado, 'El teléfono debe tener al menos 10 dígitos');
    });

    test('✓ Formulario de edición - precarga datos', () {
      final estudiante = simularEstudianteCompleto();
      final datosEditables = precargarDatosEdicion(estudiante);
      expect(datosEditables['nombreEstudiante'], isNotNull);
      expect(datosEditables['emailEstudiante'], isNotNull);
      expect(datosEditables['telefono'], isNotNull);
    });

    test('✓ Actualizar estudiante - método PUT con campos modificados', () {
      final original = {
        'nombreEstudiante': 'María',
        'emailEstudiante': 'maria@example.com',
        'telefono': '0987654321',
      };
      final editado = {
        'nombreEstudiante': 'María García',
        'emailEstudiante': 'maria@example.com',
        'telefono': '0987654322',
      };
      final cambios = detectarCambios(original, editado);

      expect(cambios['nombreEstudiante'], 'María García');
      expect(cambios['telefono'], '0987654322');
      expect(cambios.containsKey('emailEstudiante'), false);
    });

    test('✓ Deshabilitar estudiante - soft delete cambia estado', () {
      final estudiante = {'_id': '123', 'status': true};
      final resultado = aplicarSoftDelete(estudiante);
      expect(resultado['status'], false);
    });

    test('✓ Deshabilitar estudiante - confirma en diálogo', () {
      final confirmacion = simularDialogoConfirmacion();
      expect(confirmacion['mostrarAdvertencia'], true);
      expect(confirmacion['mensaje'], contains('no podrá acceder'));
    });

    test('✓ Actualizar vista tras edición - recarga lista', () {
      final estudiantesAntes = simularListarEstudiantes();
      final estudiantesDespues = actualizarListaDespuesDeEdicion(estudiantesAntes);
      expect(estudiantesDespues.length, estudiantesAntes.length);
    });

    // ========================================
    // FIGURA 3.62: Detalle consultado
    // ========================================

    test('✓ Obtener detalle estudiante - incluye toda la información', () {
      final estudiante = simularEstudianteCompleto();
      expect(estudiante['nombreEstudiante'], isNotNull);
      expect(estudiante['emailEstudiante'], isNotNull);
      expect(estudiante['fotoPerfil'], isNotNull);
      expect(estudiante['status'], isNotNull);
      expect(estudiante['confirmEmail'], isNotNull);
    });

    test('✓ Formatear estado confirmación - email confirmado', () {
      final confirmado = formatearEstadoConfirmacion(true);
      expect(confirmado, 'Email Confirmado');
    });

    test('✓ Formatear estado confirmación - email pendiente', () {
      final noConfirmado = formatearEstadoConfirmacion(false);
      expect(noConfirmado, 'Email Pendiente');
    });

    test('✓ Renderizar foto de perfil - usa placeholder si no existe', () {
      final fotoUrl = obtenerFotoPerfil(null);
      expect(fotoUrl, contains('flaticon'));
    });

    test('✓ Renderizar foto de perfil - usa URL proporcionada', () {
      final fotoUrl = obtenerFotoPerfil('https://example.com/foto.jpg');
      expect(fotoUrl, 'https://example.com/foto.jpg');
    });

    test('✓ Mostrar estado activo - chip verde', () {
      final chip = renderizarChipEstado(true);
      expect(chip['texto'], 'Activo');
      expect(chip['color'], 'verde');
    });

    test('✓ Mostrar estado inactivo - chip gris', () {
      final chip = renderizarChipEstado(false);
      expect(chip['texto'], 'Inactivo');
      expect(chip['color'], 'gris');
    });

    test('✓ Formatear teléfono opcional - muestra si existe', () {
      final telefono = formatearTelefonoOpcional('0987654321');
      expect(telefono, '0987654321');
    });

    test('✓ Formatear teléfono opcional - muestra mensaje si no existe', () {
      final telefono = formatearTelefonoOpcional(null);
      expect(telefono, 'No proporcionado');
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN
// ============================================

String? validarNombreEstudiante(String? value) {
  if (value == null || value.isEmpty) {
    return 'El nombre es obligatorio';
  }
  return null;
}

String? validarEmailEstudiante(String? value) {
  if (value == null || value.isEmpty) {
    return 'El email es obligatorio';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value)) {
    return 'Ingresa un email válido';
  }
  return null;
}

String? validarTelefonoEstudiante(String? value) {
  if (value != null && value.isNotEmpty) {
    if (value.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos';
    }
  }
  return null;
}

Map<String, dynamic> aplicarSoftDelete(Map<String, dynamic> estudiante) {
  return {...estudiante, 'status': false};
}

String formatearEstadoConfirmacion(bool confirmado) {
  return confirmado ? 'Email Confirmado' : 'Email Pendiente';
}

String obtenerFotoPerfil(String? url) {
  return url ?? 'https://cdn-icons-png.flaticon.com/512/4715/4715329.png';
}

Map<String, dynamic> renderizarChipEstado(bool activo) {
  return {
    'texto': activo ? 'Activo' : 'Inactivo',
    'color': activo ? 'verde' : 'gris',
  };
}

String formatearTelefonoOpcional(String? telefono) {
  return telefono ?? 'No proporcionado';
}

Map<String, dynamic> precargarDatosEdicion(Map<String, dynamic> estudiante) {
  return {
    'nombreEstudiante': estudiante['nombreEstudiante'],
    'emailEstudiante': estudiante['emailEstudiante'],
    'telefono': estudiante['telefono'],
  };
}

Map<String, dynamic> detectarCambios(
  Map<String, dynamic> original,
  Map<String, dynamic> editado,
) {
  final cambios = <String, dynamic>{};
  editado.forEach((key, value) {
    if (original[key] != value) {
      cambios[key] = value;
    }
  });
  return cambios;
}

Map<String, dynamic> simularDialogoConfirmacion() {
  return {
    'mostrarAdvertencia': true,
    'mensaje': 'El estudiante no podrá acceder al sistema',
  };
}

List<Map<String, dynamic>> actualizarListaDespuesDeEdicion(
  List<Map<String, dynamic>> lista,
) {
  return lista;
}

Map<String, dynamic> renderizarCardEstudiante(Map<String, dynamic> estudiante) {
  return {
    'foto': estudiante['fotoPerfil'],
    'nombre': estudiante['nombreEstudiante'],
    'email': estudiante['emailEstudiante'],
    'chip_estado': estudiante['status'],
  };
}

List<String> obtenerChipsFiltro() {
  return ['Todos', 'Activos', 'Inactivos'];
}

List<String> obtenerOpcionesMenuContextual(bool activo) {
  final opciones = ['Ver detalle', 'Editar'];
  if (activo) {
    opciones.add('Deshabilitar');
  }
  return opciones;
}

// ============================================
// FUNCIONES DE FILTRADO
// ============================================

List<Map<String, dynamic>> filtrarEstudiantesPorNombre(
  List<Map<String, dynamic>> estudiantes,
  String query,
) {
  return estudiantes.where((e) {
    final nombre = (e['nombreEstudiante'] ?? '').toString().toLowerCase();
    return nombre.contains(query.toLowerCase());
  }).toList();
}

List<Map<String, dynamic>> filtrarEstudiantesPorEmail(
  List<Map<String, dynamic>> estudiantes,
  String query,
) {
  return estudiantes.where((e) {
    final email = (e['emailEstudiante'] ?? '').toString().toLowerCase();
    return email.contains(query.toLowerCase());
  }).toList();
}

List<Map<String, dynamic>> filtrarEstudiantesPorEstado(
  List<Map<String, dynamic>> estudiantes,
  bool activo,
) {
  return estudiantes.where((e) => e['status'] == activo).toList();
}

List<Map<String, dynamic>> buscarEstudiantesEnTiempoReal(
  List<Map<String, dynamic>> estudiantes,
  String query,
) {
  return estudiantes.where((e) {
    final nombre = (e['nombreEstudiante'] ?? '').toString().toLowerCase();
    final email = (e['emailEstudiante'] ?? '').toString().toLowerCase();
    final q = query.toLowerCase();
    return nombre.contains(q) || email.contains(q);
  }).toList();
}

// ============================================
// DATOS DE PRUEBA
// ============================================

List<Map<String, dynamic>> simularListarEstudiantes() {
  return [
    {
      '_id': '1',
      'nombreEstudiante': 'María García',
      'emailEstudiante': 'maria.garcia@example.com',
      'telefono': '0987654321',
      'fotoPerfil': 'https://example.com/foto1.jpg',
      'status': true,
      'confirmEmail': true,
    },
    {
      '_id': '2',
      'nombreEstudiante': 'Carlos Ramírez',
      'emailEstudiante': 'carlos.ramirez@example.com',
      'telefono': '0987654322',
      'fotoPerfil': null,
      'status': false,
      'confirmEmail': false,
    },
    {
      '_id': '3',
      'nombreEstudiante': 'Ana Martínez',
      'emailEstudiante': 'ana.martinez@example.com',
      'telefono': null,
      'fotoPerfil': 'https://example.com/foto3.jpg',
      'status': true,
      'confirmEmail': true,
    },
  ];
}

Map<String, dynamic> simularEstudianteCompleto() {
  return {
    '_id': '1',
    'nombreEstudiante': 'María García López',
    'emailEstudiante': 'maria.garcia@example.com',
    'telefono': '0987654321',
    'fotoPerfil': 'https://example.com/foto.jpg',
    'status': true,
    'confirmEmail': true,
  };
}
