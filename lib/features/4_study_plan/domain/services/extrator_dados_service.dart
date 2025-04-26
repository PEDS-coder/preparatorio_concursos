import 'package:flutter/material.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/plano_data_logger.dart';
import 'extrator_utils.dart';
import 'extrator_models.dart';
import 'extractors/metadados_extractor.dart';
import 'extractors/dados_extraidos_extractor.dart';
import 'extractors/dados_prova_extractor.dart';
import 'extractors/dados_originais_extractor.dart';
import 'materia_color_service.dart';

/// Serviço para extração de dados do edital e plano
class ExtratorDadosService {
  final PlanoDataLogger _logger = PlanoDataLogger();

  /// Método genérico para busca de campos
  String buscarCampo(PlanoEstudo plano, Edital? edital, ChaveBusca chaveBusca) {
    // Primeiro, tentar com a chave principal
    String resultado = _buscarComFallback(
      plano,
      edital,
      chaveBusca.chaveMetadados,
      chaveBusca.chaveDadosOriginais,
      chaveBusca.eventoLog
    );

    // Se não encontrou e há alternativas de chaves originais, tentar com elas
    if (resultado == 'Não informado' && chaveBusca.alternativasOriginais.isNotEmpty) {
      debugPrint('  Tentando alternativas de chaves originais: ${chaveBusca.alternativasOriginais}');

      for (final alternativa in chaveBusca.alternativasOriginais) {
        final resultadoAlternativo = _buscarComFallback(
          plano,
          edital,
          chaveBusca.chaveMetadados,
          alternativa,
          '${chaveBusca.eventoLog}_alternativa'
        );

        if (resultadoAlternativo != 'Não informado') {
          debugPrint('  Encontrado com alternativa: $alternativa');
          return resultadoAlternativo;
        }
      }
    }

    return resultado;
  }

  /// Método privado que implementa a lógica de busca com fallback
  String _buscarComFallback(
    PlanoEstudo plano,
    Edital? edital,
    String chaveMetadados,
    String chaveDadosOriginais,
    String eventoLog
  ) {
    _logger.logRecuperacao(plano.id, eventoLog, {
      'chave_metadados': chaveMetadados,
      'chave_dados_originais': chaveDadosOriginais,
    });
    debugPrint('\nVERIFICAÇÃO DE EXIBIÇÃO - Buscando: $chaveMetadados / $chaveDadosOriginais');

    // 1. Busca em metadados exatos ou alternativos
    final resMeta = MetadadosExtractor.buscarExato(plano, chaveMetadados) ??
                   MetadadosExtractor.buscarAlternativo(plano, chaveMetadados);
    if (resMeta != null) {
      final valor = ExtratorUtils.formatarSeFormato(chaveMetadados, resMeta.valor);
      _logger.logRecuperacao(plano.id, 'valor_encontrado_metadados', {
        'chave': resMeta.caminho,
        'valor': valor,
        'origem': 'metadados_plano',
      });
      debugPrint('  Encontrado nos metadados (${resMeta.caminho}): $valor');
      return valor;
    }

    // 2. Busca em metadados aninhados
    final resMetaAninhados = MetadadosExtractor.buscarAninhado(plano, chaveMetadados);
    if (resMetaAninhados != null) {
      final valor = ExtratorUtils.formatarSeFormato(chaveMetadados, resMetaAninhados.valor);
      _logger.logRecuperacao(plano.id, 'valor_encontrado_metadados_aninhados', {
        'chave': resMetaAninhados.caminho,
        'valor': valor,
        'origem': 'metadados_plano',
      });
      debugPrint('  Encontrado nos metadados aninhados (${resMetaAninhados.caminho}): $valor');
      return valor;
    }

    // 3. Busca em dados extraídos
    final resDadosExtraidos = DadosExtraidosExtractor.buscar(edital, chaveMetadados);
    if (resDadosExtraidos != null) {
      final valor = ExtratorUtils.formatarSeFormato(chaveMetadados, resDadosExtraidos.valor);
      _logger.logRecuperacao(plano.id, 'valor_encontrado_dados_extraidos', {
        'chave': resDadosExtraidos.caminho,
        'valor': valor,
        'origem': 'dados_extraidos',
      });
      debugPrint('  Encontrado nos dados extraídos (${resDadosExtraidos.caminho}): $valor');

      // Armazenar nos metadados do plano para uso futuro
      plano.metadados[chaveMetadados] = valor;

      return valor;
    }

    // 4. Busca em dados da prova
    final resDadosProva = DadosProvaExtractor.buscar(edital, chaveMetadados);
    if (resDadosProva != null) {
      final valor = ExtratorUtils.formatarSeFormato(chaveMetadados, resDadosProva.valor);
      _logger.logRecuperacao(plano.id, 'valor_encontrado_dados_prova', {
        'chave': resDadosProva.caminho,
        'valor': valor,
        'origem': 'dados_prova',
      });
      debugPrint('  Encontrado nos dados da prova (${resDadosProva.caminho}): $valor');

      // Armazenar nos metadados do plano para uso futuro
      plano.metadados[chaveMetadados] = valor;

      return valor;
    }

    // 5. Busca em dados originais
    final resDadosOriginais = DadosOriginaisExtractor.buscar(edital, chaveMetadados, chaveDadosOriginais);
    if (resDadosOriginais != null) {
      final valor = ExtratorUtils.formatarSeFormato(chaveMetadados, resDadosOriginais.valor);
      _logger.logRecuperacao(plano.id, 'valor_encontrado_dados_originais', {
        'chave': resDadosOriginais.caminho,
        'valor': valor,
        'origem': 'dados_originais',
      });
      debugPrint('  Encontrado nos dados originais (${resDadosOriginais.caminho}): $valor');

      // Armazenar nos metadados do plano para uso futuro
      plano.metadados[chaveMetadados] = valor;

      return valor;
    }

    debugPrint('  Não encontrado em nenhum lugar. Retornando valor padrão.');
    return 'Não informado';
  }

