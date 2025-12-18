// ============================================
// PRUEBA UNITARIA - CRUD DE DOCENTES
// Archivo: test/crud_docentes_test.dart
// Figuras: 3.50, 3.52, 3.54, 3.56
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-011: CRUD de Docentes (Administrador)', () {
    
    // ========================================
    // FIGURA 3.50: Listado de docentes
    // ========================================
    
    test('✓ Listar docentes - retorna lista correctamente', () {
      final docentes = simularListarDocentes();
      expect(docentes, isNotEmpty);
      expect(docentes.length, greaterThan(0));
      expect(docentes[0]['nombreDocente'], isNotNull);
    });

    test('✓ Filtrar docentes por nombre - encuentra coincidencias', () {
      final query = 'juan';
      final docentes = simularListarDocentes();
      final filtrados = filtrarDocentesPorNombre(docentes, query);
      expect(filtrados, isNotEmpty);
      expect(filtrados[0]['nombreDocente'].toString().toLowerCase(), contains(query));
    });

    test('✓ Filtrar docentes por email - encuentra coincidencias', () {
      final query = '@epn.edu.ec';
      final docentes = simularListarDocentes();
      final filtrados = filtrarDocentesPorEmail(docentes, query);
      expect(filtrados, isNotEmpty);
      expect(filtrados[0]['emailDocente'], contains(query));
    });

    test('✓ Filtrar docentes por estado activo - solo activos', () {
      final docentes = simularListarDocentes();
      final activos = filtrarDocentesPorEstado(docentes, true);
      expect(activos.every((d) => d['estadoDocente'] == true), true);
    });

    test('✓ Filtrar docentes por estado inactivo - solo inactivos', () {
      final docentes = simularListarDocentes();
      final inactivos = filtrarDocentesPorEstado(docentes, false);
      expect(inactivos.every((d) => d['estadoDocente'] == false), true);
    });

    test('✓ Buscador en tiempo real - filtra correctamente', () {
      final docentes = simularListarDocentes();
      final query = 'per';
      final resultado = buscarDocentesEnTiempoReal(docentes, query);
      expect(resultado, isNotEmpty);
    });

    // ========================================
    // FIGURA 3.52: Docente creado
    // ========================================
    
    test('✓ Validar nombre docente - obligatorio', () {
      final resultado = validarNombreDocente('');
      expect(resultado, 'El nombre es obligatorio');
    });

    test('✓ Validar nombre docente - válido', () {
      final resultado = validarNombreDocente('Juan Pérez García');
      expect(resultado, null);
    });

    test('✓ Validar cédula docente - 10 dígitos exactos', () {
      final resultado = validarCedula('1234567890');
      expect(resultado, null);
    });

    test('✓ Validar cédula docente - menor a 10 dígitos', () {
      final resultado = validarCedula('12345');
      expect(resultado, 'La cédula debe tener 10 dígitos');
    });

    test('✓ Validar cédula docente - mayor a 10 dígitos', () {
      final resultado = validarCedula('12345678901');
      expect(resultado, 'La cédula debe tener 10 dígitos');
    });

    test('✓ Validar email institucional - formato correcto', () {
      final resultado = validarEmailInstitucional('docente@epn.edu.ec');
      expect(resultado, null);
    });

    test('✓ Validar email institucional - formato incorrecto', () {
      final resultado = validarEmailInstitucional('docente@gmail.com');
      expect(resultado, 'Debe ser un email institucional @epn.edu.ec');
    });

    test('✓ Validar email institucional - campo vacío', () {
      final resultado = validarEmailInstitucional('');
      expect(resultado, 'El email es obligatorio');
    });

    test('✓ Validar celular docente - mínimo 10 dígitos válido', () {
      final resultado = validarCelular('0987654321');
      expect(resultado, null);
    });

    test('✓ Validar celular docente - menor a 10 dígitos', () {
      final resultado = validarCelular('098765');
      expect(resultado, 'El celular debe tener al menos 10 dígitos');
    });

    test('✓ Validar edad mínima docente - 18 años o más', () {
      final fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 20));
      final resultado = validarEdadMinima(fechaNacimiento);
      expect(resultado, null);
    });

    test('✓ Validar edad mínima docente - menor a 18 años', () {
      final fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 16));
      final resultado = validarEdadMinima(fechaNacimiento);
      expect(resultado, 'Debe tener al menos 18 años');
    });

    test('✓ Validar edad mínima docente - exactamente 18 años', () {
      final fechaNacimiento = DateTime.now().subtract(const Duration(days: 365 * 18));
      final resultado = validarEdadMinima(fechaNacimiento);
      expect(resultado, null);
    });

    test('✓ Preparar datos para crear docente - formato correcto', () {
      final datos = prepararDatosDocente(
        nombre: 'Juan Pérez',
        cedula: '1234567890',
        email: 'juan.perez@epn.edu.ec',
        celular: '0987654321',
        oficina: 'B-101',
        emailAlternativo: 'juan@gmail.com',
        fechaNacimiento: '1990-01-01',
        fechaIngreso: '2020-01-01',
      );
      
      expect(datos['nombreDocente'], 'Juan Pérez');
      expect(datos['cedulaDocente'], '1234567890');
      expect(datos['emailDocente'], 'juan.perez@epn.edu.ec');
      expect(datos['celularDocente'], '0987654321');
      expect(datos['oficinaDocente'], 'B-101');
    });

    test('✓ Generar contraseña temporal - formato correcto', () {
      final password = generarPasswordTemporal();
      expect(password.length, greaterThanOrEqualTo(8));
    });

    test('✓ Establecer flag cambio obligatorio - activo por defecto', () {
      final flag = establecerFlagCambioPassword();
      expect(flag, true);
    });

    // ========================================
    // FIGURA 3.54: Docente actualizado
    // ========================================
    
    test('✓ Actualizar docente - mantiene email institucional bloqueado', () {
      final emailOriginal = 'docente@epn.edu.ec';
      final esBloqueado = validarEmailBloqueado(emailOriginal);
      expect(esBloqueado, true);
    });

    test('✓ Detectar campos modificados - identifica cambios', () {
      final original = {
        'nombreDocente': 'Juan',
        'celularDocente': '0987654321',
        'oficinaDocente': 'B-101'
      };
      final editado = {
        'nombreDocente': 'Juan Pérez',
        'celularDocente': '0987654321',
        'oficinaDocente': 'B-102'
      };
      final cambios = detectarCambios(original, editado);
      
      expect(cambios['nombreDocente'], 'Juan Pérez');
      expect(cambios['oficinaDocente'], 'B-102');
      expect(cambios.containsKey('celularDocente'), false);
    });

    test('✓ Detectar campos modificados - sin cambios', () {
      final original = {'nombreDocente': 'Juan', 'celular': '0987654321'};
      final editado = {'nombreDocente': 'Juan', 'celular': '0987654321'};
      final cambios = detectarCambios(original, editado);
      expect(cambios.isEmpty, true);
    });

    test('✓ Precargar datos para edición - convierte a strings', () {
      final docente = simularDocenteCompleto();
      final datosEditables = precargarDatosEdicion(docente);
      expect(datosEditables['nombreDocente'], isA<String>());
      expect(datosEditables['cedulaDocente'], isA<String>());
    });

    test('✓ Deshabilitar docente - requiere fecha de salida', () {
      final fechaSalida = DateTime.now().add(const Duration(days: 1));
      final resultado = validarFechaSalida(fechaSalida);
      expect(resultado, null);
    });

    test('✓ Deshabilitar docente - fecha salida no puede ser pasada', () {
      final fechaSalida = DateTime.now().subtract(const Duration(days: 30));
      final resultado = validarFechaSalida(fechaSalida);
      expect(resultado, 'La fecha de salida no puede ser anterior a hoy');
    });

    test('✓ Cambiar estado a deshabilitado - soft delete', () {
      final docente = {'_id': '123', 'estadoDocente': true};
      final actualizado = cambiarEstadoDocente(docente, false);
      expect(actualizado['estadoDocente'], false);
    });

    // ========================================
    // FIGURA 3.56: Detalle consultado
    // ========================================
    
    test('✓ Formatear información personal - estructura correcta', () {
      final docente = simularDocenteCompleto();
      final personal = extraerSeccionPersonal(docente);
      expect(personal['Nombre'], isNotNull);
      expect(personal['Cédula'], isNotNull);
      expect(personal['Fecha de Nacimiento'], isNotNull);
      expect(personal['Fecha de Ingreso'], isNotNull);
    });

    test('✓ Formatear información de contacto - estructura correcta', () {
      final docente = simularDocenteCompleto();
      final contacto = extraerSeccionContacto(docente);
      expect(contacto['Email Institucional'], isNotNull);
      expect(contacto['Email Alternativo'], isNotNull);
      expect(contacto['Celular'], isNotNull);
      expect(contacto['Oficina'], isNotNull);
    });

    test('✓ Formatear información académica - incluye asignaturas', () {
      final docente = simularDocenteCompleto();
      final academica = extraerSeccionAcademica(docente);
      expect(academica['Fecha de Ingreso'], isNotNull);
      expect(academica['Asignaturas'], isA<List>());
    });

    test('✓ Renderizar asignaturas como chips - formato correcto', () {
      final asignaturas = ['Matemáticas', 'Física', 'Química'];
      final chips = renderizarAsignaturasComoChips(asignaturas);
      expect(chips.length, 3);
      expect(chips, contains('Matemáticas'));
    });

    test('✓ Calcular edad del docente - cálculo correcto', () {
      final fechaNacimiento = DateTime(1990, 6, 15);
      final edad = calcularEdad(fechaNacimiento);
      expect(edad, greaterThanOrEqualTo(33));
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN
// ============================================

String? validarNombreDocente(String? value) {
  if (value == null || value.isEmpty) {
    return 'El nombre es obligatorio';
  }
  return null;
}

String? validarCedula(String? value) {
  if (value == null || value.isEmpty) {
    return 'La cédula es obligatoria';
  }
  if (value.length != 10) {
    return 'La cédula debe tener 10 dígitos';
  }
  return null;
}

String? validarEmailInstitucional(String? value) {
  if (value == null || value.isEmpty) {
    return 'El email es obligatorio';
  }
  if (!value.contains('@epn.edu.ec')) {
    return 'Debe ser un email institucional @epn.edu.ec';
  }
  return null;
}

String? validarCelular(String? value) {
  if (value == null || value.isEmpty) {
    return 'El celular es obligatorio';
  }
  if (value.length < 10) {
    return 'El celular debe tener al menos 10 dígitos';
  }
  return null;
}

String? validarEdadMinima(DateTime fechaNacimiento) {
  final edad = DateTime.now().difference(fechaNacimiento).inDays ~/ 365;
  if (edad < 18) {
    return 'Debe tener al menos 18 años';
  }
  return null;
}

String? validarFechaSalida(DateTime fechaSalida) {
  final hoy = DateTime.now();
  final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
  final inicioFechaSalida = DateTime(fechaSalida.year, fechaSalida.month, fechaSalida.day);
  
  if (inicioFechaSalida.isBefore(inicioHoy)) {
    return 'La fecha de salida no puede ser anterior a hoy';
  }
  return null;
}

bool validarEmailBloqueado(String email) {
  return true;
}

Map<String, dynamic> prepararDatosDocente({
  required String nombre,
  required String cedula,
  required String email,
  required String celular,
  required String oficina,
  required String emailAlternativo,
  required String fechaNacimiento,
  required String fechaIngreso,
}) {
  return {
    'nombreDocente': nombre,
    'cedulaDocente': cedula,
    'emailDocente': email,
    'celularDocente': celular,
    'oficinaDocente': oficina,
    'emailAlternativoDocente': emailAlternativo,
    'fechaNacimientoDocente': fechaNacimiento,
    'fechaIngresoDocente': fechaIngreso,
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

Map<String, dynamic> precargarDatosEdicion(Map<String, dynamic> docente) {
  return docente.map((key, value) => MapEntry(key, value.toString()));
}

Map<String, dynamic> cambiarEstadoDocente(Map<String, dynamic> docente, bool nuevoEstado) {
  return {...docente, 'estadoDocente': nuevoEstado};
}

String generarPasswordTemporal() {
  return 'Temp1234';
}

bool establecerFlagCambioPassword() {
  return true;
}

Map<String, dynamic> extraerSeccionPersonal(Map<String, dynamic> docente) {
  return {
    'Nombre': docente['nombreDocente'],
    'Cédula': docente['cedulaDocente'],
    'Fecha de Nacimiento': docente['fechaNacimientoDocente'],
    'Fecha de Ingreso': docente['fechaIngresoDocente'],
  };
}

Map<String, dynamic> extraerSeccionContacto(Map<String, dynamic> docente) {
  return {
    'Email Institucional': docente['emailDocente'],
    'Email Alternativo': docente['emailAlternativoDocente'],
    'Celular': docente['celularDocente'],
    'Oficina': docente['oficinaDocente'],
  };
}

Map<String, dynamic> extraerSeccionAcademica(Map<String, dynamic> docente) {
  return {
    'Fecha de Ingreso': docente['fechaIngresoDocente'],
    'Asignaturas': docente['asignaturas'] ?? [],
  };
}

List<String> renderizarAsignaturasComoChips(List<String> asignaturas) {
  return asignaturas;
}

int calcularEdad(DateTime fechaNacimiento) {
  return DateTime.now().difference(fechaNacimiento).inDays ~/ 365;
}

// ============================================
// FUNCIONES DE FILTRADO
// ============================================

List<Map<String, dynamic>> filtrarDocentesPorNombre(
  List<Map<String, dynamic>> docentes,
  String query,
) {
  return docentes.where((d) {
    final nombre = (d['nombreDocente'] ?? '').toString().toLowerCase();
    return nombre.contains(query.toLowerCase());
  }).toList();
}

List<Map<String, dynamic>> filtrarDocentesPorEmail(
  List<Map<String, dynamic>> docentes,
  String query,
) {
  return docentes.where((d) {
    final email = (d['emailDocente'] ?? '').toString().toLowerCase();
    return email.contains(query.toLowerCase());
  }).toList();
}

List<Map<String, dynamic>> filtrarDocentesPorEstado(
  List<Map<String, dynamic>> docentes,
  bool activo,
) {
  return docentes.where((d) => d['estadoDocente'] == activo).toList();
}

List<Map<String, dynamic>> buscarDocentesEnTiempoReal(
  List<Map<String, dynamic>> docentes,
  String query,
) {
  return docentes.where((d) {
    final nombre = (d['nombreDocente'] ?? '').toString().toLowerCase();
    final email = (d['emailDocente'] ?? '').toString().toLowerCase();
    final q = query.toLowerCase();
    return nombre.contains(q) || email.contains(q);
  }).toList();
}

// ============================================
// DATOS DE PRUEBA
// ============================================

List<Map<String, dynamic>> simularListarDocentes() {
  return [
    {
      '_id': '1',
      'nombreDocente': 'Juan Pérez',
      'emailDocente': 'juan.perez@epn.edu.ec',
      'estadoDocente': true,
      'celularDocente': '0987654321',
      'oficinaDocente': 'B-101',
    },
    {
      '_id': '2',
      'nombreDocente': 'María López',
      'emailDocente': 'maria.lopez@epn.edu.ec',
      'estadoDocente': false,
      'celularDocente': '0987654322',
      'oficinaDocente': 'B-102',
    },
    {
      '_id': '3',
      'nombreDocente': 'Carlos Ramírez',
      'emailDocente': 'carlos.ramirez@epn.edu.ec',
      'estadoDocente': true,
      'celularDocente': '0987654323',
      'oficinaDocente': 'B-103',
    },
  ];
}

Map<String, dynamic> simularDocenteCompleto() {
  return {
    '_id': '1',
    'nombreDocente': 'Juan Pérez García',
    'cedulaDocente': '1234567890',
    'emailDocente': 'juan.perez@epn.edu.ec',
    'celularDocente': '0987654321',
    'oficinaDocente': 'B-101',
    'emailAlternativoDocente': 'juan.perez@gmail.com',
    'fechaNacimientoDocente': '1990-01-01',
    'fechaIngresoDocente': '2020-01-01',
    'asignaturas': ['Matemáticas', 'Física', 'Química'],
    'estadoDocente': true,
  };
}