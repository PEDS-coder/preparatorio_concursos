import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/performance_interfaces.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Implementação local do serviço de analytics que usa apenas logs
/// Esta é uma substituição temporária para o Firebase Analytics, Crashlytics e Performance
@singleton
class LocalAnalyticsService implements IAnalyticsService {
  static const String _tag = 'LocalAnalyticsService';

  final Logger _logger;

  /// Construtor
  LocalAnalyticsService(this._logger) {
    _init();
  }

  /// Inicializa o serviço
  Future<void> _init() async {
    _logger.info('Serviço de analytics local inicializado', tag: _tag);
  }

  /// Registra um evento de login
  @override
  Future<void> logLogin({required String method}) async {
    _logger.info('Evento de login registrado: $method', tag: _tag);
  }

  /// Registra um evento de análise de edital
  @override
  Future<void> logEditalAnalysis({
    required String editalId,
    required bool success,
  }) async {
    _logger.info(
      'Evento de análise de edital registrado: $editalId (Sucesso: $success)',
      tag: _tag,
    );
  }

  /// Registra um evento de logout
  @override
  Future<void> logLogout() async {
    _logger.info('Evento de logout registrado', tag: _tag);
  }

  /// Registra um evento de criação de plano
  @override
  Future<void> logPlanoEstudoCreation({
    required String planoId,
    required String editalId,
  }) async {
    _logger.info(
      'Evento de criação de plano registrado: $planoId (Edital: $editalId)',
      tag: _tag,
    );
  }

  /// Registra um evento de sessão de estudo
  @override
  Future<void> logEstudoSession({
    required String planoId,
    required String materiaId,
    required String assuntoId,
    required String ferramenta,
    required int duracao,
  }) async {
    _logger.info(
      'Evento de sessão de estudo registrado: $materiaId (Plano: $planoId, Assunto: $assuntoId, Ferramenta: $ferramenta, Duração: ${duracao}min)',
      tag: _tag,
    );
  }

  /// Registra um evento de compra de recompensa
  @override
  Future<void> logRecompensaPurchase({
    required String recompensaId,
    required int preco,
  }) async {
    _logger.info(
      'Evento de compra de recompensa registrado: $recompensaId (Preço: $preco moedas)',
      tag: _tag,
    );
  }

  /// Registra um evento personalizado
  @override
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    _logger.info(
      'Evento personalizado registrado: $name ${parameters != null ? '($parameters)' : ''}',
      tag: _tag,
    );
  }

  /// Registra um erro
  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
  }) async {
    _logger.error(
      'Erro registrado: ${reason ?? 'Sem razão especificada'}',
      tag: _tag,
      error: exception,
      stackTrace: stack,
    );
  }

  /// Define o usuário atual
  @override
  Future<void> setUser({
    required String userId,
    String? email,
    String? name,
  }) async {
    _logger.info(
      'Usuário definido: $userId ${email != null ? '($email)' : ''} ${name != null ? '[$name]' : ''}',
      tag: _tag,
    );
  }

  /// Inicia uma trace de desempenho
  @override
  Trace startTrace(String name) {
    _logger.debug('Trace iniciada: $name', tag: _tag);
    final trace = LocalTrace(name, this);
    trace.start();
    return trace;
  }

  /// Para uma trace de desempenho
  @override
  Future<void> stopTrace(Trace trace) async {
    if (trace is LocalTrace) {
      await trace.stop();
    }
  }

  /// Inicia uma métrica HTTP
  @override
  HttpMetric startHttpMetric(String url, AppHttpMethod method) {
    _logger.debug('Métrica HTTP iniciada: ${method.name} $url', tag: _tag);
    final metric = LocalHttpMetric(url, method, this);
    metric.start();
    return metric;
  }

  /// Para uma métrica HTTP
  @override
  Future<void> stopHttpMetric(HttpMetric metric, {int? responseCode, int? responseSize}) async {
    if (metric is LocalHttpMetric) {
      if (responseCode != null) {
        metric.setHttpResponseCode(responseCode);
      }

      if (responseSize != null) {
        metric.setResponsePayloadSize(responseSize);
      }

      await metric.stop();
    }
  }
}

/// Implementação local de uma trace de desempenho
class LocalTrace implements Trace {
  @override
  final String name;
  final LocalAnalyticsService _service;
  DateTime? _startTime;
  DateTime? _endTime;

  LocalTrace(this.name, this._service);

  @override
  void start() {
    _startTime = DateTime.now();
  }

  @override
  Future<void> stop() async {
    _endTime = DateTime.now();
    final duration = _endTime!.difference(_startTime!);
    _service._logger.debug('Trace finalizada: $name (${duration.inMilliseconds}ms)', tag: 'LocalTrace');
  }

  /// Para a trace e retorna a duração (método interno)
  Duration stopAndGetDuration() {
    _endTime = DateTime.now();
    return _endTime!.difference(_startTime!);
  }
}

/// Implementação local de uma métrica HTTP
class LocalHttpMetric implements HttpMetric {
  @override
  final String url;
  @override
  final AppHttpMethod method;
  final LocalAnalyticsService _service;
  DateTime? _startTime;
  DateTime? _endTime;
  int? _httpResponseCode;
  int? _requestPayloadSize;
  int? _responsePayloadSize;
  String? _responseContentType;

  LocalHttpMetric(this.url, this.method, this._service);

  @override
  void start() {
    _startTime = DateTime.now();
  }

  @override
  Future<void> stop() async {
    _endTime = DateTime.now();
    final duration = _endTime!.difference(_startTime!);
    _service._logger.debug(
      'Métrica HTTP finalizada: ${method.name} $url (${duration.inMilliseconds}ms, Status: $_httpResponseCode)',
      tag: 'LocalHttpMetric',
    );
  }

  /// Define o código de resposta HTTP
  @override
  void setHttpResponseCode(int responseCode) {
    _httpResponseCode = responseCode;
  }

  /// Define o tamanho do payload da requisição
  @override
  void setRequestPayloadSize(int bytes) {
    _requestPayloadSize = bytes;
  }

  /// Define o tamanho do payload da resposta
  @override
  void setResponsePayloadSize(int bytes) {
    _responsePayloadSize = bytes;
  }

  /// Define o tipo de conteúdo da resposta
  @override
  void setResponseContentType(String contentType) {
    _responseContentType = contentType;
  }

  /// Para a métrica e retorna a duração (método interno)
  Duration stopAndGetDuration() {
    _endTime = DateTime.now();
    return _endTime!.difference(_startTime!);
  }
}
