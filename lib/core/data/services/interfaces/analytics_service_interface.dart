import 'package:preparatorio_concursos/core/data/services/interfaces/http_method.dart';
import 'package:preparatorio_concursos/core/mocks/firebase_mocks.dart';

/// Interface para o serviço de analytics
abstract class IAnalyticsService {
  /// Registra um evento de login
  Future<void> logLogin({required String method});

  /// Registra um evento de logout
  Future<void> logLogout();

  /// Registra um evento de análise de edital
  Future<void> logEditalAnalysis({required String editalId, required bool success});

  /// Registra um evento de criação de plano de estudo
  Future<void> logPlanoEstudoCreation({required String planoId, required String editalId});

  /// Registra um evento de sessão de estudo
  Future<void> logEstudoSession({
    required String planoId,
    required String materiaId,
    required String assuntoId,
    required String ferramenta,
    required int duracao,
  });

  /// Registra um evento de compra de recompensa
  Future<void> logRecompensaPurchase({required String recompensaId, required int preco});

  /// Registra um evento personalizado
  Future<void> logEvent({required String name, Map<String, dynamic>? parameters});

  /// Registra um erro no Crashlytics
  Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason});

  /// Define o usuário atual
  Future<void> setUser({required String userId, String? email, String? name});

  /// Inicia uma trace de desempenho
  Trace startTrace(String name);

  /// Para uma trace de desempenho
  Future<void> stopTrace(Trace trace);

  /// Inicia uma métrica HTTP
  HttpMetric startHttpMetric(String url, AppHttpMethod method);

  /// Para uma métrica HTTP
  Future<void> stopHttpMetric(HttpMetric metric, {int? responseCode, int? responseSize});
}
