class SessaoEstudo {
  final String id;
  final String planoId;
  final String materiaId;
  final String materia;
  final List<String> assuntoIds;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final int duracaoMinutos;
  final List<String> ferramentas;
  final String? observacoes;
  final bool concluida;
  final String tipoTimer; // 'progressivo' ou 'regressivo'

  SessaoEstudo({
    required this.id,
    required this.planoId,
    required this.materiaId,
    required this.materia,
    this.assuntoIds = const [],
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.duracaoMinutos,
    required this.ferramentas,
    this.observacoes,
    this.concluida = false,
    this.tipoTimer = 'progressivo',
  });

  // Calcular duração da sessão em minutos
  static int calcularDuracao(DateTime inicio, DateTime fim) {
    return fim.difference(inicio).inMinutes;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planoId': planoId,
      'materiaId': materiaId,
      'materia': materia,
      'assuntoIds': assuntoIds,
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'dataHoraFim': dataHoraFim.toIso8601String(),
      'duracaoMinutos': duracaoMinutos,
      'ferramentas': ferramentas,
      'observacoes': observacoes,
      'concluida': concluida,
      'tipoTimer': tipoTimer,
    };
  }

  factory SessaoEstudo.fromMap(Map<String, dynamic> map) {
    return SessaoEstudo(
      id: map['id'],
      planoId: map['planoId'],
      materiaId: map['materiaId'] ?? '',
      materia: map['materia'],
      assuntoIds: map['assuntoIds'] != null ? List<String>.from(map['assuntoIds']) : [],
      dataHoraInicio: DateTime.parse(map['dataHoraInicio']),
      dataHoraFim: DateTime.parse(map['dataHoraFim']),
      duracaoMinutos: map['duracaoMinutos'],
      ferramentas: List<String>.from(map['ferramentas']),
      observacoes: map['observacoes'],
      concluida: map['concluida'] ?? false,
      tipoTimer: map['tipoTimer'] ?? 'progressivo',
    );
  }

  SessaoEstudo copyWith({
    String? id,
    String? planoId,
    String? materiaId,
    String? materia,
    List<String>? assuntoIds,
    DateTime? dataHoraInicio,
    DateTime? dataHoraFim,
    int? duracaoMinutos,
    List<String>? ferramentas,
    String? observacoes,
    bool? concluida,
    String? tipoTimer,
  }) {
    return SessaoEstudo(
      id: id ?? this.id,
      planoId: planoId ?? this.planoId,
      materiaId: materiaId ?? this.materiaId,
      materia: materia ?? this.materia,
      assuntoIds: assuntoIds ?? this.assuntoIds,
      dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
      dataHoraFim: dataHoraFim ?? this.dataHoraFim,
      duracaoMinutos: duracaoMinutos ?? this.duracaoMinutos,
      ferramentas: ferramentas ?? this.ferramentas,
      observacoes: observacoes ?? this.observacoes,
      concluida: concluida ?? this.concluida,
      tipoTimer: tipoTimer ?? this.tipoTimer,
    );
  }
}
