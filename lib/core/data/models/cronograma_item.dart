enum StatusItem {
  pendente,
  concluido,
  pulado,
}

class CronogramaItem {
  final String id;
  final String planoId;
  final DateTime dataHoraInicio;
  final DateTime dataHoraFim;
  final String nomeMateria;
  final String atividadeSugerida; // 'leitura', 'video', 'questoes', etc.
  final String ferramentaSugerida;
  final StatusItem status;

  CronogramaItem({
    required this.id,
    required this.planoId,
    required this.dataHoraInicio,
    required this.dataHoraFim,
    required this.nomeMateria,
    required this.atividadeSugerida,
    required this.ferramentaSugerida,
    this.status = StatusItem.pendente,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'planoId': planoId,
      'dataHoraInicio': dataHoraInicio.toIso8601String(),
      'dataHoraFim': dataHoraFim.toIso8601String(),
      'nomeMateria': nomeMateria,
      'atividadeSugerida': atividadeSugerida,
      'ferramentaSugerida': ferramentaSugerida,
      'status': status.toString().split('.').last,
    };
  }

  factory CronogramaItem.fromMap(Map<String, dynamic> map) {
    return CronogramaItem(
      id: map['id'],
      planoId: map['planoId'],
      dataHoraInicio: DateTime.parse(map['dataHoraInicio']),
      dataHoraFim: DateTime.parse(map['dataHoraFim']),
      nomeMateria: map['nomeMateria'],
      atividadeSugerida: map['atividadeSugerida'],
      ferramentaSugerida: map['ferramentaSugerida'],
      status: StatusItem.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => StatusItem.pendente,
      ),
    );
  }

  // Método para criar uma cópia do objeto com algumas propriedades alteradas
  CronogramaItem copyWith({
    String? id,
    String? planoId,
    DateTime? dataHoraInicio,
    DateTime? dataHoraFim,
    String? nomeMateria,
    String? atividadeSugerida,
    String? ferramentaSugerida,
    StatusItem? status,
  }) {
    return CronogramaItem(
      id: id ?? this.id,
      planoId: planoId ?? this.planoId,
      dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
      dataHoraFim: dataHoraFim ?? this.dataHoraFim,
      nomeMateria: nomeMateria ?? this.nomeMateria,
      atividadeSugerida: atividadeSugerida ?? this.atividadeSugerida,
      ferramentaSugerida: ferramentaSugerida ?? this.ferramentaSugerida,
      status: status ?? this.status,
    );
  }
}
