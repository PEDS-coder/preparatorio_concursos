import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/interfaces/ia_service_interface.dart';
import '../data/services/interfaces/secure_storage_service_interface.dart';
import '../utils/logger.dart';
import 'connectivity_service.dart';

/// Serviço para gerenciar a configuração da API LLM (Gemini, OpenRouter ou Requestry)
class ApiConfigService extends ChangeNotifier {
  static const String _tag = 'ApiConfigService';

  bool _isLlmConfigured = false;
  bool _isVerifyingConfig = false;
  String? _configErrorMessage;
  IAServiceInterface? _iaService;

  // Controle de tentativas de validação
  int _validationAttempts = 0;
  static const int _maxValidationAttempts = 3;

  // Controle de timeout
  static const Duration _validationTimeout = Duration(seconds: 30);

  // Status detalhado da validação
  String _validationStatus = '';
  DateTime? _lastValidationTime;

  final ISecureStorageService _secureStorage;
  final Logger _logger;

  bool get isLlmConfigured => _isLlmConfigured;
  bool get isVerifyingConfig => _isVerifyingConfig;
  String? get configErrorMessage => _configErrorMessage;
  String get validationStatus => _validationStatus;
  DateTime? get lastValidationTime => _lastValidationTime;
  int get validationAttempts => _validationAttempts;

  ApiConfigService(this._secureStorage, this._logger) {
    // Apenas carregar o status, sem verificar a configuração
    _loadConfigStatusSilent();
  }

  /// Define o serviço de IA para verificação proativa
  void setIAService(IAServiceInterface iaService) {
    _iaService = iaService;
  }

