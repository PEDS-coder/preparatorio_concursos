/// Classe base para todos os modelos de dados
abstract class BaseModel {
  /// Converte o modelo para um Map
  Map<String, dynamic> toMap();
  
  /// Método para criar uma cópia do objeto com algumas propriedades alteradas
  BaseModel copyWith();
}
