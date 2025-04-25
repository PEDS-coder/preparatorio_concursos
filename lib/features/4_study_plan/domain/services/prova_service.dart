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
    return _extrator.buscarCampo(plano, edital, ChavesBusca.DATA_PROVA);
  }
  
  /// Obtém o local da prova
  static String obterLocal(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.LOCAL_PROVA);
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
