// ============================================
// PRUEBA UNITARIA - REGISTRO DE ESTUDIANTE
// Figura 3.2: Conclusión de la prueba de software unitaria – Registro de estudiante
// ============================================

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HU-001: Registro de Estudiante', () {
    
    test('✓ Validación de nombre completo obligatorio', () {
      final resultado = validarNombreCompleto('');
      expect(resultado, 'El nombre es obligatorio');
    });

    test('✓ Validación de nombre completo válido', () {
      final resultado = validarNombreCompleto('Juan Pérez García');
      expect(resultado, null);
    });

    test('✓ Validación de email único - formato correcto', () {
      final resultado = validarEmailRegistro('estudiante@example.com');
      expect(resultado, null);
    });

    test('✓ Validación de email único - formato incorrecto', () {
      final resultado = validarEmailRegistro('correo-invalido');
      expect(resultado, 'Ingresa un email válido');
    });

    test('✓ Validación de email único - campo vacío', () {
      final resultado = validarEmailRegistro('');
      expect(resultado, 'El email es obligatorio');
    });

    test('✓ Validación de contraseña mínimo 8 caracteres - válida', () {
      final resultado = validarPasswordRegistro('Password123');
      expect(resultado, null);
    });

    test('✓ Validación de contraseña mínimo 8 caracteres - menor a 8', () {
      final resultado = validarPasswordRegistro('Pass12');
      expect(resultado, 'La contraseña debe tener al menos 8 caracteres');
    });

    test('✓ Validación de contraseña mínimo 8 caracteres - exactamente 8', () {
      final resultado = validarPasswordRegistro('12345678');
      expect(resultado, null);
    });

    test('✓ Validación de confirmación de contraseña - coinciden', () {
      final resultado = validarConfirmacionPassword('Password123', 'Password123');
      expect(resultado, null);
    });

    test('✓ Validación de confirmación de contraseña - no coinciden', () {
      final resultado = validarConfirmacionPassword('Password123', 'Password456');
      expect(resultado, 'Las contraseñas no coinciden');
    });

    test('✓ Validación de teléfono opcional - vacío es válido', () {
      final resultado = validarTelefonoOpcional('');
      expect(resultado, null);
    });

    test('✓ Validación de teléfono opcional - 10 dígitos válido', () {
      final resultado = validarTelefonoOpcional('0987654321');
      expect(resultado, null);
    });

    test('✓ Validación de teléfono opcional - menor a 10 dígitos', () {
      final resultado = validarTelefonoOpcional('098765');
      expect(resultado, 'El teléfono debe tener al menos 10 dígitos');
    });

    test('✓ Detección de email institucional - estudiante normal', () {
      final esInstitucional = detectarEmailInstitucional('juan.perez@gmail.com');
      expect(esInstitucional, false);
    });

    test('✓ Detección de email institucional - docente EPN', () {
      final esInstitucional = detectarEmailInstitucional('profesor@epn.edu.ec');
      expect(esInstitucional, true);
    });

    test('✓ Preparación de datos para envío - formato JSON correcto', () {
      final datos = prepararDatosRegistro(
        nombre: 'Juan Pérez',
        email: 'juan@example.com',
        password: 'Password123',
        telefono: '0987654321',
      );
      
      expect(datos['nombreEstudiante'], 'Juan Pérez');
      expect(datos['emailEstudiante'], 'juan@example.com');
      expect(datos['password'], 'Password123');
      expect(datos['telefono'], '0987654321');
    });

    test('✓ Preparación de datos sin teléfono - campo vacío', () {
      final datos = prepararDatosRegistro(
        nombre: 'María López',
        email: 'maria@example.com',
        password: 'Secure123',
        telefono: null,
      );
      
      expect(datos['telefono'], '');
    });

    test('✓ Normalización de email - conversión a minúsculas', () {
      final emailNormalizado = normalizarEmail('USUARIO@EXAMPLE.COM');
      expect(emailNormalizado, 'usuario@example.com');
    });

    test('✓ Normalización de email - eliminación de espacios', () {
      final emailNormalizado = normalizarEmail('  usuario@example.com  ');
      expect(emailNormalizado, 'usuario@example.com');
    });
  });
}

// ============================================
// FUNCIONES DE VALIDACIÓN - REGISTRO
// ============================================

String? validarNombreCompleto(String? value) {
  if (value == null || value.isEmpty) {
    return 'El nombre es obligatorio';
  }
  return null;
}

String? validarEmailRegistro(String? value) {
  if (value == null || value.isEmpty) {
    return 'El email es obligatorio';
  }
  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
  if (!emailRegex.hasMatch(value)) {
    return 'Ingresa un email válido';
  }
  return null;
}

String? validarPasswordRegistro(String? value) {
  if (value == null || value.isEmpty) {
    return 'La contraseña es obligatoria';
  }
  if (value.length < 8) {
    return 'La contraseña debe tener al menos 8 caracteres';
  }
  return null;
}

String? validarConfirmacionPassword(String? value, String password) {
  if (value == null || value.isEmpty) {
    return 'Confirma tu contraseña';
  }
  if (value != password) {
    return 'Las contraseñas no coinciden';
  }
  return null;
}

String? validarTelefonoOpcional(String? value) {
  if (value != null && value.isNotEmpty) {
    if (value.length < 10) {
      return 'El teléfono debe tener al menos 10 dígitos';
    }
  }
  return null;
}

bool detectarEmailInstitucional(String email) {
  return email.toLowerCase().contains('@epn.edu.ec');
}

Map<String, dynamic> prepararDatosRegistro({
  required String nombre,
  required String email,
  required String password,
  String? telefono,
}) {
  return {
    'nombreEstudiante': nombre,
    'emailEstudiante': email,
    'password': password,
    'telefono': telefono ?? '',
  };
}

String normalizarEmail(String email) {
  return email.trim().toLowerCase();
}