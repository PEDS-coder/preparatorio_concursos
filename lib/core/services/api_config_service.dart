import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/ia_service.dart';
import '../data/services/interfaces/secure_storage_service_interface.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';

/// Serviço para gerenciar a configuração da API LLM (Gemini, OpenRouter ou Requestry)
class ApiConfigService extends ChangeNotifier {
  static const String _tag = 'ApiConfigService';

  bool _isLlmConfigured = false;
  bool _isVerifyingConfig = false;
  String? _configErrorMessage;
  IAService? _iaService;

  final ISecureStorageService _secureStorage;
  final Logger _logger;

  bool get isLlmConfigured => _isLlmConfigured;
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
      final llmApiKey = await _secureStorage.getSecure('api_key');
      final llmApiType = await _secureStorage.getSecure('api_type');
      _isLlmConfigured = llmApiKey != null && llmApiKey.isNotEmpty &&
                        llmApiType != null && llmApiType.isNotEmpty;

      _logger.debug('Status de configuração da API LLM carregado: $_isLlmConfigured', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao carregar status de configuração da API LLM', tag: _tag, error: e);
      _isLlmConfigured = false;
    } finally {
      notifyListeners();
    }
  }

  /// Atualiza o status de configuração da API LLM
  Future<void> setLlmConfigured(bool isConfigured) async {
    _isLlmConfigured = isConfigured;
    _configErrorMessage = null;
    notifyListeners();
  }

  /// Verifica proativamente se a configuração da API LLM está válida
  Future<bool> verificarConfiguracao() async {
    if (_iaService == null) {
      _configErrorMessage = 'Serviço de IA não inicializado';
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
        notifyListeners();
        return false;
      }

      final apiKey = await _secureStorage.getSecure('api_key');
      final apiType = await _secureStorage.getSecure('api_type');
      _logger.debug('Verificando configuração da API LLM: $apiType', tag: _tag);

      if (apiKey == null || apiKey.isEmpty || apiType == null || apiType.isEmpty) {
        _isLlmConfigured = false;
        _configErrorMessage = 'API LLM não configurada';
        _isVerifyingConfig = false;
        notifyListeners();
        return false;
      }

      // Verificar se o IAService já está configurado
      if (_iaService!.isConfigured && _iaService!.apiKey == apiKey && _iaService!.apiType == apiType) {
        _logger.debug('API LLM já está configurada e válida', tag: _tag);
        _isLlmConfigured = true;
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
        _configErrorMessage = 'Não foi possível acessar o serviço de IA. Verifique sua conexão com a internet.';
        _isVerifyingConfig = false;
        notifyListeners();
        return false;
      }

      final result = await _iaService!.setApiKey(apiKey, apiType);

      _isLlmConfigured = result['success'] as bool;
      if (!_isLlmConfigured) {
        _configErrorMessage = result['message'] as String;
        _logger.warning('API LLM inválida: ${_configErrorMessage}', tag: _tag);
      } else {
        _logger.debug('API LLM validada com sucesso', tag: _tag);

        // Garantir que a chave seja salva no armazenamento seguro
        await _secureStorage.saveSecure('api_key', apiKey);
        await _secureStorage.saveSecure('api_type', apiType);
      }

      _isVerifyingConfig = false;
      notifyListeners();
      return _isLlmConfigured;
    } catch (e) {
      _isLlmConfigured = false;
      _configErrorMessage = 'Erro ao verificar configuração: $e';
      _isVerifyingConfig = false;
      _logger.error('Erro na verificação da API LLM', tag: _tag, error: e);
      notifyListeners();
      return false;
    }
  }
}
