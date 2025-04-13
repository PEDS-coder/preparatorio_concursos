/// Interface para o serviço de explicação por áudio
abstract class IAudioExplanationService {
  /// Inicializa o serviço
  Future<void> init();

  /// Reproduz um áudio de explicação
  Future<void> playExplanation(String screenName);

  /// Para a reprodução do áudio
  Future<void> stopExplanation();

  /// Verifica se há um áudio disponível para a tela
  bool hasExplanationFor(String screenName);

  /// Obtém o status de reprodução
  bool get isPlaying;

  /// Obtém a tela atual sendo explicada
  String? get currentScreen;

  /// Habilita ou desabilita as explicações por áudio
  Future<void> setEnabled(bool enabled);

  /// Verifica se as explicações por áudio estão habilitadas
  bool get isEnabled;
}
