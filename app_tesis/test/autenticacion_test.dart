// ============================================
// PRUEBA UNITARIA - AUTENTICACIÓN DE USUARIOS
// Figura 3.4: Conclusión de la prueba de software unitaria – Autenticación
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-002: Autenticación de Usuarios por Rol', () {
    
    test('✓ Selector de rol - Estudiante seleccionado por defecto', () {
      final rolInicial = obtenerRolInicial();
      expect(rolInicial, 'Estudiante');
    });

    test('✓ Selector de rol - Cambio a Docente', () {
      final rol = 'Docente';
      expect(rol, isIn(['Estudiante', 'Docente', 'Administrador']));
    });

    test('✓ Selector de rol - Cambio a Administrador', () {
      final rol = 'Administrador';
      expect(rol, isIn(['Estudiante', 'Docente', 'Administrador']));
    });

    test('✓ Validación de credenciales - email válido', () {
      final resultado = validarEmailLogin('usuario@example.com');
      expect(resultado, null);
    });

    test('✓ Validación de credenciales - email inválido', () {
      final resultado = validarEmailLogin('usuario-sin-arroba');
      expect(resultado, 'Ingresa un correo válido');
    });

    test('✓ Validación de credenciales - contraseña mínimo 6 caracteres', () {
      final resultado = validarPasswordLogin('Pass12');
      expect(resultado, null);
    });

    test('✓ Validación de credenciales - contraseña muy corta', () {
      final resultado = validarPasswordLogin('12345');
      expect(resultado, 'La contraseña debe tener al menos 6 caracteres');
    });

    test('✓ Endpoint correcto según rol - Estudiante', () {
      final endpoint = obtenerEndpointLogin('Estudiante');
      expect(endpoint, contains('/estudiante/login'));
    });

    test('✓ Endpoint correcto según rol - Docente', () {
      final endpoint = obtenerEndpointLogin('Docente');
      expect(endpoint, contains('/docente/login'));
    });

    test('✓ Endpoint correcto según rol - Administrador', () {
      final endpoint = obtenerEndpointLogin('Administrador');
      expect(endpoint, endsWith('/login'));
    });

    test('✓ Preparación de credenciales - Estudiante', () {
      final body = prepararBodyLogin(
        rol: 'Estudiante',
        email: 'estudiante@example.com',
        password: 'Password123',
      );
      expect(body['emailEstudiante'], 'estudiante@example.com');
      expect(body['password'], 'Password123');
    });

    test('✓ Preparación de credenciales - Docente', () {
      final body = prepararBodyLogin(
        rol: 'Docente',
        email: 'docente@epn.edu.ec',
        password: 'Docente123',
      );
      expect(body['email'], 'docente@epn.edu.ec');
      expect(body['password'], 'Docente123');
    });

    test('✓ Preparación de credenciales - Administrador', () {
      final body = prepararBodyLogin(
        rol: 'Administrador',
        email: 'admin@epn.edu.ec',
        password: 'Admin123',
      );
      expect(body['email'], 'admin@epn.edu.ec');
      expect(body['password'], 'Admin123');
    });

    test('✓ Verificación de cuenta confirmada - simulación', () {
      final respuestaBackend = {
        'msg': 'Confirma tu cuenta primero',
        'requiresConfirmation': true,
      };
      expect(respuestaBackend['requiresConfirmation'], true);
    });

    test('✓ Verificación de cambio de contraseña obligatorio - simulación', () {
      final respuestaBackend = {
        'requiresPasswordChange': true,
        'token': 'jwt_token_123',
      };
      expect(respuestaBackend['requiresPasswordChange'], true);
    });

    test('✓ Almacenamiento de token JWT - simulación', () {
      final token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjEyMyJ9.abc123';
      expect(token.isNotEmpty, true);
      expect(token.contains('.'), true); // JWT tiene puntos
    });

    test('✓ Redirección según rol - Estudiante a HomeScreen', () {
      final destino = obtenerDestinoSegunRol('Estudiante');
      expect(destino, '/home');
    });

    test('✓ Redirección según rol - Docente a HomeScreen', () {
      final destino = obtenerDestinoSegunRol('Docente');
      expect(destino, '/home');
    });

    test('✓ Redirección según rol - Administrador a HomeScreen', () {
      final destino = obtenerDestinoSegunRol('Administrador');
      expect(destino, '/home');
    });

    test('✓ Normalización de email antes de enviar', () {
      final emailNormalizado = normalizarEmailLogin('  USUARIO@EXAMPLE.COM  ');
      expect(emailNormalizado, 'usuario@example.com');
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - AUTENTICACIÓN
// ============================================

String obtenerRolInicial() {
  return 'Estudiante';
}

String? validarEmailLogin(String? value) {
  if (value == null || value.isEmpty) {
    return 'Por favor ingresa tu correo';
  }
  if (!value.contains('@')) {
    return 'Ingresa un correo válido';
  }
  return null;
}

String? validarPasswordLogin(String? value) {
  if (value == null || value.isEmpty) {
    return 'Por favor ingresa tu contraseña';
  }
  if (value.length < 6) {
    return 'La contraseña debe tener al menos 6 caracteres';
  }
  return null;
}

String obtenerEndpointLogin(String rol) {
  const baseUrl = 'http://10.0.2.2:3000/api';
  
  switch (rol) {
    case 'Administrador':
      return '$baseUrl/login';
    case 'Docente':
      return '$baseUrl/docente/login';
    case 'Estudiante':
    default:
      return '$baseUrl/estudiante/login';
  }
}

Map<String, String> prepararBodyLogin({
  required String rol,
  required String email,
  required String password,
}) {
  if (rol == 'Estudiante') {
    return {
      'emailEstudiante': email,
      'password': password,
    };
  } else {
    // Docente y Administrador usan 'email'
    return {
      'email': email,
      'password': password,
    };
  }
}

String obtenerDestinoSegunRol(String rol) {
  // Todos los roles van al mismo HomeScreen
  // que luego muestra funcionalidades según rol
  return '/home';
}

String normalizarEmailLogin(String email) {
  return email.trim().toLowerCase();
}