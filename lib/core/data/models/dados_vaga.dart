import 'dart:convert';

/// Modelo para armazenar informações detalhadas sobre vagas
class DadosVaga {
  /// Número de vagas imediatas
  int? imediatas;
  
  /// Indica se há cadastro de reserva
  bool? cadastroReserva;
  
  /// Distribuição geográfica das vagas (por localidade)
  Map<String, int>? distribuicaoGeografica;
  
  /// Total consolidado de vagas (imediatas + CR)
  int? totalConsolidado;

  DadosVaga({
    this.imediatas,
    this.cadastroReserva,
    this.distribuicaoGeografica,
    this.totalConsolidado,
  });

  /// Cria uma instância a partir de um mapa
  factory DadosVaga.fromMap(Map<String, dynamic> map) {
    return DadosVaga(
      imediatas: map['imediatas'] is num ? (map['imediatas'] as num).toInt() : null,
      cadastroReserva: map['cadastro_reserva'] is bool 
          ? map['cadastro_reserva'] 
          : (map['cadastro_reserva'] is num ? (map['cadastro_reserva'] as num) > 0 : null),
      distribuicaoGeografica: map['distribuicao_geografica'] is Map 
          ? Map<String, int>.from((map['distribuicao_geografica'] as Map).map(
              (k, v) => MapEntry(k.toString(), v is num ? v.toInt() : 0)
            ))
          : null,
      totalConsolidado: map['total_consolidado'] is num ? (map['total_consolidado'] as num).toInt() : null,
    );
  }

  /// Converte a instância para um mapa
  Map<String, dynamic> toMap() {
    return {
      'imediatas': imediatas,
      'cadastro_reserva': cadastroReserva,
      'distribuicao_geografica': distribuicaoGeografica,
      'total_consolidado': totalConsolidado,
    };
  }

  /// Converte a instância para uma string JSON
  String toJson() => json.encode(toMap());

  /// Cria uma instância a partir de uma string JSON
  factory DadosVaga.fromJson(String source) => DadosVaga.fromMap(json.decode(source));

  @override
  String toString() {
    return 'DadosVaga(imediatas: $imediatas, cadastroReserva: $cadastroReserva, distribuicaoGeografica: $distribuicaoGeografica, totalConsolidado: $totalConsolidado)';
  }
}
