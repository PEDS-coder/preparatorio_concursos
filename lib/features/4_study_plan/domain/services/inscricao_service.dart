import '../../../../core/data/models/models.dart';
import '../../../../core/utils/formatador_service.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';

/// Serviço para obtenção de dados da inscrição
class InscricaoService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();
  
  /// Obtém o valor da inscrição
  static String obterValor(PlanoEstudo plano, Edital? edital) {
    return _extrator.buscarCampo(plano, edital, ChavesBusca.VALOR_INSCRICAO);
  }
  
  /// Obtém o período de inscrições
  static String obterPeriodo(Edital? edital) {
    if (edital == null) return 'Não informado';

    final inicio = edital.dadosExtraidos.inicioInscricao;
    final fim = edital.dadosExtraidos.fimInscricao;

    if (inicio == null || fim == null) {
      // Tentar obter dos dados originais
      if (edital.dadosOriginais != null &&
          edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map && inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
          return '${inscricoes['inicio']} a ${inscricoes['fim']}';
        }
      }
      return 'Não informado';
    }

    return '${FormatadorService.formatarData(inicio)} a ${FormatadorService.formatarData(fim)}';
  }
}
