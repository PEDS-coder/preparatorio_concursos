class Assunto {
  final String id;
  final String nome;
  final String materiaId;
  final int ordem;
  final bool isEstudado;

  Assunto({
    required this.id,
    required this.nome,
    required this.materiaId,
    this.ordem = 0,
    this.isEstudado = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'materiaId': materiaId,
      'ordem': ordem,
      'isEstudado': isEstudado,
    };
  }

  factory Assunto.fromMap(Map<String, dynamic> map) {
    return Assunto(
      id: map['id'],
      nome: map['nome'],
      materiaId: map['materiaId'],
      ordem: map['ordem'] ?? 0,
      isEstudado: map['isEstudado'] ?? false,
    );
  }

  Assunto copyWith({
    String? id,
    String? nome,
    String? materiaId,
    int? ordem,
    bool? isEstudado,
  }) {
    return Assunto(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      materiaId: materiaId ?? this.materiaId,
      ordem: ordem ?? this.ordem,
      isEstudado: isEstudado ?? this.isEstudado,
    );
  }
}
