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
