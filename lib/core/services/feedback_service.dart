import 'dart:convert';
import 'dart:io';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/feedback_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/remote_config_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para gerenciar o feedback do usuário
@singleton
class FeedbackService implements IFeedbackService {
  static const String _tag = 'FeedbackService';

  final Logger _logger;
  final IAnalyticsService _analyticsService;
  final IRemoteConfigService _remoteConfigService;

  /// Construtor
  FeedbackService(this._logger, this._analyticsService, this._remoteConfigService);

  /// Inicializa o serviço de feedback
  BetterFeedback initFeedback() {
    return BetterFeedback.of(
      theme: FeedbackThemeData(
        background: Colors.grey[800]!,
        feedbackSheetColor: Colors.grey[900]!,
        drawColors: [
          Colors.red,
          Colors.green,
          Colors.blue,
          Colors.yellow,
          Colors.purple,
          Colors.orange,
        ],
      ),
      child: Container(),
    );
  }

  /// Mostra o formulário de feedback
  void showFeedback(BuildContext context) {
    if (!_remoteConfigService.isFeatureEnabled('feedback')) {
      _logger.debug('Feedback desabilitado nas configurações remotas', tag: _tag);
      return;
    }

    try {
      BetterFeedback.of(context).show((feedback) {
        _sendFeedback(feedback);
      });

      _logger.debug('Formulário de feedback exibido', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao exibir formulário de feedback', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao exibir formulário de feedback');
    }
  }

  /// Envia o feedback para o servidor
  Future<void> _sendFeedback(UserFeedback feedback) async {
    try {
      final trace = _analyticsService.startTrace('send_feedback');

      // Registrar evento de feedback
      _analyticsService.logEvent(
        name: 'feedback_submitted',
        parameters: {
          'feedback_type': 'user_feedback',
          'has_screenshot': feedback.screenshot != null,
        },
      );

      // Enviar feedback para o servidor
      // TODO: Substituir pela URL real do servidor de feedback
      final url = _remoteConfigService.getString('feedback_url');
      if (url.isEmpty) {
        _logger.warning('URL de feedback não configurada', tag: _tag);
        _analyticsService.stopTrace(trace);
        return;
      }

      final metric = _analyticsService.startHttpMetric(url, HttpMethod.post);

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'text': feedback.text,
          'screenshot': feedback.screenshot != null
              ? base64Encode(feedback.screenshot!)
              : null,
          'extra': feedback.extra,
        }),
      );

      _analyticsService.stopHttpMetric(
        metric,
        responseCode: response.statusCode,
        responseSize: response.bodyBytes.length,
      );

      if (response.statusCode != 200) {
        throw HttpException('Erro ao enviar feedback: ${response.statusCode}');
      }

      _logger.info('Feedback enviado com sucesso', tag: _tag);
      _analyticsService.stopTrace(trace);
    } catch (e) {
      _logger.error('Erro ao enviar feedback', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao enviar feedback');
    }
  }
}
