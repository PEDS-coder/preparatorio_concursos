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

    // Verificar se há dados de inscrição no edital
    final inicio = edital.dadosExtraidos.inicioInscricao;
    final fim = edital.dadosExtraidos.fimInscricao;

    if (inicio != null && fim != null) {
      // Formatar as datas no formato dd/MM/yyyy
      final inicioFormatado = '${inicio.day.toString().padLeft(2, '0')}/${inicio.month.toString().padLeft(2, '0')}/${inicio.year}';
      final fimFormatado = '${fim.day.toString().padLeft(2, '0')}/${fim.month.toString().padLeft(2, '0')}/${fim.year}';
      return '$inicioFormatado a $fimFormatado';
    }

    // Tentar obter dos dados originais
    if (edital.dadosOriginais != null) {
      // Verificar se há dados de inscrição no objeto concurso
      if (edital.dadosOriginais!.containsKey('concurso') &&
          edital.dadosOriginais!['concurso'] is Map &&
          (edital.dadosOriginais!['concurso'] as Map).containsKey('inscricoes')) {

        final inscricoes = edital.dadosOriginais!['concurso']['inscricoes'];
        if (inscricoes is Map) {
          // Verificar se há período formatado
          if (inscricoes.containsKey('periodo')) {
            return inscricoes['periodo'];
          }

          // Verificar se há início e fim separados
          if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
            return '${inscricoes['inicio']} a ${inscricoes['fim']}';
          }
        }
      }

      // Verificar se há dados de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('inscricoes') && edital.dadosOriginais!['inscricoes'] is Map) {
        final inscricoes = edital.dadosOriginais!['inscricoes'] as Map;

        // Verificar se há período formatado
        if (inscricoes.containsKey('periodo')) {
          return inscricoes['periodo'];
        }

        // Verificar se há início e fim separados
        if (inscricoes.containsKey('inicio') && inscricoes.containsKey('fim')) {
          return '${inscricoes['inicio']} a ${inscricoes['fim']}';
        }
      }

      // Verificar se há período de inscrição diretamente nos dados originais
      if (edital.dadosOriginais!.containsKey('periodo_inscricao')) {
        if (edital.dadosOriginais!['periodo_inscricao'] is String) {
          return edital.dadosOriginais!['periodo_inscricao'];
        } else if (edital.dadosOriginais!['periodo_inscricao'] is Map) {
          final periodoInscricao = edital.dadosOriginais!['periodo_inscricao'] as Map;
          if (periodoInscricao.containsKey('inicio') && periodoInscricao.containsKey('fim')) {
            return '${periodoInscricao['inicio']} a ${periodoInscricao['fim']}';
          }
        }
      }
    }

    return 'Não informado';
  }
}
