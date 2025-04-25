import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
import '../../../../core/utils/plano_data_logger.dart';
import 'extrator_dados_service.dart';

/// Serviço para gerenciamento do calendário e sessões de estudo
class CalendarioService {
  final PlanoEstudoService _planoService;
  final ExtratorDadosService _extratoService;
  final PlanoDataLogger _logger = PlanoDataLogger();

  CalendarioService(this._planoService, this._extratoService);

  /// Gera sessões de estudo para o plano
  Future<void> gerarSessoesEstudo(PlanoEstudo plano, Function(PlanoEstudo) onSessoesGeradas) async {
    // Permitir regenerar sessões mesmo se já existirem
    // if (plano.sessoesEstudo.isNotEmpty) return;

    _logger.logApresentacao(plano.id, 'gerando_sessoes_estudo', 'Gerando sessões de estudo para o plano');

    try {
      // Gerar sessões de estudo para o plano
      final sessoes = await _planoService.gerarSessoesParaPlano(plano.id);
      if (sessoes.isNotEmpty) {
        // Recarregar o plano com as novas sessões
        final planoAtualizado = _planoService.getPlanoById(plano.id);
        if (planoAtualizado != null) {
          _logger.logApresentacao(plano.id, 'sessoes_geradas', {
            'total_sessoes': planoAtualizado.sessoesEstudo.length,
            'total_dias': _agruparSessoesPorDia(planoAtualizado.sessoesEstudo).length,
          });

          onSessoesGeradas(planoAtualizado);
        }
      } else {
        _logger.logApresentacao(plano.id, 'erro_gerar_sessoes', 'Nenhuma sessão gerada. Verifique as horas semanais configuradas.');
      }
    } catch (e) {
      _logger.logApresentacao(plano.id, 'erro_gerar_sessoes', 'Falha ao gerar sessões de estudo: $e');
    }
  }

  /// Agrupa sessões de estudo por dia
  Map<DateTime, List<SessaoEstudo>> agruparSessoesPorDia(List<SessaoEstudo> sessoes) {
    return _agruparSessoesPorDia(sessoes);
  }

  /// Método interno para agrupar sessões por dia
  Map<DateTime, List<SessaoEstudo>> _agruparSessoesPorDia(List<SessaoEstudo> sessoes) {
    final Map<DateTime, List<SessaoEstudo>> sessoesPorDia = {};

    for (final sessao in sessoes) {
      final dataKey = DateTime(
        sessao.dataHoraInicio.year,
        sessao.dataHoraInicio.month,
        sessao.dataHoraInicio.day,
      );

      if (!sessoesPorDia.containsKey(dataKey)) {
        sessoesPorDia[dataKey] = [];
      }

      sessoesPorDia[dataKey]!.add(sessao);
    }

    return sessoesPorDia;
  }

  /// Obtém as cores dos marcadores para um dia específico
  List<Color> getMarkerColors(DateTime day, Map<DateTime, List<SessaoEstudo>> sessoesPorDia) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final sessoes = sessoesPorDia[normalizedDay] ?? [];

    if (sessoes.isEmpty) return [];

    // Obter cores únicas para cada matéria no dia
    Set<Color> cores = {};
    for (var sessao in sessoes) {
      cores.add(_extratoService.getColorForMateria(sessao.materia));
    }

    return cores.toList();
  }

  /// Sincroniza o plano com o Google Calendar
  Future<bool> sincronizarComGoogleCalendar(PlanoEstudo plano) async {
    // Implementação da sincronização com o Google Calendar
    // Esta é uma implementação de exemplo, que deve ser substituída pela implementação real
    _logger.logApresentacao(plano.id, 'sincronizacao_google_calendar', 'Sincronizando com Google Calendar');

    // Simulação de sincronização bem-sucedida
    await Future.delayed(const Duration(seconds: 2));

    _logger.logApresentacao(plano.id, 'sincronizacao_google_calendar_concluida', {
      'total_sessoes': plano.sessoesEstudo.length,
      'resultado': 'sucesso',
    });

    return true;
  }

  /// Sincroniza o plano com o Apple Calendar
  Future<bool> sincronizarComAppleCalendar(PlanoEstudo plano) async {
    // Implementação da sincronização com o Apple Calendar
    // Esta é uma implementação de exemplo, que deve ser substituída pela implementação real
    _logger.logApresentacao(plano.id, 'sincronizacao_apple_calendar', 'Sincronizando com Apple Calendar');

    // Simulação de sincronização bem-sucedida
    await Future.delayed(const Duration(seconds: 2));

    _logger.logApresentacao(plano.id, 'sincronizacao_apple_calendar_concluida', {
      'total_sessoes': plano.sessoesEstudo.length,
      'resultado': 'sucesso',
    });

    return true;
  }
}
