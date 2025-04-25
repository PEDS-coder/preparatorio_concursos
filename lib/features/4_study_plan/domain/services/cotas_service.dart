import '../../../../core/data/models/models.dart';
import 'chaves_busca.dart';
import 'extrator_dados_service.dart';

/// Serviço para obtenção de dados de cotas
class CotasService {
  static final ExtratorDadosService _extrator = ExtratorDadosService();

  /// Obtém informações sobre cotas
  static String obterInformacoes(Edital? edital) {
    if (edital == null) return 'Não informado';

    // Criar um plano temporário para usar o extrator
    final planoTemp = PlanoEstudo(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'temp_user',
      editalId: edital.id,
      cargoIds: [],
      dataCriacao: DateTime.now(),
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(const Duration(days: 90)),
      horasSemanais: <String, int>{},
      ferramentas: [],
      materiasProficiencia: <MateriaProficiencia>[],
      recompensas: [],
      sessoesEstudo: [],
      metadados: {},
    );

    return _extrator.buscarCampo(planoTemp, edital, ChavesBusca.COTAS);
  }
}
