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
  final String tipoRecompensa; // 'bronze', 'prata', 'ouro', 'platina', 'diamante', 'lendario'
  final String descricaoRecompensa;
  final bool selecionada;

  RecompensaConfig({
    required this.tipoRecompensa,
    required this.descricaoRecompensa,
    this.selecionada = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipoRecompensa': tipoRecompensa,
      'descricaoRecompensa': descricaoRecompensa,
      'selecionada': selecionada,
    };
  }

  factory RecompensaConfig.fromMap(Map<String, dynamic> map) {
    return RecompensaConfig(
      tipoRecompensa: map['tipoRecompensa'],
      descricaoRecompensa: map['descricaoRecompensa'],
      selecionada: map['selecionada'] ?? false,
    );
  }

  RecompensaConfig copyWith({
    String? tipoRecompensa,
    String? descricaoRecompensa,
    bool? selecionada,
  }) {
    return RecompensaConfig(
      tipoRecompensa: tipoRecompensa ?? this.tipoRecompensa,
      descricaoRecompensa: descricaoRecompensa ?? this.descricaoRecompensa,
      selecionada: selecionada ?? this.selecionada,
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
  final Map<String, List<int>>? horariosEspecificos; // {'segunda': [18, 19, 20], 'terca': [19, 20], ...}
  final List<String> ferramentas;
  final List<MateriaProficiencia> materiasProficiencia;
  final List<RecompensaConfig> recompensas;
  final List<SessaoEstudo> sessoesEstudo;
  final Map<String, dynamic> metadados; // Dados adicionais como orgão, banca, data da prova, etc.

  PlanoEstudo({
    required this.id,
    required this.userId,
    required this.editalId,
    required this.cargoIds,
    required this.dataCriacao,
    required this.dataInicio,
    required this.dataFim,
    required this.horasSemanais,
    this.horariosEspecificos,
    required this.ferramentas,
    required this.materiasProficiencia,
    required this.recompensas,
    required this.sessoesEstudo,
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
    };

    // Adicionar horários específicos se existirem
    if (horariosEspecificos != null) {
      final horariosMap = <String, List<dynamic>>{};
      for (var entry in horariosEspecificos!.entries) {
        horariosMap[entry.key] = entry.value.toList();
      }
      map['horariosEspecificos'] = horariosMap;
    }

    // Adicionar metadados
    map['metadados'] = metadados;

    return map;
  }

  factory PlanoEstudo.fromMap(Map<String, dynamic> map) {
    // Processar horários específicos se existirem
    Map<String, List<int>>? horariosEspecificos;
    if (map['horariosEspecificos'] != null) {
      horariosEspecificos = {};
      (map['horariosEspecificos'] as Map<String, dynamic>).forEach((key, value) {
        if (value is List) {
          horariosEspecificos![key] = List<int>.from(value);
        }
      });
    }

    return PlanoEstudo(
      id: map['id'],
      userId: map['userId'],
      editalId: map['editalId'],
      cargoIds: List<String>.from(map['cargoIds']),
      dataCriacao: DateTime.parse(map['dataCriacao']),
      dataInicio: DateTime.parse(map['dataInicio']),
      dataFim: DateTime.parse(map['dataFim']),
      horasSemanais: Map<String, int>.from(map['horasSemanais']),
      horariosEspecificos: horariosEspecificos,
      ferramentas: List<String>.from(map['ferramentas']),
      materiasProficiencia: List<MateriaProficiencia>.from(
          map['materiasProficiencia']?.map((x) => MateriaProficiencia.fromMap(x))),
      recompensas: List<RecompensaConfig>.from(
          map['recompensas']?.map((x) => RecompensaConfig.fromMap(x))),
      sessoesEstudo: List<SessaoEstudo>.from(
          map['sessoesEstudo']?.map((x) => SessaoEstudo.fromMap(x))),
      metadados: map['metadados'] != null ? Map<String, dynamic>.from(map['metadados']) : {},
    );
  }

  // Métodos para serialização JSON
  Map<String, dynamic> toJson() => toMap();

  factory PlanoEstudo.fromJson(Map<String, dynamic> json) => PlanoEstudo.fromMap(json);

  // Getters para compatibilidade com código existente
  String get titulo => metadados['titulo'] ?? 'Plano de Estudo';
  List<dynamic> get materias => metadados['materias'] ?? [];

  // Método copyWith para criar uma cópia com alterações
  PlanoEstudo copyWith({
    String? id,
    String? userId,
    String? editalId,
    List<String>? cargoIds,
    DateTime? dataCriacao,
    DateTime? dataInicio,
    DateTime? dataFim,
    Map<String, int>? horasSemanais,
    Map<String, List<int>>? horariosEspecificos,
    List<String>? ferramentas,
    List<MateriaProficiencia>? materiasProficiencia,
    List<RecompensaConfig>? recompensas,
    List<SessaoEstudo>? sessoesEstudo,
    Map<String, dynamic>? metadados,
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
      horariosEspecificos: horariosEspecificos ?? this.horariosEspecificos,
      ferramentas: ferramentas ?? this.ferramentas,
      materiasProficiencia: materiasProficiencia ?? this.materiasProficiencia,
      recompensas: recompensas ?? this.recompensas,
      sessoesEstudo: sessoesEstudo ?? this.sessoesEstudo,
      metadados: metadados ?? this.metadados,
    );
  }
}
