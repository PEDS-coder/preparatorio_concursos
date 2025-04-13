/// Interface para o serviço de configuração de API
abstract class IApiConfigService {
  /// Verifica se a API está configurada
  Future<bool> isApiConfigured();

  /// Verifica a configuração da API
  Future<bool> verificarConfiguracao();

  /// Salva a chave da API
  Future<void> saveApiKey(String apiKey);

  /// Obtém a chave da API
  String? getApiKey();

  /// Limpa a chave da API
  Future<void> clearApiKey();

  /// Verifica se a chave da API é válida
  Future<bool> isApiKeyValid(String apiKey);

  /// Obtém o status da configuração da API
  bool get isConfigured;

  /// Obtém o status da validação da API
  bool get isValidated;

  /// Obtém o modelo da API configurado
  String get apiModel;

  /// Define o modelo da API
  Future<void> setApiModel(String model);
}
