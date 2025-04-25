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
        valor = de.dataProva;
        caminho = 'dadosExtraidos.dataProva';
        break;
      case 'localProva':
        valor = de.localProva;
        caminho = 'dadosExtraidos.localProva';
        break;
      case 'valorInscricao':
        if (de.valorTaxa != null) {
          valor = de.valorTaxa.toString();
          caminho = 'dadosExtraidos.valorTaxa';
        }
        break;
      case 'periodoInscricao':
        if (de.inicioInscricao != null && de.fimInscricao != null) {
          valor = '${de.inicioInscricao} a ${de.fimInscricao}';
          caminho = 'dadosExtraidos.inicioInscricao/fimInscricao';
        }
        break;
      // Adicionar outros casos conforme necessário
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
