import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/ia_service.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/api_config_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/secure_storage_service_interface.dart';
import 'package:preparatorio_concursos/core/services/connectivity_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para gerenciar a configuração da API LLM (Gemini, OpenRouter ou Requestry)
@singleton
class ApiConfigService extends ChangeNotifier implements IApiConfigService {
  static const String _tag = 'ApiConfigService';
  static const String _apiKeyKey = 'api_key';
  static const String _apiTypeKey = 'api_type';
  static const String _apiModelKey = 'api_model';

  bool _isLlmConfigured = false;
  bool _isVerifyingConfig = false;
  bool _isValidated = false;
  String? _configErrorMessage;
  String? _apiModel;
  IAService? _iaService;
  final ISecureStorageService _secureStorage;
  final Logger _logger;

  @override
  bool get isConfigured => _isLlmConfigured;

  @override
  bool get isValidated => _isValidated;

  @override
  String get apiModel => _apiModel ?? 'gemini-2.5-pro-exp-03-25';

  bool get isVerifyingConfig => _isVerifyingConfig;
  String? get configErrorMessage => _configErrorMessage;

  ApiConfigService(this._secureStorage, this._logger) {
    _loadConfigStatus();
  }

  /// Define o serviço de IA para verificação proativa
  void setIAService(IAService iaService) {
    _iaService = iaService;
  }

  /// Carrega o status de configuração da API LLM
  Future<void> _loadConfigStatus() async {
    try {
      // Verificar configuração da API LLM
      final llmApiKey = await _secureStorage.getSecure(_apiKeyKey);
      final llmApiType = await _secureStorage.getSecure(_apiTypeKey);
      final apiModel = await _secureStorage.getSecure(_apiModelKey);

      _isLlmConfigured = llmApiKey != null && llmApiKey.isNotEmpty &&
                        llmApiType != null && llmApiType.isNotEmpty;

      _apiModel = apiModel;

      _logger.debug('Status de configuração da API LLM carregado: $_isLlmConfigured', tag: _tag);
      notifyListeners();
    } catch (e) {
      _logger.error('Erro ao carregar status de configuração da API LLM', tag: _tag, error: e);
      _isLlmConfigured = false;
      notifyListeners();
    }
  }

  /// Atualiza o status de configuração da API LLM
  Future<void> setLlmConfigured(bool isConfigured) async {
    _isLlmConfigured = isConfigured;
    _configErrorMessage = null;
    notifyListeners();
  }

