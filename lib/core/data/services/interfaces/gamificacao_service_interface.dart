import 'package:preparatorio_concursos/core/data/models/trofeu.dart';
import 'package:preparatorio_concursos/core/data/models/usuario.dart';

/// Interface para o serviço de gamificação
abstract class IGamificacaoService {
  /// Carrega os troféus do usuário
  Future<void> loadUsuarioTrofeus();

  /// Adiciona moedas ao usuário
  Future<void> adicionarMoedas(int quantidade, String motivo);

  /// Remove moedas do usuário
  Future<bool> removerMoedas(int quantidade, String motivo);

  /// Registra uma atividade de estudo
  Future<void> registrarAtividade(
    String tipo,
    int duracao,
    String materiaId,
    String assuntoId,
  );

  /// Verifica e atribui troféus
  Future<List<Trofeu>> verificarTrofeus();

  /// Obtém o usuário atual
  Usuario? get usuario;

  /// Obtém a lista de troféus do usuário
  List<Trofeu> get trofeus;

  /// Obtém o total de moedas do usuário
  int get moedas;

  /// Obtém o streak atual do usuário
  int get streak;

  /// Obtém o total de horas estudadas
  int get horasEstudadas;

  /// Obtém o total de dias estudados
  int get diasEstudados;
}