  /// Carrega o status de configuração da API LLM (silenciosamente, sem notificar)
  Future<void> _loadConfigStatusSilent() async {
    try {
      // Verificar configuração da API LLM
      final llmApiKey = await _secureStorage.getSecure('api_key');
      final llmApiType = await _secureStorage.getSecure('api_type');
      _isLlmConfigured = llmApiKey != null && llmApiKey.isNotEmpty &&
                        llmApiType != null && llmApiType.isNotEmpty;

      // Não definir mensagem de erro ou status de validação aqui
      _validationStatus = '';
      _configErrorMessage = null;

      _logger.debug('Status de configuração da API LLM carregado: $_isLlmConfigured', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao carregar status de configuração da API LLM', tag: _tag, error: e);
      _isLlmConfigured = false;
      // Não definir mensagem de erro ou status de validação aqui
      _validationStatus = '';
      _configErrorMessage = null;
    }
    // Não notificar os ouvintes aqui
  }

  /// Carrega o status de configuração da API LLM e notifica os ouvintes
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

  /// Reseta o status de validação
  void resetValidationStatus() {
    _validationStatus = '';
    _configErrorMessage = null;
    _isVerifyingConfig = false;
    notifyListeners();
  }

  /// Verifica proativamente se a configuração da API LLM está válida
  Future<bool> verificarConfiguracao() async {
    if (_iaService == null) {
      _configErrorMessage = 'Serviço de IA não inicializado';
      _validationStatus = 'Falha: Serviço de IA não inicializado';
      notifyListeners();
      return false;
    }

    try {
      // Iniciar verificação
      _isVerifyingConfig = true;
      _configErrorMessage = null;
      _validationStatus = 'Iniciando verificação...';
      _validationAttempts = 0;
      notifyListeners();

      // Verificar conectividade com a internet
      _validationStatus = 'Verificando conectividade com a internet...';
      notifyListeners();

      final bool isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        _isLlmConfigured = false;
        _configErrorMessage = 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
        _validationStatus = 'Falha: Sem conexão com a internet';
        _isVerifyingConfig = false;
        _lastValidationTime = DateTime.now();
        notifyListeners();
        return false;
      }

      // Obter chave API e tipo
      _validationStatus = 'Obtendo configurações salvas...';
      notifyListeners();

      final apiKey = await _secureStorage.getSecure('api_key');
      final apiType = await _secureStorage.getSecure('api_type');
      _logger.debug('Verificando configuração da API LLM: $apiType', tag: _tag);

      if (apiKey == null || apiKey.isEmpty || apiType == null || apiType.isEmpty) {
        _isLlmConfigured = false;
        // Não definir mensagem de erro quando a API não está configurada
        // Isso é um estado válido na tela de configuração
        _configErrorMessage = null;
        _validationStatus = '';
        _isVerifyingConfig = false;
        _lastValidationTime = DateTime.now();
        notifyListeners();
        return false;
      }

      // Verificar se o IAService já está configurado
      if (_iaService!.isConfigured && _iaService!.apiKey == apiKey && _iaService!.apiType == apiType) {
        _logger.debug('API LLM já está configurada e válida', tag: _tag);

        // Realizar teste de conexão para garantir que a API ainda está funcionando
        _validationStatus = 'Testando conexão com a API...';
        notifyListeners();

        final bool isConnectionValid = await _testApiConnection(apiKey, apiType);
        if (!isConnectionValid) {
          _isLlmConfigured = false;
          _configErrorMessage = 'Falha na conexão com a API. Verifique sua chave e conexão com a internet.';
          _validationStatus = 'Falha: Teste de conexão falhou';
          _isVerifyingConfig = false;
          _lastValidationTime = DateTime.now();
          notifyListeners();
          return false;
        }

        _isLlmConfigured = true;
        _validationStatus = 'Sucesso: API já configurada e validada';
        _isVerifyingConfig = false;
        _lastValidationTime = DateTime.now();
        notifyListeners();
        return true;
      }

      // Verificar se a API key é válida
      _logger.debug('Verificando validade da API key: $apiType', tag: _tag);
      _validationStatus = 'Verificando validade da chave API...';
      notifyListeners();

      // Verificar se o serviço da API está acessível
      _validationStatus = 'Verificando disponibilidade do serviço...';
      notifyListeners();

      bool serviceReachable = false;
      if (apiType == 'gemini' || apiType == 'gemini_official') {
        serviceReachable = await ConnectivityService.canReachService('https://generativelanguage.googleapis.com');
      } else if (apiType == 'openrouter') {
        serviceReachable = await ConnectivityService.canReachService('https://openrouter.ai/api');
      } else if (apiType == 'requestry') {
        serviceReachable = await ConnectivityService.canReachService('https://api.requestry.com');
      }

      if (!serviceReachable) {
        _isLlmConfigured = false;
        _configErrorMessage = 'Não foi possível acessar o serviço de IA. Verifique sua conexão com a internet.';
        _validationStatus = 'Falha: Serviço de IA inacessível';
        _isVerifyingConfig = false;
        _lastValidationTime = DateTime.now();
        notifyListeners();
        return false;
      }

      // Configurar a chave API com retry
      _validationStatus = 'Configurando chave API...';
      notifyListeners();

      Map<String, dynamic> result = {'success': false, 'message': 'Não foi possível validar a chave API'};

      // Implementar retry com backoff exponencial
      for (_validationAttempts = 1; _validationAttempts <= _maxValidationAttempts; _validationAttempts++) {
        try {
          _validationStatus = 'Tentativa $_validationAttempts de $_maxValidationAttempts...';
          notifyListeners();

          // Usar timeout para evitar bloqueio indefinido
          result = await _executeWithTimeout(
            () => _iaService!.setApiKey(apiKey, apiType),
            _validationTimeout,
            'Timeout ao validar chave API'
          );

          // Se for bem-sucedido, sair do loop
          if (result['success'] as bool) {
            break;
          }

          // Se não for a última tentativa, aguardar antes de tentar novamente
          if (_validationAttempts < _maxValidationAttempts) {
            // Backoff exponencial: 1s, 2s, 4s, etc.
            final waitTime = Duration(seconds: 1 << (_validationAttempts - 1));
            _validationStatus = 'Aguardando ${waitTime.inSeconds}s antes da próxima tentativa...';
            notifyListeners();
            await Future.delayed(waitTime);
          }
        } catch (e) {
          _logger.error('Erro na tentativa $_validationAttempts: $e', tag: _tag);

          // Se for a última tentativa, propagar o erro
          if (_validationAttempts >= _maxValidationAttempts) {
            rethrow;
          }

          // Aguardar antes de tentar novamente
          final waitTime = Duration(seconds: 1 << (_validationAttempts - 1));
          _validationStatus = 'Erro: $e. Aguardando ${waitTime.inSeconds}s antes da próxima tentativa...';
          notifyListeners();
          await Future.delayed(waitTime);
        }
      }

      _isLlmConfigured = result['success'] as bool;
      if (!_isLlmConfigured) {
        _configErrorMessage = result['message'] as String;
        _validationStatus = 'Falha: ${result['message']}';
        _logger.warning('API LLM inválida: $_configErrorMessage', tag: _tag);
      } else {
        _logger.debug('API LLM validada com sucesso', tag: _tag);
        _validationStatus = 'Sucesso: API validada com sucesso';

        // Garantir que a chave seja salva no armazenamento seguro
        await _secureStorage.saveSecure('api_key', apiKey);
        await _secureStorage.saveSecure('api_type', apiType);

        // Salvar timestamp da última validação bem-sucedida
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_api_validation', DateTime.now().toIso8601String());
      }

      _isVerifyingConfig = false;
      _lastValidationTime = DateTime.now();
      notifyListeners();
      return _isLlmConfigured;
    } catch (e) {
      _isLlmConfigured = false;
      _configErrorMessage = 'Erro ao verificar configuração: $e';
      _validationStatus = 'Erro: $e';
      _isVerifyingConfig = false;
      _lastValidationTime = DateTime.now();
      _logger.error('Erro na verificação da API LLM', tag: _tag, error: e);
      notifyListeners();
      return false;
    }
  }

