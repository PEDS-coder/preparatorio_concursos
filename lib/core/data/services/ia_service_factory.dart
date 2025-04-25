import 'interfaces/ia_service_interface.dart';
import 'gemini_service.dart';
import 'gemini_official_service.dart';
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
      case 'gemini_official':
        service = GeminiOfficialService();
        break;
      // Adicionar outros provedores aqui no futuro
      default:
        AppLogger.w('IAServiceFactory', 'Tipo de API desconhecido: $apiType. Usando Gemini Official como fallback.');
        service = GeminiOfficialService();
    }

    // Armazenar a instância no cache
    _instances[apiType] = service;
    return service;
  }

  /// Obtém o serviço padrão (baseado na configuração)
  Future<IAServiceInterface> getDefaultService() async {
    // Temporariamente desativado o MCP devido a problemas de compatibilidade
    AppLogger.i('IAServiceFactory', 'Usando serviço Gemini Official');
    return createService('gemini_official');

    /* Código original com suporte a MCP (desativado temporariamente)
    // Verificar se o protocolo MCP está ativado
    final useMcp = await McpConfig.isMcpEnabled();

    // Retornar o serviço apropriado
    if (useMcp) {
      AppLogger.i('IAServiceFactory', 'Usando serviço MCP Gemini');
      return createService('mcp_gemini');
    } else {
      AppLogger.i('IAServiceFactory', 'Usando serviço Gemini Official');
      return createService('gemini_official');
    }
    */
  }

  /// Limpa o cache de instâncias
  void clearCache() {
    _instances.clear();
  }
}
