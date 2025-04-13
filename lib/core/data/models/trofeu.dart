import 'base_model.dart';

class Trofeu implements BaseModel {
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

  @override
  Trofeu copyWith({
    String? id,
    String? nomeTrofeu,
    String? descricaoTrofeu,
    String? icone,
  }) {
    return Trofeu(
      id: id ?? this.id,
      nomeTrofeu: nomeTrofeu ?? this.nomeTrofeu,
      descricaoTrofeu: descricaoTrofeu ?? this.descricaoTrofeu,
      icone: icone ?? this.icone,
    );
  }
}

class UsuarioTrofeu implements BaseModel {
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

  @override
  UsuarioTrofeu copyWith({
    String? userId,
    String? trofeuId,
    DateTime? dataConquista,
  }) {
    return UsuarioTrofeu(
      userId: userId ?? this.userId,
      trofeuId: trofeuId ?? this.trofeuId,
      dataConquista: dataConquista ?? this.dataConquista,
    );
  }
}
