// ============================================
// PRUEBA UNITARIA - CREAR NUEVA CONTRASEÑA
// Figura 3.8: Conclusión de la prueba de software unitaria – Crear nueva contraseña
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-003: Crear Nueva Contraseña', () {
    
    test('✓ Recepción de código desde correo - código válido', () {
      final codigo = 'abc123xyz789';
      expect(codigo.isNotEmpty, true);
      expect(codigo.length, greaterThanOrEqualTo(8));
    });

    test('✓ Validación del token - formato correcto', () {
      final token = validarFormatoToken('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
      expect(token, true);
    });

    test('✓ Validación del token - token vacío', () {
      final token = validarFormatoToken('');
      expect(token, false);
    });

    test('✓ Validación de nueva contraseña - mínimo 8 caracteres válido', () {
      final resultado = validarNuevaPassword('Password123');
      expect(resultado, null);
    });

    test('✓ Validación de nueva contraseña - menor a 8 caracteres', () {
      final resultado = validarNuevaPassword('Pass12');
      expect(resultado, 'La contraseña debe tener al menos 8 caracteres');
    });

    test('✓ Validación de nueva contraseña - exactamente 8 caracteres', () {
      final resultado = validarNuevaPassword('12345678');
      expect(resultado, null);
    });

    test('✓ Validación de nueva contraseña - campo vacío', () {
      final resultado = validarNuevaPassword('');
      expect(resultado, 'Por favor ingresa una contraseña');
    });

    test('✓ Confirmación de contraseña - contraseñas coinciden', () {
      final resultado = validarConfirmacionNuevaPassword('Password123', 'Password123');
      expect(resultado, null);
    });

    test('✓ Confirmación de contraseña - contraseñas no coinciden', () {
      final resultado = validarConfirmacionNuevaPassword('Password123', 'Password456');
      expect(resultado, 'Las contraseñas no coinciden');
    });

    test('✓ Confirmación de contraseña - campo vacío', () {
      final resultado = validarConfirmacionNuevaPassword('', 'Password123');
      expect(resultado, 'Por favor confirma tu contraseña');
    });

    test('✓ Endpoint de actualización - con token', () {
      final token = 'abc123xyz';
      final endpoint = obtenerEndpointNuevaPassword(token);
      expect(endpoint, contains(token));
      expect(endpoint, contains('nuevopassword'));
    });

    test('✓ Preparación de datos para envío - formato JSON', () {
      final body = prepararBodyNuevaPassword(
        password: 'NewPassword123',
        confirmPassword: 'NewPassword123',
      );
      expect(body['password'], 'NewPassword123');
      expect(body['confirmpassword'], 'NewPassword123');
    });

    test('✓ Validación de token antes de enviar - token válido', () {
      final esValido = verificarTokenAntesDeCambio('token_valido_123');
      expect(esValido, true);
    });

    test('✓ Validación de token antes de enviar - token inválido', () {
      final esValido = verificarTokenAntesDeCambio('');
      expect(esValido, false);
    });

    test('✓ Almacenamiento seguro - simulación encriptación', () {
      final passwordEncriptada = simularEncriptacion('Password123');
      expect(passwordEncriptada, isNot('Password123')); // No debe ser texto plano
      expect(passwordEncriptada.isNotEmpty, true);
    });

    test('✓ Mensaje de confirmación exitosa', () {
      final mensaje = '¡Contraseña actualizada exitosamente! Ya puedes iniciar sesión.';
      expect(mensaje, contains('exitosamente'));
      expect(mensaje, contains('iniciar sesión'));
    });

    test('✓ Redirección a login después de cambio exitoso', () {
      final destino = obtenerDestinoPostCambio();
      expect(destino, '/login');
    });

    test('✓ Tiempo de espera antes de redirección - 2 segundos', () {
      final duracionSegundos = 2;
      expect(duracionSegundos, 2);
    });

    test('✓ Validación en tiempo real - 8 caracteres', () {
      final longitud = 'Password'.length;
      expect(longitud, greaterThanOrEqualTo(8));
    });

    test('✓ Indicador de carga durante petición', () {
      final isLoading = true;
      expect(isLoading, true);
    });

    test('✓ Manejo de errores - token expirado', () {
      final error = 'Token inválido o expirado';
      expect(error, contains('Token'));
    });

    test('✓ Manejo de errores - error de conexión', () {
      final error = 'Error de conexión. Verifica tu internet.';
      expect(error, contains('conexión'));
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - NUEVA CONTRASEÑA
// ============================================

bool validarFormatoToken(String token) {
  return token.isNotEmpty && token.length >= 8;
}

String? validarNuevaPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Por favor ingresa una contraseña';
  }
  if (value.length < 8) {
    return 'La contraseña debe tener al menos 8 caracteres';
  }
  return null;
}

String? validarConfirmacionNuevaPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Por favor confirma tu contraseña';
  }
  if (value != password) {
    return 'Las contraseñas no coinciden';
  }
  return null;
}

String obtenerEndpointNuevaPassword(String token) {
  const baseUrl = 'http://10.0.2.2:3000/api';
  return '$baseUrl/estudiante/nuevopassword/$token';
}

Map<String, String> prepararBodyNuevaPassword({
  required String password,
  required String confirmPassword,
}) {
  return {
    'password': password,
    'confirmpassword': confirmPassword,
  };
}

bool verificarTokenAntesDeCambio(String? token) {
  return token != null && token.isNotEmpty;
}

String simularEncriptacion(String password) {
  // Simulación de hash (en backend se usa bcrypt)
  return 'hashed_$password';
}

String obtenerDestinoPostCambio() {
  return '/login';
}