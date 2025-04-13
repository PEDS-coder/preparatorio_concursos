import 'interfaces/ia_service_interface.dart';
import 'gemini_service.dart';
import '../../utils/logger_adapter.dart';

/// Fábrica para criar instâncias de serviços de IA
class IAServiceFactory {
  // Singleton
  static final IAServiceFactory _instance = IAServiceFactory._internal();
  factory IAServiceFactory() => _instance;
  IAServiceFactory._internal();

  // Cache de instâncias
  final Map<String, IAServiceInterface> _instances = {};

  /// Cria ou retorna uma instância de serviço de IA
  IAServiceInterface createService(String apiType) {
    // Verificar se já existe uma instância para este tipo
    if (_instances.containsKey(apiType)) {
      return _instances[apiType]!;
    }

    // Criar uma nova instância
    IAServiceInterface service;
    switch (apiType.toLowerCase()) {
      case 'gemini':
        service = GeminiService();
        break;
      // Adicionar outros provedores aqui no futuro
      default:
        AppLogger.w('IAServiceFactory', 'Tipo de API desconhecido: $apiType. Usando Gemini como fallback.');
        service = GeminiService();
    }

    // Armazenar a instância no cache
    _instances[apiType] = service;
    return service;
  }

  /// Obtém o serviço padrão (Gemini)
  IAServiceInterface getDefaultService() {
    return createService('gemini');
  }

  /// Limpa o cache de instâncias
  void clearCache() {
    _instances.clear();
  }
}
