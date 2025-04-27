import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/api_quota.dart';

/// Serviço para gerenciar o uso de cotas da API
class ApiQuotaService {
  final ApiQuota _apiQuota = ApiQuota();

  // Chaves para SharedPreferences
  static const String _keyRequestsPerMinute = 'api_requests_per_minute';
  static const String _keyRequestsPerDay = 'api_requests_per_day';
  static const String _keyTokensPerMinute = 'api_tokens_per_minute';
  static const String _keyTokensPerDay = 'api_tokens_per_day';
  static const String _keyLastMinuteReset = 'api_last_minute_reset';
  static const String _keyLastDayReset = 'api_last_day_reset';

  // Singleton
  static final ApiQuotaService _instance = ApiQuotaService._internal();
  factory ApiQuotaService() => _instance;
  ApiQuotaService._internal();

  /// Inicializa o serviço carregando dados salvos
  Future<void> init() async {
    try {
      await _loadSavedData();
    } catch (e) {
      debugPrint('ApiQuotaService: Erro ao inicializar - $e');
    }
  }

  /// Registra uma nova requisição à API
  Future<void> registerApiRequest({int estimatedTokens = 1000}) async {
    _apiQuota.registerRequest(estimatedTokens: estimatedTokens);
    await _saveData();
  }

  /// Verifica se algum limite de cota foi excedido
  bool isQuotaExceeded() {
    return _apiQuota.isQuotaExceeded();
  }

  /// Obtém o objeto ApiQuota para consulta
  ApiQuota get quota => _apiQuota;

  /// Carrega dados salvos do SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Verificar se os contadores precisam ser resetados
    final now = DateTime.now();

    final lastMinuteResetStr = prefs.getString(_keyLastMinuteReset);
    final lastDayResetStr = prefs.getString(_keyLastDayReset);

    DateTime lastMinuteReset = lastMinuteResetStr != null
        ? DateTime.parse(lastMinuteResetStr)
        : now;

    DateTime lastDayReset = lastDayResetStr != null
        ? DateTime.parse(lastDayResetStr)
        : now;

    // Resetar contadores por minuto se necessário
    if (now.difference(lastMinuteReset).inMinutes >= 1) {
      await prefs.setInt(_keyRequestsPerMinute, 0);
      await prefs.setInt(_keyTokensPerMinute, 0);
      await prefs.setString(_keyLastMinuteReset, now.toIso8601String());
      debugPrint('ApiQuotaService: Contadores por minuto resetados');
    }

    // Resetar contadores por dia se necessário
    if (now.difference(lastDayReset).inHours >= 24) {
      await prefs.setInt(_keyRequestsPerDay, 0);
      await prefs.setInt(_keyTokensPerDay, 0);
      await prefs.setString(_keyLastDayReset, now.toIso8601String());
      debugPrint('ApiQuotaService: Contadores por dia resetados');
    }

    // Carregar valores atuais
    _apiQuota.requestsPerMinute = prefs.getInt(_keyRequestsPerMinute) ?? 0;
    _apiQuota.requestsPerDay = prefs.getInt(_keyRequestsPerDay) ?? 0;
    _apiQuota.tokensPerMinute = prefs.getInt(_keyTokensPerMinute) ?? 0;
    _apiQuota.tokensPerDay = prefs.getInt(_keyTokensPerDay) ?? 0;
    _apiQuota.lastMinuteReset = lastMinuteReset;
    _apiQuota.lastDayReset = lastDayReset;

    debugPrint('ApiQuotaService: Dados carregados - ${_apiQuota.requestsPerMinute}/${ApiQuota.MAX_REQUESTS_PER_MINUTE} req/min, ${_apiQuota.requestsPerDay}/${ApiQuota.MAX_REQUESTS_PER_DAY} req/day');
  }

  /// Salva os dados atuais no SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt(_keyRequestsPerMinute, _apiQuota.requestsPerMinute);
      await prefs.setInt(_keyRequestsPerDay, _apiQuota.requestsPerDay);
      await prefs.setInt(_keyTokensPerMinute, _apiQuota.tokensPerMinute);
      await prefs.setInt(_keyTokensPerDay, _apiQuota.tokensPerDay);
      await prefs.setString(_keyLastMinuteReset, _apiQuota.lastMinuteReset.toIso8601String());
      await prefs.setString(_keyLastDayReset, _apiQuota.lastDayReset.toIso8601String());
    } catch (e) {
      debugPrint('ApiQuotaService: Erro ao salvar dados - $e');
    }
  }

  /// Reseta todos os contadores (útil para testes)
  Future<void> resetAllCounters() async {
    _apiQuota.resetAllCounters();
    await _saveData();
  }
}
