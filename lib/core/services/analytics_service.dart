import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para gerenciar analytics, crashlytics e telemetria de desempenho
@singleton
class AnalyticsService implements IAnalyticsService {
  static const String _tag = 'AnalyticsService';

  final Logger _logger;
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final FirebasePerformance _performance;

  /// Construtor
  AnalyticsService(this._logger) {
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _performance = FirebasePerformance.instance;
    _init();
  }

  /// Inicializa o serviço
  Future<void> _init() async {
    try {
      // Configurar o Crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Configurar o Analytics
      await _analytics.setAnalyticsCollectionEnabled(true);

      // Configurar o Performance Monitoring
      await _performance.setPerformanceCollectionEnabled(true);

      // Configurar o usuário anônimo
      await _analytics.setUserId(id: 'anonymous');

      _logger.info('Serviço de analytics inicializado', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao inicializar serviço de analytics', tag: _tag, error: e);
    }
  }

  /// Registra um evento de login
  Future<void> logLogin({required String method}) async {
    try {
      await _analytics.logLogin(loginMethod: method);
      _logger.debug('Evento de login registrado: $method', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento de login', tag: _tag, error: e);
    }
  }

  /// Registra um evento de logout
  Future<void> logLogout() async {
    try {
      await _analytics.logEvent(name: 'logout');
      _logger.debug('Evento de logout registrado', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento de logout', tag: _tag, error: e);
    }
  }

  /// Registra um evento de análise de edital
  Future<void> logEditalAnalysis({required String editalId, required bool success}) async {
    try {
      await _analytics.logEvent(
        name: 'edital_analysis',
        parameters: {
          'edital_id': editalId,
          'success': success,
        },
      );
      _logger.debug('Evento de análise de edital registrado: $editalId', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento de análise de edital', tag: _tag, error: e);
    }
  }

  /// Registra um evento de criação de plano de estudo
  Future<void> logPlanoEstudoCreation({required String planoId, required String editalId}) async {
    try {
      await _analytics.logEvent(
        name: 'plano_estudo_creation',
        parameters: {
          'plano_id': planoId,
          'edital_id': editalId,
        },
      );
      _logger.debug('Evento de criação de plano de estudo registrado: $planoId', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento de criação de plano de estudo', tag: _tag, error: e);
    }
  }

  /// Registra um evento de sessão de estudo
  Future<void> logEstudoSession({
    required String planoId,
    required String materiaId,
    required String assuntoId,
    required String ferramenta,
    required int duracao,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'estudo_session',
        parameters: {
          'plano_id': planoId,
          'materia_id': materiaId,
          'assunto_id': assuntoId,
          'ferramenta': ferramenta,
          'duracao': duracao,
        },
      );
      _logger.debug('Evento de sessão de estudo registrado: $materiaId', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento de sessão de estudo', tag: _tag, error: e);
    }
  }

  /// Registra um evento de compra de recompensa
  Future<void> logRecompensaPurchase({required String recompensaId, required int preco}) async {
    try {
      await _analytics.logEvent(
        name: 'recompensa_purchase',
        parameters: {
          'recompensa_id': recompensaId,
          'preco': preco,
        },
      );
      _logger.debug('Evento de compra de recompensa registrado: $recompensaId', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento de compra de recompensa', tag: _tag, error: e);
    }
  }

  /// Registra um evento personalizado
  Future<void> logEvent({required String name, Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      _logger.debug('Evento personalizado registrado: $name', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao registrar evento personalizado', tag: _tag, error: e);
    }
  }

  /// Registra um erro no Crashlytics
  Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason}) async {
    try {
      await _crashlytics.recordError(
        exception,
        stack,
        reason: reason,
        printDetails: true,
      );
      _logger.error('Erro registrado no Crashlytics', tag: _tag, error: exception);
    } catch (e) {
      _logger.error('Erro ao registrar erro no Crashlytics', tag: _tag, error: e);
    }
  }

  /// Define o usuário atual
  Future<void> setUser({required String userId, String? email, String? name}) async {
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);

      if (email != null) {
        await _crashlytics.setCustomKey('email', email);
      }

      if (name != null) {
        await _crashlytics.setCustomKey('name', name);
      }

      _logger.debug('Usuário definido: $userId', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao definir usuário', tag: _tag, error: e);
    }
  }

  /// Inicia uma trace de desempenho
  Trace startTrace(String name) {
    try {
      final trace = _performance.newTrace(name);
      trace.start();
      _logger.debug('Trace iniciada: $name', tag: _tag);
      return trace;
    } catch (e) {
      _logger.error('Erro ao iniciar trace', tag: _tag, error: e);
      throw e;
    }
  }

  /// Para uma trace de desempenho
  Future<void> stopTrace(Trace trace) async {
    try {
      await trace.stop();
      _logger.debug('Trace finalizada: ${trace.name}', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao finalizar trace', tag: _tag, error: e);
    }
  }

  /// Inicia uma métrica HTTP
  HttpMetric startHttpMetric(String url, HttpMethod method) {
    try {
      final metric = _performance.newHttpMetric(url, method);
      metric.start();
      _logger.debug('Métrica HTTP iniciada: $url', tag: _tag);
      return metric;
    } catch (e) {
      _logger.error('Erro ao iniciar métrica HTTP', tag: _tag, error: e);
      throw e;
    }
  }

  /// Para uma métrica HTTP
  Future<void> stopHttpMetric(HttpMetric metric, {int? responseCode, int? responseSize}) async {
    try {
      if (responseCode != null) {
        metric.httpResponseCode = responseCode;
      }

      if (responseSize != null) {
        metric.responsePayloadSize = responseSize;
      }

      await metric.stop();
      _logger.debug('Métrica HTTP finalizada: ${metric.url}', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao finalizar métrica HTTP', tag: _tag, error: e);
    }
  }
}
