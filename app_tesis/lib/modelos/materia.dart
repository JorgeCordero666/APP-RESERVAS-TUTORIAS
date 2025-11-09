// lib/modelos/materia.dart - VERSIÓN CORREGIDA
class Materia {
  final String id;
  final String nombre;
  final String codigo;
  final String semestre;
  final int creditos;
  final String? descripcion;
  final bool activa;
  final String creadoPor;  // ✅ Solo guardamos el ID
  final DateTime creadaEn;
  final DateTime actualizadaEn;

  Materia({
    required this.id,
    required this.nombre,
    required this.codigo,
    required this.semestre,
    required this.creditos,
    this.descripcion,
    required this.activa,
    required this.creadoPor,
    required this.creadaEn,
    required this.actualizadaEn,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    print('🔍 Parseando materia: ${json['nombre']}');
    print('   Datos recibidos:');
    print('   - _id: ${json['_id']}');
    print('   - creadoPor: ${json['creadoPor']} (${json['creadoPor'].runtimeType})');
    
    // ✅ Manejar creadoPor que puede venir como String o como Object
    String creadoPorId;
    
    if (json['creadoPor'] is String) {
      // Si es un String, usarlo directamente
      creadoPorId = json['creadoPor'];
      print('   ✅ creadoPor es String: $creadoPorId');
    } else if (json['creadoPor'] is Map) {
      // Si es un objeto (populated), extraer el _id
      creadoPorId = json['creadoPor']['_id'] ?? '';
      print('   ✅ creadoPor es Map, extrayendo _id: $creadoPorId');
    } else {
      // Fallback
      creadoPorId = '';
      print('   ⚠️ creadoPor es tipo desconocido, usando string vacío');
    }
    
    try {
      final materia = Materia(
        id: json['_id'] ?? '',
        nombre: json['nombre'] ?? '',
        codigo: json['codigo'] ?? '',
        semestre: json['semestre'] ?? '',
        creditos: json['creditos'] ?? 0,
        descripcion: json['descripcion'],
        activa: json['activa'] ?? true,
        creadoPor: creadoPorId,
        creadaEn: json['creadaEn'] != null 
            ? DateTime.parse(json['creadaEn']) 
            : DateTime.now(),
        actualizadaEn: json['actualizadaEn'] != null
            ? DateTime.parse(json['actualizadaEn'])
            : DateTime.now(),
      );
      
      print('   ✅ Materia parseada exitosamente');
      return materia;
      
    } catch (e) {
      print('   ❌ Error parseando materia: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'codigo': codigo,
      'semestre': semestre,
      'creditos': creditos,
      'descripcion': descripcion,
      'activa': activa,
    };
  }

  Materia copyWith({
    String? id,
    String? nombre,
    String? codigo,
    String? semestre,
    int? creditos,
    String? descripcion,
    bool? activa,
    String? creadoPor,
    DateTime? creadaEn,
    DateTime? actualizadaEn,
  }) {
    return Materia(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      codigo: codigo ?? this.codigo,
      semestre: semestre ?? this.semestre,
      creditos: creditos ?? this.creditos,
      descripcion: descripcion ?? this.descripcion,
      activa: activa ?? this.activa,
      creadoPor: creadoPor ?? this.creadoPor,
      creadaEn: creadaEn ?? this.creadaEn,
      actualizadaEn: actualizadaEn ?? this.actualizadaEn,
    );
  }

  @override
  String toString() {
    return 'Materia{nombre: $nombre, codigo: $codigo, semestre: $semestre}';
  }
}