import 'package:preparatorio_concursos/core/data/models/sessao_estudo.dart';

/// Interface para o serviço de sessões de estudo
abstract class ISessaoEstudoService {
  /// Carrega as sessões de estudo salvas
  Future<void> loadSessoes();

  /// Adiciona uma nova sessão de estudo
  Future<void> addSessao(SessaoEstudo sessao);

  /// Atualiza uma sessão de estudo existente
  Future<void> updateSessao(SessaoEstudo sessao);

  /// Remove uma sessão de estudo
  Future<void> removeSessao(String sessaoId);

  /// Obtém uma sessão de estudo pelo ID
  SessaoEstudo? getSessaoById(String sessaoId);

  /// Inicia uma sessão de estudo
  Future<SessaoEstudo> iniciarSessao(
    String planoId,
    String materiaId,
    String assuntoId,
    String ferramenta,
  );

  /// Finaliza uma sessão de estudo
  Future<void> finalizarSessao(
    String sessaoId, {
    required int duracao,
    required int pontuacao,
    required bool concluida,
  });

  /// Obtém sessões de estudo por plano
  List<SessaoEstudo> getSessoesByPlano(String planoId);

  /// Obtém sessões de estudo por matéria
  List<SessaoEstudo> getSessoesByMateria(String materiaId);

  /// Obtém sessões de estudo por data
  List<SessaoEstudo> getSessoesByData(DateTime data);

  /// Obtém a lista de sessões de estudo
  List<SessaoEstudo> get sessoes;

  /// Verifica se há sessões de estudo salvas
  bool get hasSessoes;
}