  /// Obtém emoji para o tipo de informação
  String getEmojiForInfoType(String label) {
    final labelLower = label.toLowerCase();

    switch (labelLower) {
      case 'período de inscrições':
      case 'data da prova':
        return '📅';
      case 'nome':
      case 'título':
        return '📝';
      case 'órgão':
        return '🏢';
      case 'banca':
        return '👨‍⚖️';
      case 'cargo':
        return '👔';
      case 'vagas':
        return '🎯';
      case 'local das provas':
        return '🏫';
      case 'cotas':
        return '♿';
      case 'taxa de inscrição':
        return '💰';
      case 'salário':
        return '💵';
      case 'escolaridade':
      case 'nível':
        return '🎓';
      case 'total de questões':
        return '❓';
      case 'formato':
        return '📋';
      case 'duração':
        return '⏱️';
      case 'critérios de aprovação':
        return '✅';
      case 'critérios de reprovação':
        return '❌';
      case 'critérios de desempate':
        return '🔄';
      case 'tema da prova subjetiva':
        return '📄';
      default:
        return '📌';
    }
  }

  /// Obtém cor para o tipo de informação
  Color getColorForInfoType(String label) {
    final labelLower = label.toLowerCase();

    switch (labelLower) {
      case 'período de inscrições':
      case 'data da prova':
        return Colors.red;
      case 'nome':
      case 'título':
      case 'órgão':
      case 'banca':
        return Colors.blue;
      case 'cargo':
        return Colors.purple;
      case 'vagas':
        return Colors.orange;
      case 'local das provas':
        return Colors.orange;
      case 'cotas':
        return Colors.purple;
      case 'taxa de inscrição':
      case 'salário':
        return Colors.green;
      case 'escolaridade':
      case 'nível':
        return Colors.orange;
      case 'total de questões':
        return Colors.blue;
      case 'formato':
        return Colors.purple;
      case 'duração':
        return Colors.orange;
      case 'critérios de aprovação':
        return Colors.green;
      case 'critérios de reprovação':
        return Colors.red;
      case 'critérios de desempate':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Obtém cor para a matéria
  Color getColorForMateria(String nomeMateria) => MateriaColorService.getColorForMateria(nomeMateria);
}