  @override
  Future<bool> isApiConfigured() async {
    try {
      final apiKey = await _secureStorage.getSecure(_apiKeyKey);
      final apiType = await _secureStorage.getSecure(_apiTypeKey);

      return apiKey != null && apiKey.isNotEmpty &&
             apiType != null && apiType.isNotEmpty;
    } catch (e) {
      _logger.error('Erro ao verificar configuração da API', tag: _tag, error: e);
      return false;
    }
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _secureStorage.saveSecure(_apiKeyKey, apiKey);
      _logger.debug('Chave da API salva com sucesso', tag: _tag);

      // Verificar se o tipo da API já está configurado
      final apiType = await _secureStorage.getSecure(_apiTypeKey);
      if (apiType == null || apiType.isEmpty) {
        // Definir Gemini como padrão se não estiver configurado
        await _secureStorage.saveSecure(_apiTypeKey, 'gemini');
      }

      _isLlmConfigured = true;
      notifyListeners();
    } catch (e) {
      _logger.error('Erro ao salvar chave da API', tag: _tag, error: e);
      throw Exception('Erro ao salvar chave da API: $e');
    }
  }

  @override
  String? getApiKey() {
    try {
      return _secureStorage.getSecure(_apiKeyKey) as String?;
    } catch (e) {
      _logger.error('Erro ao obter chave da API', tag: _tag, error: e);
      return null;
    }
  }

  @override
  Future<void> clearApiKey() async {
    try {
      await _secureStorage.deleteSecure(_apiKeyKey);
      _logger.debug('Chave da API removida com sucesso', tag: _tag);
      _isLlmConfigured = false;
      _isValidated = false;
      notifyListeners();
    } catch (e) {
      _logger.error('Erro ao remover chave da API', tag: _tag, error: e);
      throw Exception('Erro ao remover chave da API: $e');
    }
  }

  @override
  Future<bool> isApiKeyValid(String apiKey) async {
    if (_iaService == null) {
      _logger.warning('Serviço de IA não inicializado', tag: _tag);
      return false;
    }

    try {
      // Obter o tipo de API atual
      final apiType = await _secureStorage.getSecure(_apiTypeKey) ?? 'gemini';

      // Verificar se o serviço da API está acessível
      bool serviceReachable = false;
      if (apiType == 'gemini') {
        serviceReachable = await ConnectivityService.canReachService('https://generativelanguage.googleapis.com');
      } else if (apiType == 'openrouter') {
        serviceReachable = await ConnectivityService.canReachService('https://openrouter.ai/api');
      } else if (apiType == 'requestry') {
        serviceReachable = await ConnectivityService.canReachService('https://api.requestry.com');
      }

      if (!serviceReachable) {
        _logger.warning('Serviço de IA inacessível', tag: _tag);
        return false;
      }

      // Testar a chave da API
      final result = await _iaService!.testApiKey(apiKey, apiType);
      return result;
    } catch (e) {
      _logger.error('Erro ao validar chave da API', tag: _tag, error: e);
      return false;
    }
  }

  @override
  Future<void> setApiModel(String model) async {
    try {
      await _secureStorage.saveSecure(_apiModelKey, model);
      _apiModel = model;
      _logger.debug('Modelo da API definido: $model', tag: _tag);
      notifyListeners();
    } catch (e) {
      _logger.error('Erro ao definir modelo da API', tag: _tag, error: e);
      throw Exception('Erro ao definir modelo da API: $e');
    }
  }

  /// Verifica proativamente se a configuração da API LLM está válida
  @override
  Future<bool> verificarConfiguracao() async {
    if (_iaService == null) {
      _configErrorMessage = 'Serviço de IA não inicializado';
      _logger.warning('Serviço de IA não inicializado', tag: _tag);
      notifyListeners();
      return false;
    }

    try {
      _isVerifyingConfig = true;
      _configErrorMessage = null;
      notifyListeners();

      // Verificar conectividade com a internet
      final bool isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        _isLlmConfigured = false;
        _configErrorMessage = 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
        _isVerifyingConfig = false;
        _logger.warning('Sem conexão com a internet', tag: _tag);
        notifyListeners();
        return false;
      }

      final apiKey = await _secureStorage.getSecure(_apiKeyKey);
      final apiType = await _secureStorage.getSecure(_apiTypeKey);

      if (apiKey == null || apiKey.isEmpty || apiType == null || apiType.isEmpty) {
        _isLlmConfigured = false;
        _configErrorMessage = 'API LLM não configurada';
        _isVerifyingConfig = false;
        _logger.warning('API LLM não configurada', tag: _tag);
        notifyListeners();
        return false;
      }

      // Verificar se o IAService já está configurado
      if (_iaService!.isConfigured && _iaService!.apiKey == apiKey && _iaService!.apiType == apiType) {
        _logger.info('API LLM já está configurada e válida', tag: _tag);
        _isLlmConfigured = true;
        _isValidated = true;
        _isVerifyingConfig = false;
        notifyListeners();
        return true;
      }

      // Verificar se a API key é válida
      _logger.debug('Verificando validade da API key: $apiType', tag: _tag);

      // Verificar se o serviço da API está acessível
      bool serviceReachable = false;
      if (apiType == 'gemini') {
        serviceReachable = await ConnectivityService.canReachService('https://generativelanguage.googleapis.com');
      } else if (apiType == 'openrouter') {
        serviceReachable = await ConnectivityService.canReachService('https://openrouter.ai/api');
      } else if (apiType == 'requestry') {
        serviceReachable = await ConnectivityService.canReachService('https://api.requestry.com');
      }

      if (!serviceReachable) {
        _isLlmConfigured = false;
        _isValidated = false;
        _configErrorMessage = 'Não foi possível acessar o serviço de IA. Verifique sua conexão com a internet.';
        _isVerifyingConfig = false;
        _logger.warning('Serviço de IA inacessível', tag: _tag);
        notifyListeners();
        return false;
      }

      final result = await _iaService!.setApiKey(apiKey, apiType);

      _isLlmConfigured = result['success'] as bool;
      _isValidated = _isLlmConfigured;

      if (!_isLlmConfigured) {
        _configErrorMessage = result['message'] as String;
        _logger.warning('API LLM inválida: ${_configErrorMessage}', tag: _tag);
      } else {
        _logger.info('API LLM validada com sucesso', tag: _tag);

        // Garantir que a chave seja salva no armazenamento seguro
        await _secureStorage.saveSecure(_apiKeyKey, apiKey);
        await _secureStorage.saveSecure(_apiTypeKey, apiType);

        // Salvar o modelo atual se estiver definido
        if (_apiModel != null) {
          await _secureStorage.saveSecure(_apiModelKey, _apiModel!);
        }
      }

      _isVerifyingConfig = false;
      notifyListeners();
      return _isLlmConfigured;
    } catch (e) {
      _isLlmConfigured = false;
      _isValidated = false;
      _configErrorMessage = 'Erro ao verificar configuração: $e';
      _isVerifyingConfig = false;
      _logger.error('Erro na verificação da API LLM', tag: _tag, error: e);
      notifyListeners();
      return false;
    }
  }
}
