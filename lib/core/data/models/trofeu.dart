class Trofeu {
  final String id;
  final String nomeTrofeu;
  final String descricaoTrofeu;
  final String icone;

  Trofeu({
    required this.id,
    required this.nomeTrofeu,
    required this.descricaoTrofeu,
    required this.icone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomeTrofeu': nomeTrofeu,
      'descricaoTrofeu': descricaoTrofeu,
      'icone': icone,
    };
  }

  factory Trofeu.fromMap(Map<String, dynamic> map) {
    return Trofeu(
      id: map['id'],
      nomeTrofeu: map['nomeTrofeu'],
      descricaoTrofeu: map['descricaoTrofeu'],
      icone: map['icone'],
    );
  }
}

class UsuarioTrofeu {
  final String userId;
  final String trofeuId;
  final DateTime dataConquista;

  UsuarioTrofeu({
    required this.userId,
    required this.trofeuId,
    required this.dataConquista,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'trofeuId': trofeuId,
      'dataConquista': dataConquista.toIso8601String(),
    };
  }

  factory UsuarioTrofeu.fromMap(Map<String, dynamic> map) {
    return UsuarioTrofeu(
      userId: map['userId'],
      trofeuId: map['trofeuId'],
      dataConquista: DateTime.parse(map['dataConquista']),
    );
  }
}
