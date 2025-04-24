class ProgressoEstudo {
  final String id;
  final String userId;
  final String editalId;
  final String materiaId;
  final String? topicoId;
  final EstadoProgresso estado;
  final DateTime dataAtualizacao;

  ProgressoEstudo({
    required this.id,
    required this.userId,
    required this.editalId,
    required this.materiaId,
    this.topicoId,
    required this.estado,
    required this.dataAtualizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'editalId': editalId,
      'materiaId': materiaId,
      'topicoId': topicoId,
      'estado': estado.index,
      'dataAtualizacao': dataAtualizacao.toIso8601String(),
    };
  }

  factory ProgressoEstudo.fromMap(Map<String, dynamic> map) {
    return ProgressoEstudo(
      id: map['id'],
      userId: map['userId'],
      editalId: map['editalId'],
      materiaId: map['materiaId'],
      topicoId: map['topicoId'],
      estado: EstadoProgresso.values[map['estado']],
      dataAtualizacao: DateTime.parse(map['dataAtualizacao']),
    );
  }

  // Métodos para serialização JSON
  Map<String, dynamic> toJson() => toMap();

  factory ProgressoEstudo.fromJson(Map<String, dynamic> json) => ProgressoEstudo.fromMap(json);
}

enum EstadoProgresso {
  naoEstudado,
  estudado,
  primeiraRevisao,
  segundaRevisao,
  terceiraRevisao,
}

// Extensão para obter cores e nomes dos estados
extension EstadoProgressoExtension on EstadoProgresso {
  String get nome {
    switch (this) {
      case EstadoProgresso.naoEstudado:
        return 'Não estudado';
      case EstadoProgresso.estudado:
        return 'Estudado';
      case EstadoProgresso.primeiraRevisao:
        return '1ª Revisão';
      case EstadoProgresso.segundaRevisao:
        return '2ª Revisão';
      case EstadoProgresso.terceiraRevisao:
        return '3ª Revisão';
    }
  }

  String get corHex {
    switch (this) {
      case EstadoProgresso.naoEstudado:
        return '#FFFFFF'; // Branco
      case EstadoProgresso.estudado:
        return '#4CAF50'; // Verde
      case EstadoProgresso.primeiraRevisao:
        return '#FFEB3B'; // Amarelo
      case EstadoProgresso.segundaRevisao:
        return '#FF9800'; // Laranja
      case EstadoProgresso.terceiraRevisao:
        return '#F44336'; // Vermelho
    }
  }
}
