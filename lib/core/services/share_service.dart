import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/share_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

/// Serviço para compartilhamento de conteúdo
@singleton
class ShareService implements IShareService {
  static const String _tag = 'ShareService';

  final Logger _logger;
  final IAnalyticsService _analyticsService;

  /// Construtor
  ShareService(this._logger, this._analyticsService);

  /// Compartilha um plano de estudo
  Future<bool> sharePlanoEstudo(PlanoEstudo plano) async {
    try {
      // Criar texto para compartilhamento
      final text = _createPlanoEstudoText(plano);

      // Compartilhar texto
      await Share.share(
        text,
        subject: 'Meu Plano de Estudo: ${plano.titulo}',
      );

      // Registrar evento de compartilhamento
      _analyticsService.logEvent(
        name: 'share_plano_estudo',
        parameters: {'plano_id': plano.id},
      );

      _logger.info('Plano de estudo compartilhado', tag: _tag);

      return true;
    } catch (e) {
      _logger.error('Erro ao compartilhar plano de estudo', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao compartilhar plano de estudo');
      return false;
    }
  }

  /// Compartilha uma imagem
  Future<bool> shareImage(Uint8List imageBytes, {String? text, String? subject}) async {
    try {
      // Salvar imagem temporariamente
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_image.png');
      await file.writeAsBytes(imageBytes);

      // Compartilhar imagem
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject,
      );

      // Registrar evento de compartilhamento
      _analyticsService.logEvent(
        name: 'share_image',
        parameters: {'status': result.status.name},
      );

      _logger.info('Imagem compartilhada', tag: _tag);

      return true;
    } catch (e) {
      _logger.error('Erro ao compartilhar imagem', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao compartilhar imagem');
      return false;
    }
  }

  /// Compartilha um widget como imagem
  Future<bool> shareWidgetAsImage(GlobalKey<State<StatefulWidget>> key, {String? text, String? subject}) async {
    try {
      // Capturar widget como imagem
      final imageBytes = await _captureWidget(key);
      if (imageBytes == null) {
        return false;
      }

      // Compartilhar imagem
      return shareImage(imageBytes, text: text, subject: subject);
    } catch (e) {
      _logger.error('Erro ao compartilhar widget como imagem', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao compartilhar widget como imagem');
      return false;
    }
  }

  /// Compartilha um texto
  Future<bool> shareText(String text, {String? subject}) async {
    try {
      // Compartilhar texto
      await Share.share(
        text,
        subject: subject,
      );

      // Registrar evento de compartilhamento
      _analyticsService.logEvent(
        name: 'share_text',
        parameters: {'text_length': text.length},
      );

      _logger.info('Texto compartilhado', tag: _tag);

      return true;
    } catch (e) {
      _logger.error('Erro ao compartilhar texto', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao compartilhar texto');
      return false;
    }
  }

  /// Compartilha um arquivo
  Future<bool> shareFile(String filePath, {String? text, String? subject}) async {
    try {
      // Verificar se o arquivo existe
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.error('Arquivo não encontrado: $filePath', tag: _tag);
        return false;
      }

      // Compartilhar arquivo
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: text,
        subject: subject,
      );

      // Registrar evento de compartilhamento
      _analyticsService.logEvent(
        name: 'share_file',
        parameters: {
          'file_path': filePath,
          'status': result.status.name,
        },
      );

      _logger.info('Arquivo compartilhado', tag: _tag);

      return true;
    } catch (e) {
      _logger.error('Erro ao compartilhar arquivo', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao compartilhar arquivo');
      return false;
    }
  }

  /// Cria texto para compartilhamento de plano de estudo
  String _createPlanoEstudoText(PlanoEstudo plano) {
    final buffer = StringBuffer();

    // Título
    buffer.writeln('📚 MEU PLANO DE ESTUDO 📚');
    buffer.writeln('');

    // Informações do plano
    buffer.writeln('📋 ${plano.titulo}');
    buffer.writeln('📅 Período: ${_formatDate(plano.dataInicio)} a ${_formatDate(plano.dataFim)}');
    buffer.writeln('');

    // Matérias
    buffer.writeln('📕 MATÉRIAS:');
    for (final materia in plano.materias) {
      buffer.writeln('• ${materia.nome} (${materia.tipo})');
      buffer.writeln('  - Dias: ${materia.diasEstudo.join(", ")}');
      if (materia.questoes > 0) {
        buffer.writeln('  - Questões: ${materia.questoes}');
      }
      buffer.writeln('');
    }

    // Ferramentas
    if (plano.ferramentas.isNotEmpty) {
      buffer.writeln('🛠️ FERRAMENTAS DE ESTUDO:');
      for (final ferramenta in plano.ferramentas) {
        buffer.writeln('• $ferramenta');
      }
      buffer.writeln('');
    }

    // Recompensas
    if (plano.recompensas.isNotEmpty) {
      buffer.writeln('🏆 RECOMPENSAS:');
      for (final recompensa in plano.recompensas) {
        buffer.writeln('• ${recompensa.descricaoRecompensa} (${_formatTipoRecompensa(recompensa.tipoRecompensa)})');
      }
      buffer.writeln('');
    }

    // Rodapé
    buffer.writeln('Criado com o app Preparatório Concursos');

    return buffer.toString();
  }

  /// Formata uma data
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Formata o tipo de recompensa
  String _formatTipoRecompensa(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'diaria':
        return 'Diária';
      case 'semanal':
        return 'Semanal';
      case 'mensal':
        return 'Mensal';
      default:
        return tipo;
    }
  }

  /// Captura um widget como imagem
  Future<Uint8List?> _captureWidget(GlobalKey<State<StatefulWidget>> key) async {
    try {
      final renderObject = key.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        _logger.error('O widget não é um RenderRepaintBoundary', tag: _tag);
        return null;
      }

      final boundary = renderObject;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      _logger.error('Erro ao capturar widget como imagem', tag: _tag, error: e);
      return null;
    }
  }
}
