// lib/modelos/materia.dart
class Materia {
  final String id;
  final String nombre;
  final String codigo;
  final String semestre;
  final int creditos;
  final String? descripcion;
  final bool activa;
  final String creadoPor;
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
    return Materia(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      codigo: json['codigo'] ?? '',
      semestre: json['semestre'] ?? '',
      creditos: json['creditos'] ?? 0,
      descripcion: json['descripcion'],
      activa: json['activa'] ?? true,
      creadoPor: json['creadoPor'] ?? '',
      creadaEn: json['creadaEn'] != null 
          ? DateTime.parse(json['creadaEn']) 
          : DateTime.now(),
      actualizadaEn: json['actualizadaEn'] != null
          ? DateTime.parse(json['actualizadaEn'])
          : DateTime.now(),
    );
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