import 'dart:convert';

/// Modelo para armazenar informações sobre cotas em concursos
class Cota {
  /// Nome da cota (ex: "Pessoas com Deficiência", "Negros", etc.)
  final String nome;
  
  /// Percentual de vagas reservadas para a cota (ex: 20.0 para 20%)
  final double? percentual;
  
  /// Número absoluto de vagas reservadas para a cota
  final int? numeroVagas;
  
  /// Critérios para concorrer à cota
  final String? criterios;

  Cota({
    required this.nome,
    this.percentual,
    this.numeroVagas,
    this.criterios,
  });

  /// Cria uma instância a partir de um mapa
  factory Cota.fromMap(Map<String, dynamic> map) {
    double? percentualValue;
    if (map['percentual'] != null) {
      if (map['percentual'] is int) {
        percentualValue = (map['percentual'] as int).toDouble();
      } else if (map['percentual'] is double) {
        percentualValue = map['percentual'];
      } else if (map['percentual'] is String) {
        percentualValue = double.tryParse(map['percentual']);
      }
    }
    
    return Cota(
      nome: map['nome'] ?? 'Não informado',
      percentual: percentualValue,
      numeroVagas: map['numero_vagas'] is int ? map['numero_vagas'] : null,
      criterios: map['criterios'],
    );
  }

  /// Converte a instância para um mapa
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'percentual': percentual,
      'numero_vagas': numeroVagas,
      'criterios': criterios,
    };
  }

  /// Converte a instância para uma string JSON
  String toJson() => json.encode(toMap());

  /// Cria uma instância a partir de uma string JSON
  factory Cota.fromJson(String source) => Cota.fromMap(json.decode(source));

  @override
  String toString() {
    String result = nome;
    if (percentual != null) {
      result += ' (${percentual!.toStringAsFixed(1)}%)';
    } else if (numeroVagas != null) {
      result += ' ($numeroVagas vagas)';
    }
    return result;
  }
}
