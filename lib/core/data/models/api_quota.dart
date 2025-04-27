import 'package:flutter/foundation.dart';

/// Modelo para rastrear o uso de cotas da API Gemini
class ApiQuota {
  // Contadores de uso
  int _requestsPerMinute = 0;
  int _requestsPerDay = 0;
  int _tokensPerMinute = 0;
  int _tokensPerDay = 0;

  // Timestamps para resetar contadores
  DateTime _lastMinuteReset = DateTime.now();
  DateTime _lastDayReset = DateTime.now();

  // Limites da API Gemini
  static const int MAX_REQUESTS_PER_MINUTE = 5;
  static const int MAX_REQUESTS_PER_DAY = 25;
  static const int MAX_TOKENS_PER_MINUTE = 250000;
  static const int MAX_TOKENS_PER_DAY = 1000000;

  // Getters para contadores
  int get requestsPerMinute => _requestsPerMinute;
  int get requestsPerDay => _requestsPerDay;
  int get tokensPerMinute => _tokensPerMinute;
  int get tokensPerDay => _tokensPerDay;

  // Setters para contadores (para uso interno e pelo ApiQuotaService)
  set requestsPerMinute(int value) => _requestsPerMinute = value;
  set requestsPerDay(int value) => _requestsPerDay = value;
  set tokensPerMinute(int value) => _tokensPerMinute = value;
  set tokensPerDay(int value) => _tokensPerDay = value;

  // Getters e setters para timestamps
  DateTime get lastMinuteReset => _lastMinuteReset;
  set lastMinuteReset(DateTime value) => _lastMinuteReset = value;

  DateTime get lastDayReset => _lastDayReset;
  set lastDayReset(DateTime value) => _lastDayReset = value;

  // Getters para limites restantes
  int get remainingRequestsPerMinute => MAX_REQUESTS_PER_MINUTE - _requestsPerMinute;
  int get remainingRequestsPerDay => MAX_REQUESTS_PER_DAY - _requestsPerDay;
  int get remainingTokensPerMinute => MAX_TOKENS_PER_MINUTE - _tokensPerMinute;
  int get remainingTokensPerDay => MAX_TOKENS_PER_DAY - _tokensPerDay;

  // Getters para porcentagem de uso
  double get requestsPerMinutePercentage => _requestsPerMinute / MAX_REQUESTS_PER_MINUTE;
  double get requestsPerDayPercentage => _requestsPerDay / MAX_REQUESTS_PER_DAY;
  double get tokensPerMinutePercentage => _tokensPerMinute / MAX_TOKENS_PER_MINUTE;
  double get tokensPerDayPercentage => _tokensPerDay / MAX_TOKENS_PER_DAY;

  // Singleton
  static final ApiQuota _instance = ApiQuota._internal();
  factory ApiQuota() => _instance;
  ApiQuota._internal();

  /// Registra uma nova requisição e estima o uso de tokens
  void registerRequest({int estimatedTokens = 1000}) {
    _checkAndResetCounters();

    _requestsPerMinute++;
    _requestsPerDay++;
    _tokensPerMinute += estimatedTokens;
    _tokensPerDay += estimatedTokens;

    debugPrint('API Quota: $_requestsPerMinute/$MAX_REQUESTS_PER_MINUTE req/min, $_requestsPerDay/$MAX_REQUESTS_PER_DAY req/day');
    debugPrint('Token Usage: $_tokensPerMinute/$MAX_TOKENS_PER_MINUTE tokens/min, $_tokensPerDay/$MAX_TOKENS_PER_DAY tokens/day');
  }

  /// Verifica se os contadores precisam ser resetados
  void _checkAndResetCounters() {
    final now = DateTime.now();

    // Resetar contadores por minuto
    if (now.difference(_lastMinuteReset).inMinutes >= 1) {
      _requestsPerMinute = 0;
      _tokensPerMinute = 0;
      _lastMinuteReset = now;
      debugPrint('API Quota: Contadores por minuto resetados');
    }

    // Resetar contadores por dia
    if (now.difference(_lastDayReset).inHours >= 24) {
      _requestsPerDay = 0;
      _tokensPerDay = 0;
      _lastDayReset = now;
      debugPrint('API Quota: Contadores por dia resetados');
    }
  }

  /// Verifica se algum limite foi excedido
  bool isQuotaExceeded() {
    _checkAndResetCounters();
    return _requestsPerMinute >= MAX_REQUESTS_PER_MINUTE ||
           _requestsPerDay >= MAX_REQUESTS_PER_DAY ||
           _tokensPerMinute >= MAX_TOKENS_PER_MINUTE ||
           _tokensPerDay >= MAX_TOKENS_PER_DAY;
  }

  /// Reseta todos os contadores (útil para testes)
  void resetAllCounters() {
    _requestsPerMinute = 0;
    _requestsPerDay = 0;
    _tokensPerMinute = 0;
    _tokensPerDay = 0;
    _lastMinuteReset = DateTime.now();
    _lastDayReset = DateTime.now();
    debugPrint('API Quota: Todos os contadores resetados');
  }
}
