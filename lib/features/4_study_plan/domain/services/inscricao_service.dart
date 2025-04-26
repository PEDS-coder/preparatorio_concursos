import 'package:flutter/foundation.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/formatador_service.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';

/// Serviço para obtenção de dados da inscrição
class InscricaoService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();

  /// Obtém o valor da inscrição
  static String obterValor(PlanoEstudo plano, Edital? edital) {
    debugPrint('\nInscricaoService.obterValor - Buscando valor da inscrição');

    // Primeiro, tentar usar o extrator padrão
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.VALOR_INSCRICAO);

    // Se não encontrou e temos um edital, tentar buscar diretamente
    if (resultado == 'Não informado' && edital != null && edital.dadosOriginais != null) {
      debugPrint('  Não encontrado pelo extrator padrão, tentando buscar diretamente...');

      // Verificar se há dados de inscrição no objeto concurso
      if (edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map) {
          debugPrint('  Chaves em concurso.inscricoes: ${inscricoes.keys.toList()}');

          if (inscricoes.containsKey('taxa')) {
            resultado = inscricoes['taxa'].toString();
            debugPrint('  Encontrado em concurso.inscricoes.taxa: $resultado');

            // Armazenar nos metadados do plano para uso futuro
            plano.metadados['valorInscricao'] = resultado;

            return resultado;
          }
        }
      }

      // Verificar se há dados de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('inscricoes') &&
          edital.dadosOriginais!['inscricoes'] is Map) {

        final inscricoes = edital.dadosOriginais!['inscricoes'] as Map;
        debugPrint('  Chaves em inscricoes: ${inscricoes.keys.toList()}');

        if (inscricoes.containsKey('taxa')) {
          resultado = inscricoes['taxa'].toString();
          debugPrint('  Encontrado em inscricoes.taxa: $resultado');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['valorInscricao'] = resultado;

          return resultado;
        }
      }

      // Verificar se há taxa de inscrição diretamente nos dados extraídos
      if (edital.dadosExtraidos.taxaInscricao != null) {
        resultado = edital.dadosExtraidos.taxaInscricao.toString();
        debugPrint('  Encontrado em dadosExtraidos.taxaInscricao: $resultado');

        // Armazenar nos metadados do plano para uso futuro
        plano.metadados['valorInscricao'] = resultado;

        return resultado;
      }

      // Verificar se há taxa de inscrição na estrutura aninhada
      if (edital.dadosExtraidos.concurso != null &&
          edital.dadosExtraidos.concurso!.containsKey('inscricoes') &&
          edital.dadosExtraidos.concurso!['inscricoes'] is Map) {

        final inscricoes = edital.dadosExtraidos.concurso!['inscricoes'] as Map;
        debugPrint('  Verificando em dadosExtraidos.concurso.inscricoes: ${inscricoes.keys.toList()}');

        if (inscricoes.containsKey('taxa')) {
          resultado = inscricoes['taxa'].toString();
          debugPrint('  Encontrado em dadosExtraidos.concurso.inscricoes.taxa: $resultado');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['valorInscricao'] = resultado;

          return resultado;
        }
      }

      // Verificar se há taxa de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('taxa_inscricao')) {
        resultado = edital.dadosOriginais!['taxa_inscricao'].toString();
        debugPrint('  Encontrado em dadosOriginais.taxa_inscricao: $resultado');

        // Armazenar nos metadados do plano para uso futuro
        plano.metadados['valorInscricao'] = resultado;

        return resultado;
      }
    }

    return resultado;
  }

  /// Obtém o período de inscrições
  static String obterPeriodo(Edital? edital) {
    if (edital == null) return 'Não informado';

    debugPrint('\nInscricaoService.obterPeriodo - Buscando período de inscrição');

    // Verificar se há dados de inscrição no edital
    final inicio = edital.dadosExtraidos.inicioInscricao;
    final fim = edital.dadosExtraidos.fimInscricao;

    if (inicio != null && fim != null) {
      // Formatar as datas no formato dd/MM/yyyy
      final inicioFormatado = '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}';
      final fimFormatado = '${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}/${fim.year}';
      debugPrint('  Encontrado em dadosExtraidos: $inicioFormatado a $fimFormatado');
      return '$inicioFormatado a $fimFormatado';
    }

    // Verificar se há período de inscrição diretamente nos dados extraídos
    if (edital.dadosExtraidos.periodoInscricaoInicio != null &&
        edital.dadosExtraidos.periodoInscricaoFim != null) {
      final resultado = '${edital.dadosExtraidos.periodoInscricaoInicio} a ${edital.dadosExtraidos.periodoInscricaoFim}';
      debugPrint('  Encontrado em periodoInscricaoInicio/Fim: $resultado');
      return resultado;
    }

    // Verificar se há período de inscrição como string única
    if (edital.dadosExtraidos.concurso != null &&
        edital.dadosExtraidos.concurso!.containsKey('inscricoes') &&
        edital.dadosExtraidos.concurso!['inscricoes'] is Map) {

      final inscricoes = edital.dadosExtraidos.concurso!['inscricoes'] as Map;
      debugPrint('  Verificando em dadosExtraidos.concurso.inscricoes: ${inscricoes.keys.toList()}');

      if (inscricoes.containsKey('periodo')) {
        final resultado = inscricoes['periodo'].toString();
        debugPrint('  Encontrado em dadosExtraidos.concurso.inscricoes.periodo: $resultado');
        return resultado;
      }
    }

    // Tentar obter dos dados originais
    if (edital.dadosOriginais != null) {
      debugPrint('  Verificando dados originais...');

      // Verificar se há dados de inscrição no objeto concurso
      if (edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map) {
          debugPrint('  Chaves em concurso.inscricoes: ${inscricoes.keys.toList()}');

          // Verificar se há período formatado
          if (inscricoes.containsKey('periodo')) {
            debugPrint('  Encontrado em concurso.inscricoes.periodo: ${inscricoes['periodo']}');
            return inscricoes['periodo'];
          }

          // Verificar se há início e fim separados
          if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
            final resultado = '${inscricoes['inicio']} a ${inscricoes['fim']}';
            debugPrint('  Encontrado em concurso.inscricoes.inicio/fim: $resultado');
            return resultado;
          }
        }
      }

      // Verificar se há dados de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('inscricoes') && edital.dadosOriginais!['inscricoes'] is Map) {
        final inscricoes = edital.dadosOriginais!['inscricoes'] as Map;
        debugPrint('  Chaves em inscricoes: ${inscricoes.keys.toList()}');

        // Verificar se há período formatado
        if (inscricoes.containsKey('periodo')) {
          debugPrint('  Encontrado em inscricoes.periodo: ${inscricoes['periodo']}');
          return inscricoes['periodo'];
        }

        // Verificar se há início e fim separados
        if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
          final resultado = '${inscricoes['inicio']} a ${inscricoes['fim']}';
          debugPrint('  Encontrado em inscricoes.inicio/fim: $resultado');
          return resultado;
        }
      }

      // Verificar se há período de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('periodo_inscricao')) {
        if (edital.dadosOriginais!['periodo_inscricao'] is String) {
          return edital.dadosOriginais!['periodo_inscricao'];
        } else if (edital.dadosOriginais!['periodo_inscricao'] is Map) {
          final periodoInscricao = edital.dadosOriginais!['periodo_inscricao'] as Map;
          if (periodoInscricao.containsKey('inicio') && periodoInscricao.containsKey('fim')) {
            return '${periodoInscricao['inicio']} a ${periodoInscricao['fim']}';
          }
        }
      }
    }

    return 'Não informado';
  }
}
