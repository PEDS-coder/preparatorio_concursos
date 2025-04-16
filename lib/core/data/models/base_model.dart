/// Classe base para todos os modelos de dados
abstract class BaseModel {
  /// Converte o modelo para um Map
  Map<String, dynamic> toMap();

  /// Converte o modelo para JSON
  Map<String, dynamic> toJson() => toMap();

  /// Método para criar uma cópia do objeto com algumas propriedades alteradas
  BaseModel copyWith();
}
