import 'sessao_estudo.dart';

class MateriaProficiencia {
  final String nomeMateria;
  final int nivelProficiencia; // 1 a 5

  MateriaProficiencia({
    required this.nomeMateria,
    required this.nivelProficiencia,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomeMateria': nomeMateria,
      'nivelProficiencia': nivelProficiencia,
    };
  }

  factory MateriaProficiencia.fromMap(Map<String, dynamic> map) {
    return MateriaProficiencia(
      nomeMateria: map['nomeMateria'],
      nivelProficiencia: map['nivelProficiencia'],
    );
  }
}

class RecompensaConfig {
  final String tipoRecompensa; // 'diaria', 'semanal', 'mensal'
  final String descricaoRecompensa;

  RecompensaConfig({
    required this.tipoRecompensa,
    required this.descricaoRecompensa,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipoRecompensa': tipoRecompensa,
      'descricaoRecompensa': descricaoRecompensa,
    };
  }

  factory RecompensaConfig.fromMap(Map<String, dynamic> map) {
    return RecompensaConfig(
      tipoRecompensa: map['tipoRecompensa'],
      descricaoRecompensa: map['descricaoRecompensa'],
    );
  }
}

class PlanoEstudo {
  final String id;
  final String userId;
  final String editalId;
  final List<String> cargoIds;
  final DateTime dataCriacao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final Map<String, int> horasSemanais; // {'segunda': 2, 'terca': 3, ...}
  final List<String> ferramentas;
  final List<MateriaProficiencia> materiasProficiencia;
  final List<RecompensaConfig> recompensas;
  final List<SessaoEstudo> sessoesEstudo;

  PlanoEstudo({
    required this.id,
    required this.userId,
    required this.editalId,
    required this.cargoIds,
    required this.dataCriacao,
    required this.dataInicio,
    required this.dataFim,
    required this.horasSemanais,
    required this.ferramentas,
    required this.materiasProficiencia,
    required this.recompensas,
    required this.sessoesEstudo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'editalId': editalId,
      'cargoIds': cargoIds,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataInicio': dataInicio.toIso8601String(),
      'dataFim': dataFim.toIso8601String(),
      'horasSemanais': horasSemanais,
      'ferramentas': ferramentas,
      'materiasProficiencia': materiasProficiencia.map((m) => m.toMap()).toList(),
      'recompensas': recompensas.map((r) => r.toMap()).toList(),
      'sessoesEstudo': sessoesEstudo.map((s) => s.toMap()).toList(),
    };
  }

  factory PlanoEstudo.fromMap(Map<String, dynamic> map) {
    return PlanoEstudo(
      id: map['id'],
      userId: map['userId'],
      editalId: map['editalId'],
      cargoIds: List<String>.from(map['cargoIds']),
      dataCriacao: DateTime.parse(map['dataCriacao']),
      dataInicio: DateTime.parse(map['dataInicio']),
      dataFim: DateTime.parse(map['dataFim']),
      horasSemanais: Map<String, int>.from(map['horasSemanais']),
      ferramentas: List<String>.from(map['ferramentas']),
      materiasProficiencia: List<MateriaProficiencia>.from(
          map['materiasProficiencia']?.map((x) => MateriaProficiencia.fromMap(x))),
      recompensas: List<RecompensaConfig>.from(
          map['recompensas']?.map((x) => RecompensaConfig.fromMap(x))),
      sessoesEstudo: List<SessaoEstudo>.from(
          map['sessoesEstudo']?.map((x) => SessaoEstudo.fromMap(x))),
    );
  }
}
