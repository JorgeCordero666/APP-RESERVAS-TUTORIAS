// lib/modelos/horario.dart
class Horario {
  final String id;
  final String? materia;
  final String diaSemana;
  final List<Map<String, dynamic>> bloques;

  Horario({
    required this.id,
    this.materia,
    required this.diaSemana,
    required this.bloques,
  });

  factory Horario.fromJson(Map<String, dynamic> json) {
    return Horario(
      id: json['_id'] ?? '',
      materia: json['materia'],
      diaSemana: json['diaSemana'] ?? '',
      bloques: List<Map<String, dynamic>>.from(json['bloques'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materia': materia,
      'diaSemana': diaSemana,
      'bloques': bloques,
    };
  }
}
