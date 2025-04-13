import 'sessao_estudo.dart';
import 'base_model.dart';
import 'dart:convert';

class MateriaProficiencia implements BaseModel {
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

  @override
  MateriaProficiencia copyWith({
    String? nomeMateria,
    int? nivelProficiencia,
  }) {
    return MateriaProficiencia(
      nomeMateria: nomeMateria ?? this.nomeMateria,
      nivelProficiencia: nivelProficiencia ?? this.nivelProficiencia,
    );
  }
}

class Materia implements BaseModel {
  final String id;
  final String nome;
  final String tipo; // 'básico', 'específico', etc.
  final List<String> diasEstudo; // dias da semana: 'segunda', 'terça', etc.
  final int questoes; // número de questões
  final List<String> assuntos; // lista de assuntos da matéria
  final Map<String, dynamic> metadados; // dados adicionais

  Materia({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.diasEstudo,
    this.questoes = 0,
    this.assuntos = const [],
    Map<String, dynamic>? metadados,
  }) : this.metadados = metadados ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'diasEstudo': diasEstudo,
      'questoes': questoes,
      'assuntos': assuntos,
      'metadados': metadados,
    };
  }

  factory Materia.fromMap(Map<String, dynamic> map) {
    return Materia(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      tipo: map['tipo'] ?? '',
      diasEstudo: List<String>.from(map['diasEstudo'] ?? []),
      questoes: map['questoes'] ?? 0,
      assuntos: List<String>.from(map['assuntos'] ?? []),
      metadados: map['metadados'] != null ? Map<String, dynamic>.from(map['metadados']) : {},
    );
  }

  String toJson() => json.encode(toMap());

  factory Materia.fromJson(String source) => Materia.fromMap(json.decode(source));

  @override
  Materia copyWith({
    String? id,
    String? nome,
    String? tipo,
    List<String>? diasEstudo,
    int? questoes,
    List<String>? assuntos,
    Map<String, dynamic>? metadados,
  }) {
    return Materia(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      diasEstudo: diasEstudo ?? this.diasEstudo,
      questoes: questoes ?? this.questoes,
      assuntos: assuntos ?? this.assuntos,
      metadados: metadados ?? this.metadados,
    );
  }
}

class RecompensaConfig implements BaseModel {
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
      tipoRecompensa: map['tipoRecompensa'] ?? '',
      descricaoRecompensa: map['descricaoRecompensa'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory RecompensaConfig.fromJson(String source) => RecompensaConfig.fromMap(json.decode(source));

  @override
  RecompensaConfig copyWith({
    String? tipoRecompensa,
    String? descricaoRecompensa,
  }) {
    return RecompensaConfig(
      tipoRecompensa: tipoRecompensa ?? this.tipoRecompensa,
      descricaoRecompensa: descricaoRecompensa ?? this.descricaoRecompensa,
    );
  }
}

class PlanoEstudo implements BaseModel {
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
  final Map<String, dynamic> metadados; // Dados adicionais como orgão, banca, data da prova, etc.
  final String titulo; // Título do plano de estudo
  final List<Materia> materias; // Lista de matérias do plano

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
    required this.titulo,
    required this.materias,
    Map<String, dynamic>? metadados,
  }) : this.metadados = metadados ?? {};

  Map<String, dynamic> toMap() {
    final map = {
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
      'titulo': titulo,
      'materias': materias.map((m) => m.toMap()).toList(),
    };

    // Adicionar metadados
    map['metadados'] = metadados;

    return map;
  }

  String toJson() => json.encode(toMap());

  factory PlanoEstudo.fromMap(Map<String, dynamic> map) {
    return PlanoEstudo(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      editalId: map['editalId'] ?? '',
      cargoIds: List<String>.from(map['cargoIds'] ?? []),
      dataCriacao: map['dataCriacao'] != null ? DateTime.parse(map['dataCriacao']) : DateTime.now(),
      dataInicio: map['dataInicio'] != null ? DateTime.parse(map['dataInicio']) : DateTime.now(),
      dataFim: map['dataFim'] != null ? DateTime.parse(map['dataFim']) : DateTime.now().add(Duration(days: 90)),
      horasSemanais: Map<String, int>.from(map['horasSemanais'] ?? {}),
      ferramentas: List<String>.from(map['ferramentas'] ?? []),
      materiasProficiencia: map['materiasProficiencia'] != null
          ? List<MateriaProficiencia>.from(
              map['materiasProficiencia'].map((x) => MateriaProficiencia.fromMap(x)))
          : [],
      recompensas: map['recompensas'] != null
          ? List<RecompensaConfig>.from(
              map['recompensas'].map((x) => RecompensaConfig.fromMap(x)))
          : [],
      sessoesEstudo: map['sessoesEstudo'] != null
          ? List<SessaoEstudo>.from(
              map['sessoesEstudo'].map((x) => SessaoEstudo.fromMap(x)))
          : [],
      titulo: map['titulo'] ?? 'Plano de Estudo',
      materias: map['materias'] != null
          ? List<Materia>.from(
              map['materias'].map((x) => Materia.fromMap(x)))
          : [],
      metadados: map['metadados'] != null ? Map<String, dynamic>.from(map['metadados']) : {},
    );
  }

  factory PlanoEstudo.fromJson(String source) => PlanoEstudo.fromMap(json.decode(source));

  @override
  PlanoEstudo copyWith({
    String? id,
    String? userId,
    String? editalId,
    List<String>? cargoIds,
    DateTime? dataCriacao,
    DateTime? dataInicio,
    DateTime? dataFim,
    Map<String, int>? horasSemanais,
    List<String>? ferramentas,
    List<MateriaProficiencia>? materiasProficiencia,
    List<RecompensaConfig>? recompensas,
    List<SessaoEstudo>? sessoesEstudo,
    Map<String, dynamic>? metadados,
    String? titulo,
    List<Materia>? materias,
  }) {
    return PlanoEstudo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      editalId: editalId ?? this.editalId,
      cargoIds: cargoIds ?? this.cargoIds,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      dataInicio: dataInicio ?? this.dataInicio,
      dataFim: dataFim ?? this.dataFim,
      horasSemanais: horasSemanais ?? this.horasSemanais,
      ferramentas: ferramentas ?? this.ferramentas,
      materiasProficiencia: materiasProficiencia ?? this.materiasProficiencia,
      recompensas: recompensas ?? this.recompensas,
      sessoesEstudo: sessoesEstudo ?? this.sessoesEstudo,
      metadados: metadados ?? this.metadados,
      titulo: titulo ?? this.titulo,
      materias: materias ?? this.materias,
    );
  }
}
