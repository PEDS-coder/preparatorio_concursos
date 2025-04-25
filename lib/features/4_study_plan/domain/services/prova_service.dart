import '../../../../core/data/models/models.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';

/// Serviço para obtenção de dados da prova
class ProvaService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();

  /// Obtém o formato da prova
  static String obterFormato(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.FORMATO_PROVA);
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
          return prova['data'].toString();
        }
      }

      // Verificar se há dados da prova diretamente nos dados originais
      if (edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('prova') &&
          edital.dadosOriginais!['prova'] is Map) {

        final prova = edital.dadosOriginais!['prova'] as Map;
        if (prova.containsKey('data')) {
          return prova['data'].toString();
        }
      }
    }

    return resultado;
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
          return prova['local'].toString();
        }
      }

      // Verificar se há dados da prova diretamente nos dados originais
      if (edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('prova') &&
          edital.dadosOriginais!['prova'] is Map) {

        final prova = edital.dadosOriginais!['prova'] as Map;
        if (prova.containsKey('local')) {
          return prova['local'].toString();
        }
      }
    }

    return resultado;
  }

  /// Obtém o total de questões da prova
  static String obterTotalQuestoes(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.TOTAL_QUESTOES);
  }

  /// Obtém a duração da prova
  static String obterDuracao(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.DURACAO_PROVA);
  }

  /// Obtém os critérios de aprovação da prova
  static String obterCriteriosAprovacao(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.CRITERIOS_APROVACAO);
  }

  /// Obtém os critérios de reprovação da prova
  static String obterCriteriosReprovacao(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.CRITERIOS_REPROVACAO);
  }

  /// Obtém os critérios de desempate da prova
  static String obterCriteriosDesempate(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.CRITERIOS_DESEMPATE);
  }

  /// Obtém o tema da prova subjetiva
  static String obterTemaProvaSubjetiva(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.TEMA_PROVA_SUBJETIVA);
  }
}
