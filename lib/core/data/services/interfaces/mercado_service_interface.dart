import 'package:preparatorio_concursos/core/data/models/recompensa_mercado.dart';

/// Interface para o serviço de mercado
abstract class IMercadoService {
  /// Carrega as recompensas disponíveis
  Future<void> loadRecompensas();

  /// Adiciona uma nova recompensa
  Future<void> addRecompensa(RecompensaMercado recompensa);

  /// Atualiza uma recompensa existente
  Future<void> updateRecompensa(RecompensaMercado recompensa);

  /// Remove uma recompensa
  Future<void> removeRecompensa(String recompensaId);

  /// Compra uma recompensa
  Future<bool> comprarRecompensa(String recompensaId);

  /// Resgata uma recompensa comprada
  Future<bool> resgatarRecompensa(String recompensaId);

  /// Obtém o histórico de compras do usuário
  Future<List<RecompensaMercado>> getHistoricoCompras();

  /// Obtém as recompensas disponíveis
  List<RecompensaMercado> get recompensas;

  /// Obtém as recompensas compradas pelo usuário
  List<RecompensaMercado> get recompensasCompradas;

  /// Verifica se o usuário já recebeu o bônus diário
  bool get recebeuBonusDiario;

  /// Concede o bônus diário ao usuário
  Future<int> concederBonusDiario();

  /// Reseta o status do bônus diário
  Future<void> resetarBonusDiario();
}
