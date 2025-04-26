import 'package:flutter/foundation.dart';
import '../../../../core/data/models/models.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';
import 'formatador_service.dart';

/// Serviço para obtenção de dados da prova
class ProvaService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();

  /// Obtém o formato da prova
  static String obterFormato(PlanoEstudo plano, Edital? edital) {
    String formato = _extrator.buscarCampo(plano, edital, ChavesBusca.FORMATO_PROVA);
    return _formatarFormatoProva(formato);
  }

  /// Formata o formato da prova para exibição padronizada
  static String _formatarFormatoProva(String formato) {
    if (formato == 'Não informado') return formato;

    // Converter para minúsculo para padronização
    String formatoLower = formato.toLowerCase();

    // Dividir por vírgulas ou outros separadores comuns
    List<String> formatos = formatoLower.split(RegExp(r'[,;/]'));

    // Limpar e capitalizar cada formato
    formatos = formatos.map((f) => f.trim()).where((f) => f.isNotEmpty).toList();
    formatos = formatos.map((f) => f[0].toUpperCase() + f.substring(1)).toList();

    // Juntar com "e" para o último item e vírgulas para os demais
    if (formatos.length == 1) {
      return formatos[0];
    } else if (formatos.length == 2) {
      return '${formatos[0]} e ${formatos[1]}';
    } else {
      String resultado = '';
      for (int i = 0; i < formatos.length; i++) {
        if (i == formatos.length - 1) {
          resultado += ' e ${formatos[i]}';
        } else if (i == formatos.length - 2) {
          resultado += formatos[i];
        } else {
          resultado += '${formatos[i]}, ';
        }
      }
      return resultado;
    }
  }

  /// Padroniza o estilo de escrita das informações
  static String _padronizarEstilo(String texto) {
    return FormatadorService.padronizarEstiloEscrita(texto);
  }

  /// Obtém a data da prova
  static String obterData(PlanoEstudo plano, Edital? edital) {
    // Usar o extrator para buscar a data da prova
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.DATA_PROVA);

    // Se não encontrou, verificar diretamente no edital
    if (resultado == 'Não informado' && edital != null) {
      // Verificar se há dados da prova no objeto concurso
      if (edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {

        final prova = edital.dadosOriginais!['concurso']['prova'];
        if (prova is Map && prova.containsKey('data')) {
          resultado = prova['data'].toString();
        }
      }

      // Verificar se há dados da prova diretamente nos dados originais
      if (resultado == 'Não informado' &&
          edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('prova') &&
          edital.dadosOriginais!['prova'] is Map) {

        final prova = edital.dadosOriginais!['prova'] as Map;
        if (prova.containsKey('data')) {
          resultado = prova['data'].toString();
        }
      }
    }

    return _padronizarEstilo(resultado);
  }

  /// Obtém o local da prova
  static String obterLocal(PlanoEstudo plano, Edital? edital) {
    // Usar o extrator para buscar o local da prova
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.LOCAL_PROVA);

    // Se não encontrou, verificar diretamente no edital
    if (resultado == 'Não informado' && edital != null) {
      // Verificar se há dados da prova no objeto concurso
      if (edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {

        final prova = edital.dadosOriginais!['concurso']['prova'];
        if (prova is Map && prova.containsKey('local')) {
          resultado = prova['local'].toString();
        }
      }

      // Verificar se há dados da prova diretamente nos dados originais
      if (resultado == 'Não informado' &&
          edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('prova') &&
          edital.dadosOriginais!['prova'] is Map) {

        final prova = edital.dadosOriginais!['prova'] as Map;
        if (prova.containsKey('local')) {
          resultado = prova['local'].toString();
        }
      }
    }

    return _padronizarEstilo(resultado);
  }

  /// Obtém o total de questões da prova
  static String obterTotalQuestoes(PlanoEstudo plano, Edital? edital) {
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.TOTAL_QUESTOES);
    return _padronizarEstilo(resultado);
  }

  /// Obtém a duração da prova
  static String obterDuracao(PlanoEstudo plano, Edital? edital) {
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.DURACAO_PROVA);
    return _padronizarEstilo(resultado);
  }

  /// Obtém os critérios de aprovação da prova
  static String obterCriteriosAprovacao(PlanoEstudo plano, Edital? edital) {
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.CRITERIOS_APROVACAO);
    return _padronizarEstilo(resultado);
  }

  /// Obtém os critérios de reprovação da prova
  static String obterCriteriosReprovacao(PlanoEstudo plano, Edital? edital) {
    debugPrint('\nProvaService.obterCriteriosReprovacao - Buscando critérios de reprovação');

    // Primeiro, tentar usar o extrator padrão
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.CRITERIOS_REPROVACAO);

    // Se não encontrou e temos um edital, tentar buscar diretamente
    if (resultado == 'Não informado' && edital != null && edital.dadosOriginais != null) {
      debugPrint('  Não encontrado pelo extrator padrão, tentando buscar diretamente...');

      // Verificar se há dados da prova no objeto concurso
      if (edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('prova')) {

        final prova = edital.dadosOriginais!['concurso']['prova'];
        if (prova is Map) {
          debugPrint('  Chaves em concurso.prova: ${prova.keys.toList()}');

          if (prova.containsKey('criterios_reprovacao')) {
            resultado = prova['criterios_reprovacao'].toString();
            debugPrint('  Encontrado em concurso.prova.criterios_reprovacao: $resultado');

            // Armazenar nos metadados do plano para uso futuro
            plano.metadados['criteriosReprovacao'] = resultado;

            return resultado;
          }
        }
      }

      // Verificar se há dados da prova diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('prova') &&
          edital.dadosOriginais!['prova'] is Map) {

        final prova = edital.dadosOriginais!['prova'] as Map;
        debugPrint('  Chaves em prova: ${prova.keys.toList()}');

        if (prova.containsKey('criterios_reprovacao')) {
          resultado = prova['criterios_reprovacao'].toString();
          debugPrint('  Encontrado em prova.criterios_reprovacao: $resultado');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['criteriosReprovacao'] = resultado;

          return resultado;
        }
      }

      // Verificar se há critérios de reprovação diretamente nos dados extraídos
      if (edital.dadosExtraidos.criteriosReprovacao != null) {
        resultado = edital.dadosExtraidos.criteriosReprovacao!;
        debugPrint('  Encontrado em dadosExtraidos.criteriosReprovacao: $resultado');

        // Armazenar nos metadados do plano para uso futuro
        plano.metadados['criteriosReprovacao'] = resultado;

        return resultado;
      }

      // Verificar se há critérios de reprovação na estrutura aninhada
      if (edital.dadosExtraidos.concurso != null &&
          edital.dadosExtraidos.concurso!.containsKey('prova') &&
          edital.dadosExtraidos.concurso!['prova'] is Map) {

        final prova = edital.dadosExtraidos.concurso!['prova'] as Map;
        debugPrint('  Verificando em dadosExtraidos.concurso.prova: ${prova.keys.toList()}');

        if (prova.containsKey('criterios_reprovacao')) {
          resultado = prova['criterios_reprovacao'].toString();
          debugPrint('  Encontrado em dadosExtraidos.concurso.prova.criterios_reprovacao: $resultado');

          // Armazenar nos metadados do plano para uso futuro
          plano.metadados['criteriosReprovacao'] = resultado;

          return _padronizarEstilo(resultado);
        }
      }
    }

    return resultado;
  }

  /// Obtém os critérios de desempate da prova
  static String obterCriteriosDesempate(PlanoEstudo plano, Edital? edital) {
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.CRITERIOS_DESEMPATE);
    return _padronizarEstilo(resultado);
  }

  /// Obtém o tema da prova subjetiva
  static String obterTemaProvaSubjetiva(PlanoEstudo plano, Edital? edital) {
    String resultado = _extrator.buscarCampo(plano, edital, ChavesBusca.TEMA_PROVA_SUBJETIVA);
    return _padronizarEstilo(resultado);
  }
}
