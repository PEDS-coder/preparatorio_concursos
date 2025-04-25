import '../../../../../core/data/models/models.dart';
import '../../../../../core/utils/formatador_service.dart';
import '../extrator_models.dart';
import '../extrator_utils.dart';

/// Extrator de dados da prova do edital
class DadosProvaExtractor {
  /// Busca um valor nos dados da prova do edital
  static ResultadoBusca? buscar(Edital? edital, String chave) {
    if (edital == null || edital.dadosExtraidos.dadosProva == null) return null;
    
    final dadosProva = edital.dadosExtraidos.dadosProva!;
    String? valor;
    String caminho = '';
    
    switch (chave) {
      case 'formatoProva':
        if (dadosProva.formato != null && dadosProva.formato!.isNotEmpty) {
          valor = dadosProva.formato!.join(', ');
          caminho = 'dadosExtraidos.dadosProva.formato';
        }
        break;
      case 'dataProva':
        if (dadosProva.dataRealizacao != null) {
          valor = FormatadorService.formatarData(dadosProva.dataRealizacao!);
          caminho = 'dadosExtraidos.dadosProva.dataRealizacao';
        }
        break;
      case 'totalQuestoes':
        if (dadosProva.totalQuestoes != null) {
          valor = dadosProva.totalQuestoes.toString();
          caminho = 'dadosExtraidos.dadosProva.totalQuestoes';
        }
        break;
      case 'duracaoProva':
        valor = dadosProva.duracao;
        caminho = 'dadosExtraidos.dadosProva.duracao';
        break;
      case 'criteriosAprovacao':
        valor = dadosProva.criteriosAprovacao;
        caminho = 'dadosExtraidos.dadosProva.criteriosAprovacao';
        break;
      case 'criteriosReprovacao':
        valor = dadosProva.criteriosReprovacao;
        caminho = 'dadosExtraidos.dadosProva.criteriosReprovacao';
        break;
      case 'criteriosDesempate':
        if (dadosProva.criteriosDesempate != null && dadosProva.criteriosDesempate!.isNotEmpty) {
          List<String> criteriosList = [];
          for (var i = 0; i < dadosProva.criteriosDesempate!.length; i++) {
            criteriosList.add('${i+1}. ${dadosProva.criteriosDesempate![i]}');
          }
          valor = criteriosList.join('\n');
          caminho = 'dadosExtraidos.dadosProva.criteriosDesempate';
        }
        break;
      case 'temaProvaSubjetiva':
        valor = dadosProva.temaDiscursiva;
        caminho = 'dadosExtraidos.dadosProva.temaDiscursiva';
        break;
      // Adicionar outros casos conforme necessário
    }
    
    if (ExtratorUtils.isValorValido(valor)) {
      return ResultadoBusca(
        valor: valor!,
        origem: FonteDados.DADOS_PROVA,
        caminho: caminho,
      );
    }
    
    return null;
  }
}
