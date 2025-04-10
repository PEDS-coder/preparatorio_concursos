import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar a configuração da API LLM (Gemini ou OpenAI)
class ApiConfigService extends ChangeNotifier {
  bool _isLlmConfigured = false;

  bool get isLlmConfigured => _isLlmConfigured;

  ApiConfigService() {
    _loadConfigStatus();
  }

  /// Carrega o status de configuração da API LLM
  Future<void> _loadConfigStatus() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar configuração da API LLM
    final llmApiKey = prefs.getString('api_key');
    final llmApiType = prefs.getString('api_type');
    _isLlmConfigured = llmApiKey != null && llmApiKey.isNotEmpty &&
                      llmApiType != null && llmApiType.isNotEmpty;

    notifyListeners();
  }

  /// Atualiza o status de configuração da API LLM
  Future<void> setLlmConfigured(bool isConfigured) async {
    _isLlmConfigured = isConfigured;
    notifyListeners();
  }
}
