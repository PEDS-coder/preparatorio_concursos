import '../../../../../core/data/models/models.dart';
import '../extrator_models.dart';

/// Extrator de dados dos metadados do plano
class MetadadosExtractor {
  /// Busca um valor exato nos metadados do plano
  static ResultadoBusca? buscarExato(PlanoEstudo plano, String chave) {
    if (plano.metadados.containsKey(chave)) {
      final valor = plano.metadados[chave];
      if (valor != null && valor.toString().isNotEmpty && valor.toString() != 'null') {
        return ResultadoBusca(
          valor: valor.toString(),
          origem: FonteDados.METADADOS,
          caminho: chave,
        );
      }
    }
    return null;
  }

  /// Busca um valor alternativo nos metadados do plano
  static ResultadoBusca? buscarAlternativo(PlanoEstudo plano, String chave) {
    // Implementar lógica para buscar chaves alternativas
    // Por exemplo, se buscar 'formatoProva', também tentar 'formato_prova', 'formato', etc.
    final alternativas = _getAlternativas(chave);
    for (final alternativa in alternativas) {
      if (plano.metadados.containsKey(alternativa)) {
        final valor = plano.metadados[alternativa];
        if (valor != null && valor.toString().isNotEmpty && valor.toString() != 'null') {
          return ResultadoBusca(
            valor: valor.toString(),
            origem: FonteDados.METADADOS_ALTERNATIVO,
            caminho: alternativa,
          );
        }
      }
    }
    return null;
  }

  /// Busca um valor aninhado nos metadados do plano
  static ResultadoBusca? buscarAninhado(PlanoEstudo plano, String chave) {
    // Implementar lógica para buscar em estruturas aninhadas
    // Por exemplo, se buscar 'prova.formato', tentar plano.metadados['prova']['formato']
    final partes = chave.split('.');
    if (partes.length > 1) {
      dynamic atual = plano.metadados;
      String caminho = '';
      
      for (int i = 0; i < partes.length; i++) {
        final parte = partes[i];
        caminho += (i > 0 ? '.' : '') + parte;
        
        if (atual is Map && atual.containsKey(parte)) {
          atual = atual[parte];
          if (i == partes.length - 1 && atual != null && atual.toString().isNotEmpty && atual.toString() != 'null') {
            return ResultadoBusca(
              valor: atual.toString(),
              origem: FonteDados.METADADOS_ANINHADOS,
              caminho: caminho,
            );
          }
        } else {
          break;
        }
      }
    }
    return null;
  }

  /// Obtém alternativas para uma chave
  static List<String> _getAlternativas(String chave) {
    switch (chave) {
      case 'formatoProva':
        return ['formato_prova', 'formato', 'tipo_prova', 'tipo'];
      case 'dataProva':
        return ['data_prova', 'data', 'data_realizacao'];
      case 'localProva':
        return ['local_prova', 'local', 'local_realizacao'];
      case 'valorInscricao':
        return ['valor_inscricao', 'taxa', 'taxa_inscricao', 'valor_taxa'];
      case 'criteriosAprovacao':
        return ['criterios_aprovacao', 'aprovacao'];
      case 'criteriosReprovacao':
        return ['criterios_reprovacao', 'reprovacao'];
      case 'criteriosDesempate':
        return ['criterios_desempate', 'desempate'];
      case 'totalQuestoes':
        return ['total_questoes', 'questoes', 'numero_questoes'];
      case 'duracaoProva':
        return ['duracao_prova', 'duracao', 'tempo_prova'];
      case 'temaProvaSubjetiva':
        return ['tema_prova_subjetiva', 'tema_discursiva', 'tema_subjetiva', 'tema_redacao'];
      default:
        return [];
    }
  }
}
