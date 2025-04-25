import 'base_model.dart';

class Flashcard implements BaseModel {
  final String id;
  final String userId;
  final String? editalId; // Opcional
  final String materia;
  final String pergunta;
  final String resposta;
  final String fonte; // 'manual' ou 'ia'

  Flashcard({
    required this.id,
    required this.userId,
    this.editalId,
    required this.materia,
    required this.pergunta,
    required this.resposta,
    required this.fonte,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'editalId': editalId,
      'materia': materia,
      'pergunta': pergunta,
      'resposta': resposta,
      'fonte': fonte,
    };
  }

  @override
  Map<String, dynamic> toJson() => toMap();

  factory Flashcard.fromMap(Map<String, dynamic> map) {
    return Flashcard(
      id: map['id'],
      userId: map['userId'],
      editalId: map['editalId'],
      materia: map['materia'],
      pergunta: map['pergunta'],
      resposta: map['resposta'],
      fonte: map['fonte'],
    );
  }

  @override
  Flashcard copyWith({
    String? id,
    String? userId,
    String? editalId,
    String? materia,
    String? pergunta,
    String? resposta,
    String? fonte,
  }) {
    return Flashcard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      editalId: editalId ?? this.editalId,
      materia: materia ?? this.materia,
      pergunta: pergunta ?? this.pergunta,
      resposta: resposta ?? this.resposta,
      fonte: fonte ?? this.fonte,
    );
  }
}
