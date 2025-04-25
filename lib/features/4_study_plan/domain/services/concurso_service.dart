import '../../../../core/data/models/models.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';

/// Serviço para obtenção de dados do concurso
class ConcursoService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();
  
  /// Obtém o título do concurso
  static String obterTitulo(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.TITULO);
  }
  
  /// Obtém o órgão do concurso
  static String obterOrgao(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.ORGAO);
  }
  
  /// Obtém a banca do concurso
  static String obterBanca(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.BANCA);
  }
}
