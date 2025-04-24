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
