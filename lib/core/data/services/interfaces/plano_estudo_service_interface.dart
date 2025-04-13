import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';

/// Interface para o serviço de planos de estudo
abstract class IPlanoEstudoService {
  /// Carrega os planos de estudo salvos
  Future<void> loadPlanos();

  /// Adiciona um novo plano de estudo
  Future<void> addPlano(PlanoEstudo plano);

  /// Atualiza um plano de estudo existente
  Future<void> updatePlano(PlanoEstudo plano);

  /// Remove um plano de estudo
  Future<void> removePlano(String planoId);

  /// Obtém um plano de estudo pelo ID
  PlanoEstudo? getPlanoById(String planoId);

  /// Define o plano de estudo atual
  Future<void> setCurrentPlano(String planoId);

  /// Obtém o plano de estudo atual
  PlanoEstudo? getCurrentPlano();

  /// Gera um plano de estudo personalizado
  Future<PlanoEstudo> gerarPlanoPersonalizado(
    String editalId,
    List<String> cargoIds,
    Map<String, dynamic> preferencias,
  );

  /// Obtém planos de estudo por edital
  List<PlanoEstudo> getPlanosByEdital(String editalId);

  /// Obtém a lista de planos de estudo
  List<PlanoEstudo> get planos;

  /// Obtém o plano de estudo atual
  PlanoEstudo? get currentPlano;

  /// Verifica se há planos de estudo salvos
  bool get hasPlanos;
}
