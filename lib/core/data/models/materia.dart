import 'assunto.dart';

class Materia {
  final String id;
  final String nome;
  final String? editalId;
  final String? cargoId;
  final List<Assunto> assuntos;
  final int nivelProficiencia; // 1 a 5

  Materia({
    required this.id,
    required this.nome,
    this.editalId,
    this.cargoId,
    this.assuntos = const [],
    this.nivelProficiencia = 3,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'editalId': editalId,
      'cargoId': cargoId,
      'assuntos': assuntos.map((a) => a.toMap()).toList(),
      'nivelProficiencia': nivelProficiencia,
    };
  }

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'],
      nome: map['nome'],
      editalId: map['editalId'],
      cargoId: map['cargoId'],
      assuntos: map['assuntos'] != null
          ? List<Assunto>.from(map['assuntos']?.map((x) => Assunto.fromMap(x)))
          : [],
      nivelProficiencia: map['nivelProficiencia'] ?? 3,
    );
  }

  Materia copyWith({
    String? id,
    String? nome,
    String? editalId,
    String? cargoId,
    List<Assunto>? assuntos,
    int? nivelProficiencia,
  }) {
    return Materia(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      editalId: editalId ?? this.editalId,
      cargoId: cargoId ?? this.cargoId,
      assuntos: assuntos ?? this.assuntos,
      nivelProficiencia: nivelProficiencia ?? this.nivelProficiencia,
    );
  }
}
