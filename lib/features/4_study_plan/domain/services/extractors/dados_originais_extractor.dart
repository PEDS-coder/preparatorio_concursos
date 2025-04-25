import '../../../../../core/data/models/models.dart';
import '../extrator_models.dart';
import '../extrator_utils.dart';

/// Extrator de dados originais do edital
class DadosOriginaisExtractor {
  /// Busca um valor nos dados originais do edital
  static ResultadoBusca? buscar(Edital? edital, String chaveMetadados, String chaveDadosOriginais) {
    if (edital == null || edital.dadosOriginais == null) return null;
    
    // Dividir a chave por pontos para navegar na estrutura aninhada
    final partes = chaveDadosOriginais.split('.');
    
    // Tentar buscar em resposta_completa primeiro
    final valorRespostaCompleta = _buscarEmCaminho(edital.dadosOriginais!, ['resposta_completa', ...partes]);
    if (valorRespostaCompleta != null) {
      return ResultadoBusca(
        valor: valorRespostaCompleta,
        origem: FonteDados.DADOS_ORIGINAIS,
        caminho: 'dadosOriginais.resposta_completa.$chaveDadosOriginais',
      );
    }
    
    // Tentar buscar diretamente
    final valorDireto = _buscarEmCaminho(edital.dadosOriginais!, partes);
    if (valorDireto != null) {
      return ResultadoBusca(
        valor: valorDireto,
        origem: FonteDados.DADOS_ORIGINAIS,
        caminho: 'dadosOriginais.$chaveDadosOriginais',
      );
    }
    
    // Tentar buscar em concurso
    final valorConcurso = _buscarEmCaminho(edital.dadosOriginais!, ['concurso', ...partes]);
    if (valorConcurso != null) {
      return ResultadoBusca(
        valor: valorConcurso,
        origem: FonteDados.DADOS_ORIGINAIS,
        caminho: 'dadosOriginais.concurso.$chaveDadosOriginais',
      );
    }
    
    // Casos especiais baseados na chave de metadados
    switch (chaveMetadados) {
      case 'valorInscricao':
        if (edital.dadosOriginais!.containsKey('taxa_inscricao')) {
          final valor = edital.dadosOriginais!['taxa_inscricao'];
          if (ExtratorUtils.isValorValido(valor)) {
            return ResultadoBusca(
              valor: valor.toString(),
              origem: FonteDados.DADOS_ORIGINAIS,
              caminho: 'dadosOriginais.taxa_inscricao',
            );
          }
        }
        break;
      // Adicionar outros casos especiais conforme necessário
    }
    
    return null;
  }
  
  /// Busca um valor em um caminho aninhado
  static String? _buscarEmCaminho(Map<String, dynamic> dados, List<String> caminho) {
    dynamic atual = dados;
    
    for (int i = 0; i < caminho.length; i++) {
      final parte = caminho[i];
      
      if (atual is Map && atual.containsKey(parte)) {
        atual = atual[parte];
        
        if (i == caminho.length - 1) {
          // Chegamos ao final do caminho
          if (atual is List) {
            return atual.join(', ');
          } else if (ExtratorUtils.isValorValido(atual)) {
            return atual.toString();
          }
        }
      } else {
        // Caminho não existe
        break;
      }
    }
    
    return null;
  }
}
