import 'package:flutter/foundation.dart';
import '../../../../../core/data/models/models.dart';
import '../extrator_models.dart';
import '../extrator_utils.dart';

/// Extrator de dados dos dados extraídos do edital
class DadosExtraidosExtractor {
  /// Busca um valor nos dados extraídos do edital
  static ResultadoBusca? buscar(Edital? edital, String chave) {
    if (edital == null) return null;

    final de = edital.dadosExtraidos;
    String? valor;
    String caminho = '';

    // Log para depuração
    debugPrint('\nDadosExtraidosExtractor - Buscando: $chave');

    // Verificar se há dados na estrutura aninhada
    if (de.concurso != null) {
      debugPrint('  Chaves em concurso: ${de.concurso!.keys.toList()}');

      // Verificar se há dados de inscrição
      if (de.concurso!.containsKey('inscricoes') && de.concurso!['inscricoes'] is Map) {
        debugPrint('  Chaves em concurso.inscricoes: ${(de.concurso!['inscricoes'] as Map).keys.toList()}');
      }

      // Verificar se há dados de prova
      if (de.concurso!.containsKey('prova') && de.concurso!['prova'] is Map) {
        debugPrint('  Chaves em concurso.prova: ${(de.concurso!['prova'] as Map).keys.toList()}');
      }
    }

    switch (chave) {
      case 'titulo':
        valor = de.titulo;
        caminho = 'dadosExtraidos.titulo';
        break;
      case 'orgao':
        valor = de.orgao;
        caminho = 'dadosExtraidos.orgao';
        break;
      case 'banca':
        valor = de.banca;
        caminho = 'dadosExtraidos.banca';
        break;
      case 'dataProva':
        if (de.dataProva != null) {
          // Verificar se é um objeto DateTime ou uma string
          if (de.dataProva is DateTime) {
            // Formatar a data no padrão brasileiro
            final dataObj = de.dataProva as DateTime;
            final dia = dataObj.day.toString().padLeft(2, '0');
            final mes = dataObj.month.toString().padLeft(2, '0');
            final ano = dataObj.year.toString();
            valor = '$dia/$mes/$ano';
          } else {
            // Se for uma string, usar diretamente
            valor = de.dataProva.toString();
          }
          caminho = 'dadosExtraidos.dataProva';
        } else if (de.prova != null && de.prova!.containsKey('data')) {
          valor = de.prova!['data'].toString();
          caminho = 'dadosExtraidos.prova.data';
        }
        break;
      case 'localProva':
        if (de.localProva != null && de.localProva!.isNotEmpty) {
          valor = de.localProva;
          caminho = 'dadosExtraidos.localProva';
        } else if (de.prova != null && de.prova!.containsKey('local')) {
          valor = de.prova!['local'].toString();
          caminho = 'dadosExtraidos.prova.local';
        }
        break;
      case 'valorInscricao':
        if (de.valorTaxa != null) {
          valor = de.valorTaxa.toString();
          caminho = 'dadosExtraidos.valorTaxa';
          debugPrint('  Encontrado em valorTaxa: $valor');
        } else if (de.taxaInscricao != null) {
          valor = de.taxaInscricao.toString();
          caminho = 'dadosExtraidos.taxaInscricao';
          debugPrint('  Encontrado em taxaInscricao: $valor');
        } else if (de.concurso != null &&
                  de.concurso!.containsKey('inscricoes') &&
                  de.concurso!['inscricoes'] is Map &&
                  (de.concurso!['inscricoes'] as Map).containsKey('taxa')) {
          valor = (de.concurso!['inscricoes'] as Map)['taxa'].toString();
          caminho = 'dadosExtraidos.concurso.inscricoes.taxa';
          debugPrint('  Encontrado em concurso.inscricoes.taxa: $valor');
        }
        break;
      case 'periodoInscricao':
        // Verificar se temos os dados no formato de data
        if (de.inicioInscricao != null && de.fimInscricao != null) {
          // Formatar as datas no formato dd/MM/yyyy
          final inicioFormatado = '${de.inicioInscricao!.day.toString().padLeft(2, '0')}/${de.inicioInscricao!.month.toString().padLeft(2, '0')}/${de.inicioInscricao!.year}';
          final fimFormatado = '${de.fimInscricao!.day.toString().padLeft(2, '0')}/${de.fimInscricao!.month.toString().padLeft(2, '0')}/${de.fimInscricao!.year}';
          valor = '$inicioFormatado a $fimFormatado';
          caminho = 'dadosExtraidos.inicioInscricao/fimInscricao';
          debugPrint('  Encontrado em inicioInscricao/fimInscricao: $valor');
        }
        // Verificar se temos os dados no formato de string
        else if (de.periodoInscricaoInicio != null && de.periodoInscricaoFim != null) {
          valor = '${de.periodoInscricaoInicio} a ${de.periodoInscricaoFim}';
          caminho = 'dadosExtraidos.periodoInscricaoInicio/periodoInscricaoFim';
          debugPrint('  Encontrado em periodoInscricaoInicio/periodoInscricaoFim: $valor');
        }
        // Verificar se há período na estrutura aninhada
        else if (de.concurso != null &&
                de.concurso!.containsKey('inscricoes') &&
                de.concurso!['inscricoes'] is Map) {

          final inscricoes = de.concurso!['inscricoes'] as Map;

          // Verificar se há período formatado
          if (inscricoes.containsKey('periodo')) {
            valor = inscricoes['periodo'].toString();
            caminho = 'dadosExtraidos.concurso.inscricoes.periodo';
            debugPrint('  Encontrado em concurso.inscricoes.periodo: $valor');
          }
          // Verificar se há início e fim separados
          else if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
            valor = '${inscricoes['inicio']} a ${inscricoes['fim']}';
            caminho = 'dadosExtraidos.concurso.inscricoes.inicio/fim';
            debugPrint('  Encontrado em concurso.inscricoes.inicio/fim: $valor');
          }
        }
        break;
      case 'cotas':
        if (de.cotas != null && de.cotas!.isNotEmpty) {
          List<String> cotasInfo = [];
          for (var cota in de.cotas!) {
            String cotaStr = cota.nome;
            if (cota.percentual != null) {
              cotaStr += ' (${cota.percentual}%)';
            }
            cotasInfo.add(cotaStr);
          }
          valor = cotasInfo.join(', ');
          caminho = 'dadosExtraidos.cotas';
        }
        break;
      case 'criteriosAprovacao':
        if (de.criteriosAprovacao != null) {
          valor = de.criteriosAprovacao;
          caminho = 'dadosExtraidos.criteriosAprovacao';
        }
        break;
      case 'criteriosReprovacao':
        if (de.criteriosReprovacao != null) {
          valor = de.criteriosReprovacao;
          caminho = 'dadosExtraidos.criteriosReprovacao';
          debugPrint('  Encontrado em criteriosReprovacao: $valor');
        } else if (de.concurso != null &&
                  de.concurso!.containsKey('prova') &&
                  de.concurso!['prova'] is Map &&
                  (de.concurso!['prova'] as Map).containsKey('criterios_reprovacao')) {
          valor = (de.concurso!['prova'] as Map)['criterios_reprovacao'].toString();
          caminho = 'dadosExtraidos.concurso.prova.criterios_reprovacao';
          debugPrint('  Encontrado em concurso.prova.criterios_reprovacao: $valor');
        } else if (de.dadosProva != null && de.dadosProva!.criteriosReprovacao != null) {
          valor = de.dadosProva!.criteriosReprovacao;
          caminho = 'dadosExtraidos.dadosProva.criteriosReprovacao';
          debugPrint('  Encontrado em dadosProva.criteriosReprovacao: $valor');
        }
        break;
      case 'criteriosDesempate':
        if (de.criteriosDesempate != null && de.criteriosDesempate!.isNotEmpty) {
          valor = de.criteriosDesempate!.join('\n');
          caminho = 'dadosExtraidos.criteriosDesempate';
        }
        break;
      case 'formatoProva':
        if (de.formatoProva != null) {
          valor = de.formatoProva;
          caminho = 'dadosExtraidos.formatoProva';
        }
        break;
      case 'duracaoProva':
        if (de.duracaoProva != null) {
          valor = de.duracaoProva;
          caminho = 'dadosExtraidos.duracaoProva';
        }
        break;
      case 'temaProvaSubjetiva':
        if (de.temaDiscursiva != null) {
          valor = de.temaDiscursiva;
          caminho = 'dadosExtraidos.temaDiscursiva';
        }
        break;
      case 'totalQuestoes':
        if (de.totalQuestoes != null) {
          valor = de.totalQuestoes.toString();
          caminho = 'dadosExtraidos.totalQuestoes';
        }
        break;
    }

    if (ExtratorUtils.isValorValido(valor)) {
      return ResultadoBusca(
        valor: valor!,
        origem: FonteDados.DADOS_EXTRAIDOS,
        caminho: caminho,
      );
    }

    return null;
  }
}
