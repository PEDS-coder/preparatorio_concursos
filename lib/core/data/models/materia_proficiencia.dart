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
      nivelProficiencia: map['nivelProficiencia'] ?? 3,
    );
  }

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
