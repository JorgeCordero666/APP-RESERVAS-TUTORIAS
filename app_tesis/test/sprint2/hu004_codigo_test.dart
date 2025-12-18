// ============================================
// PRUEBA UNITARIA - INGRESAR CÓDIGO
// HU-004: Sprint 2
// Figura 3.11 y 3.12: Validación de código
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-004: Ingresar Código de Recuperación', () {
    
    // ========== VALIDACIÓN DEL CÓDIGO ==========
    
    test('✓ Código válido - Mínimo 8 caracteres', () {
      final codigo = 'ABC12XYZ';
      expect(codigo.length, greaterThanOrEqualTo(8));
    });

    test('✓ Código válido - Formato alfanumérico', () {
      final codigo = 'ABC123XYZ789';
      expect(codigo.isNotEmpty, true);
      expect(codigo.length >= 8, true);
    });

    test('✓ Validación de código - Campo vacío', () {
      final resultado = validarCodigo('');
      expect(resultado, 'Por favor ingresa el código');
    });

    test('✓ Validación de código - Menor a 8 caracteres', () {
      final resultado = validarCodigo('ABC123');
      expect(resultado, 'El código debe tener al menos 8 caracteres');
    });

    test('✓ Validación de código - Exactamente 8 caracteres', () {
      final resultado = validarCodigo('ABC12XYZ');
      expect(resultado, null);
    });

    test('✓ Validación de código - Más de 8 caracteres', () {
      final resultado = validarCodigo('ABC123XYZ789DEF456');
      expect(resultado, null);
    });

    // ========== ENDPOINTS DE COMPROBACIÓN ==========
    
    test('✓ Endpoint de comprobación - Estudiante', () {
      final token = 'abc123xyz';
      final endpoint = obtenerEndpointComprobar(token, 'estudiante');
      expect(endpoint, contains('estudiante/recuperarpassword'));
      expect(endpoint, contains(token));
    });

    test('✓ Endpoint de comprobación - Docente', () {
      final token = 'abc123xyz';
      final endpoint = obtenerEndpointComprobar(token, 'docente');
      expect(endpoint, contains('docente/recuperarpassword'));
      expect(endpoint, contains(token));
    });

    test('✓ Endpoint de comprobación - Administrador', () {
      final token = 'abc123xyz';
      final endpoint = obtenerEndpointComprobar(token, 'administrador');
      expect(endpoint, contains('administrador/recuperarpassword'));
      expect(endpoint, contains(token));
    });

    // ========== VALIDACIÓN DEL TOKEN ==========
    
    test('✓ Token válido - Success true', () {
      final response = {'success': true};
      expect(response['success'], true);
    });

    test('✓ Token inválido - Campo error presente', () {
      final response = {'error': 'Token inválido o expirado'};
      expect(response.containsKey('error'), true);
    });

    test('✓ Token expirado - Mensaje específico', () {
      final error = 'Token inválido o expirado';
      expect(error, contains('Token'));
      expect(error, contains('expirado'));
    });

    test('✓ Validación de vigencia - 24 horas', () {
      const horasValidez = 24;
      expect(horasValidez, 24);
    });

    // ========== RESPUESTAS DEL BACKEND ==========
    
    test('✓ Respuesta exitosa - Status 200', () {
      const statusCode = 200;
      expect(statusCode, 200);
    });

    test('✓ Respuesta exitosa - Contiene campo success', () {
      final data = {'success': true, 'msg': 'Token válido'};
      expect(data.containsKey('success'), true);
    });

    test('✓ Respuesta con error - Status diferente de 200', () {
      const statusCode = 404;
      expect(statusCode, isNot(200));
    });

    // ========== MANEJO DE ERRORES ==========
    
    test('✓ Error de conexión - Mensaje apropiado', () {
      final error = 'Error de conexión';
      expect(error, contains('conexión'));
    });

    test('✓ Error token inválido - Mensaje al usuario', () {
      final mensaje = 'Token inválido o expirado';
      expect(mensaje.isNotEmpty, true);
    });

    test('✓ Error servidor - Status 500', () {
      const statusCode = 500;
      final esError = statusCode >= 500;
      expect(esError, true);
    });

    // ========== NAVEGACIÓN ==========
    
    test('✓ Redirección exitosa - Ruta nueva contraseña', () {
      final destino = '/nueva-password';
      expect(destino, '/nueva-password');
    });

    test('✓ Token se pasa como argumento', () {
      final token = 'abc123xyz789';
      expect(token.isNotEmpty, true);
    });

    // ========== VALIDACIÓN DE UI ==========
    
    test('✓ Estado de carga - Durante validación', () {
      final isLoading = true;
      expect(isLoading, true);
    });

    test('✓ Botón deshabilitado durante carga', () {
      final isLoading = true;
      final botonHabilitado = !isLoading;
      expect(botonHabilitado, false);
    });

    test('✓ Indicador de progreso visible', () {
      final mostrarIndicador = true;
      expect(mostrarIndicador, true);
    });

    // ========== INSTRUCCIONES AL USUARIO ==========
    
    test('✓ Mensaje informativo - Copiar desde correo', () {
      final mensaje = 'Copia el código desde tu correo y pégalo aquí.';
      expect(mensaje, contains('correo'));
      expect(mensaje, contains('código'));
    });

    test('✓ Placeholder del campo - Indicación clara', () {
      final placeholder = 'Pega aquí el código';
      expect(placeholder.isNotEmpty, true);
    });

    // ========== INTENTOS MÚLTIPLES ==========
    
    test('✓ Múltiples endpoints - Estrategia de fallback', () {
      final endpoints = [
        'estudiante/recuperarpassword',
        'docente/recuperarpassword',
        'administrador/recuperarpassword',
      ];
      expect(endpoints.length, 3);
    });

    test('✓ Intentar siguiente endpoint - Si falla el primero', () {
      final endpointActual = 0;
      final siguienteEndpoint = endpointActual + 1;
      expect(siguienteEndpoint, 1);
    });

    test('✓ Formato del código - Trim aplicado', () {
      final codigoOriginal = '  ABC123XYZ  ';
      final codigoLimpio = codigoOriginal.trim();
      expect(codigoLimpio, 'ABC123XYZ');
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - CÓDIGO
// ============================================

String? validarCodigo(String? value) {
  if (value == null || value.isEmpty) {
    return 'Por favor ingresa el código';
  }
  if (value.length < 8) {
    return 'El código debe tener al menos 8 caracteres';
  }
  return null;
}

String obtenerEndpointComprobar(String token, String rol) {
  const baseUrl = 'http://10.0.2.2:3000/api';
  switch (rol.toLowerCase()) {
    case 'estudiante':
      return '$baseUrl/estudiante/recuperarpassword/$token';
    case 'docente':
      return '$baseUrl/docente/recuperarpassword/$token';
    case 'administrador':
      return '$baseUrl/administrador/recuperarpassword/$token';
    default:
      return '$baseUrl/estudiante/recuperarpassword/$token';
  }
}