  /// Testa a conexão com a API usando a chave fornecida
  Future<bool> _testApiConnection(String apiKey, String apiType) async {
    try {
      _logger.debug('Testando conexão com a API: $apiType', tag: _tag);
      _logger.debug('Chave API: ${apiKey.length} caracteres', tag: _tag);
      _logger.debug('Prefixo da chave: ${apiKey.substring(0, apiKey.length > 5 ? 5 : apiKey.length)}...', tag: _tag);

      if (apiKey.isEmpty) {
        _logger.error('Chave API vazia', tag: _tag);
        return false;
      }

      if (apiType == 'gemini_official' && !apiKey.startsWith('AI')) {
        _logger.error('Formato de chave API inválido para Gemini: não começa com "AI"', tag: _tag);
        _logger.debug('Prefixo real: ${apiKey.substring(0, apiKey.length > 2 ? 2 : apiKey.length)}', tag: _tag);
      }

      // Usar timeout para evitar bloqueio indefinido
      final bool isValid = await _executeWithTimeout(
        () => _iaService!.testApiKey(apiKey, apiType),
        _validationTimeout,
        'Timeout ao testar conexão com a API'
      );

      _logger.debug('Teste de conexão com a API: ${isValid ? 'Sucesso' : 'Falha'}', tag: _tag);
      return isValid;
    } catch (e) {
      _logger.error('Erro ao testar conexão com a API', tag: _tag, error: e);
      return false;
    }
  }

  /// Executa uma função com timeout
  Future<T> _executeWithTimeout<T>(Future<T> Function() function, Duration timeout, String timeoutMessage) async {
    try {
      return await function().timeout(timeout, onTimeout: () {
        throw Exception(timeoutMessage);
      });
    } catch (e) {
      _logger.error('Erro ao executar função com timeout: $e', tag: _tag);
      rethrow;
    }
  }
}
