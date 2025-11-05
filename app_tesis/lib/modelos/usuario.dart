import 'dart:convert';
import '../config/api_config.dart';

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String rol; // 'Administrador', 'Docente', 'Estudiante'
  final String? fotoPerfil;
  final bool status;
  final bool confirmEmail;

  // Campos específicos según el rol
  final String? cedula; // Solo docentes
  final String? telefono; // Estudiantes
  final String? celular; // Docentes
  final String? oficina; // Docentes
  final String? emailAlternativo; // Docentes
  final List<String>? asignaturas; // Docentes
  final String? semestreAsignado; // Docentes
  final DateTime? fechaNacimiento; // Docentes
  final DateTime? fechaIngreso; // Docentes

  // OAuth (no lo usaremos por ahora)
  final bool isOAuth;
  final String? oauthProvider;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.fotoPerfil,
    required this.status,
    required this.confirmEmail,
    this.cedula,
    this.telefono,
    this.celular,
    this.oficina,
    this.emailAlternativo,
    this.asignaturas,
    this.semestreAsignado,
    this.fechaNacimiento,
    this.fechaIngreso,
    this.isOAuth = false,
    this.oauthProvider,
  });

  // Convierte JSON del backend a objeto Usuario
  factory Usuario.fromJson(Map<String, dynamic> json, String rol) {
    print('🔍 Usuario.fromJson llamado');
    print('   Rol recibido: $rol');
    print('   JSON keys: ${json.keys.join(", ")}');
    print('   _id: ${json['_id']}');
    print('   id: ${json['id']}');
    
    switch (rol) {
      case 'Administrador':
        final id = json['_id'] ?? json['id'] ?? '';
        print('✅ Admin ID extraído: $id');
        return Usuario(
          id: id,
          nombre: json['nombreAdministrador'] ?? '',
          email: json['email'] ?? '',
          rol: 'Administrador',
          fotoPerfil: json['fotoPerfilAdmin'],
          status: json['status'] ?? true,
          confirmEmail: json['confirmEmail'] ?? true,
          isOAuth: json['isOAuth'] ?? false,
          oauthProvider: json['oauthProvider'],
        );

      case 'Docente':
        final id = json['_id'] ?? json['id'] ?? '';
        print('✅ Docente ID extraído: $id');
        
        // ========================================
        // ✅ PROCESAMIENTO CORRECTO DE ASIGNATURAS
        // ========================================
        List<String>? asignaturasFinales;
        
        if (json['asignaturas'] != null) {
          print('📚 Procesando asignaturas...');
          print('   Tipo: ${json['asignaturas'].runtimeType}');
          print('   Valor: ${json['asignaturas']}');
          
          if (json['asignaturas'] is List) {
            // Ya es una lista
            asignaturasFinales = List<String>.from(json['asignaturas']);
            print('   ✅ Ya es una lista: ${asignaturasFinales.length} materias');
          } else if (json['asignaturas'] is String) {
            // Es un string, intentar parsear
            final stringValue = json['asignaturas'] as String;
            
            // Si es un string vacío o "[]", tratar como lista vacía
            if (stringValue.trim().isEmpty || stringValue.trim() == '[]') {
              asignaturasFinales = [];
              print('   ℹ️ String vacío o "[]", usando lista vacía');
            } else {
              try {
                final parsed = jsonDecode(stringValue);
                if (parsed is List) {
                  asignaturasFinales = List<String>.from(parsed);
                  print('   ✅ Parseado desde string: ${asignaturasFinales.length} materias');
                } else {
                  asignaturasFinales = [];
                  print('   ⚠️ String parseado no es una lista válida');
                }
              } catch (e) {
                print('   ❌ Error parseando string: $e');
                asignaturasFinales = [];
              }
            }
          } else {
            asignaturasFinales = [];
            print('   ⚠️ Tipo no reconocido, usando lista vacía');
          }
        } else {
          asignaturasFinales = [];
          print('   ℹ️ asignaturas es null, usando lista vacía');
        }
        
        print('   📋 Asignaturas finales: ${asignaturasFinales.isEmpty ? "ninguna" : asignaturasFinales.join(", ")}');
        
        return Usuario(
          id: id,
          nombre: json['nombreDocente'] ?? '',
          email: json['emailDocente'] ?? '',
          rol: 'Docente',
          fotoPerfil: json['avatarDocente'],
          status: json['estadoDocente'] ?? true,
          confirmEmail: json['confirmEmail'] ?? true,
          cedula: json['cedulaDocente'],
          celular: json['celularDocente'],
          oficina: json['oficinaDocente'],
          emailAlternativo: json['emailAlternativoDocente'],
          asignaturas: asignaturasFinales,                    // ✅ CORREGIDO
          semestreAsignado: json['semestreAsignado'],
          fechaNacimiento: json['fechaNacimientoDocente'] != null
              ? DateTime.parse(json['fechaNacimientoDocente'])
              : null,
          fechaIngreso: json['fechaIngresoDocente'] != null
              ? DateTime.parse(json['fechaIngresoDocente'])
              : null,
          isOAuth: json['isOAuth'] ?? false,
          oauthProvider: json['oauthProvider'],
        );

      case 'Estudiante':
      default:
        final id = json['_id'] ?? json['id'] ?? '';
        print('✅ Estudiante ID extraído: $id');
        
        if (id.isEmpty) {
          print('⚠️ ADVERTENCIA: ID de estudiante está vacío');
          print('   JSON completo: $json');
        }
        
        return Usuario(
          id: id,
          nombre: json['nombreEstudiante'] ?? '',
          email: json['emailEstudiante'] ?? '',
          rol: 'Estudiante',
          fotoPerfil: json['fotoPerfil'],
          status: json['status'] ?? true,
          confirmEmail: json['confirmEmail'] ?? false,
          telefono: json['telefono'],
          isOAuth: json['isOAuth'] ?? false,
          oauthProvider: json['oauthProvider'],
        );
    }
  }

  // Convierte el objeto Usuario a JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fotoPerfil': fotoPerfil,
      'status': status,
      'confirmEmail': confirmEmail,
      'isOAuth': isOAuth,
      'oauthProvider': oauthProvider,
    };

    if (cedula != null) data['cedula'] = cedula;
    if (telefono != null) data['telefono'] = telefono;
    if (celular != null) data['celular'] = celular;
    if (oficina != null) data['oficina'] = oficina;
    if (emailAlternativo != null) data['emailAlternativo'] = emailAlternativo;
    if (asignaturas != null) data['asignaturas'] = asignaturas; // ✅ COMO LISTA
    if (semestreAsignado != null) data['semestreAsignado'] = semestreAsignado;
    if (fechaNacimiento != null) {
      data['fechaNacimiento'] = fechaNacimiento!.toIso8601String();
    }
    if (fechaIngreso != null) {
      data['fechaIngreso'] = fechaIngreso!.toIso8601String();
    }

    return data;
  }

  // Crea una copia del usuario con campos modificados
  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rol,
    String? fotoPerfil,
    bool? status,
    bool? confirmEmail,
    String? cedula,
    String? telefono,
    String? celular,
    String? oficina,
    String? emailAlternativo,
    List<String>? asignaturas,
    String? semestreAsignado,
    DateTime? fechaNacimiento,
    DateTime? fechaIngreso,
    bool? isOAuth,
    String? oauthProvider,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      status: status ?? this.status,
      confirmEmail: confirmEmail ?? this.confirmEmail,
      cedula: cedula ?? this.cedula,
      telefono: telefono ?? this.telefono,
      celular: celular ?? this.celular,
      oficina: oficina ?? this.oficina,
      emailAlternativo: emailAlternativo ?? this.emailAlternativo,
      asignaturas: asignaturas ?? this.asignaturas,
      semestreAsignado: semestreAsignado ?? this.semestreAsignado,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fechaIngreso: fechaIngreso ?? this.fechaIngreso,
      isOAuth: isOAuth ?? this.isOAuth,
      oauthProvider: oauthProvider ?? this.oauthProvider,
    );
  }

  @override
  String toString() {
    return 'Usuario{id: $id, nombre: $nombre, email: $email, rol: $rol}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Usuario && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Métodos útiles
  bool get esAdministrador => rol == 'Administrador';
  bool get esDocente => rol == 'Docente';
  bool get esEstudiante => rol == 'Estudiante';
  bool get esOAuth => isOAuth;

  String get nombreCompleto => nombre;
  
  String get fotoPerfilUrl {
    final placeholder =
        'https://cdn-icons-png.flaticon.com/512/4715/4715329.png';
    if (fotoPerfil == null || fotoPerfil!.trim().isEmpty) return placeholder;
    final f = fotoPerfil!.trim();
    if (f.startsWith('http')) return f;
    // si viene una ruta relativa (p.ej. /uploads/...), la normalizamos con baseUrl
    var base = ApiConfig.baseUrl;
    // baseUrl contiene '/api' al final; si la ruta ya incluye '/api' o '/uploads' manejamos sin duplicar
    if (f.startsWith('/')) {
      // quitar '/api' si base termina en '/api' para apuntar al host
      if (base.endsWith('/api')) {
        base = base.replaceFirst('/api', '');
      }
      return base + f;
    }
    // caso: ruta sin slash inicial
    if (base.endsWith('/')) {
      return base + f;
    }
    return '$base/$f';
  }
}