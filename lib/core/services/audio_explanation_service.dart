import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class AudioExplanationService extends ChangeNotifier {
  static final AudioExplanationService _instance = AudioExplanationService._internal();

  factory AudioExplanationService() => _instance;

  AudioExplanationService._internal();

  final Map<String, AudioPlayer> _players = {};
  bool _explanationsEnabled = true;
  double _volume = 0.7;

  // Verificar se estamos no Windows
  final bool _isWindows = !kIsWeb && Platform.isWindows;

  // Diretório temporário para armazenar arquivos de áudio no Windows
  String? _tempDir;

  // Mapa para rastrear arquivos temporários no Windows
  final Map<String, String> _tempFiles = {};

  // Inicializar o serviço
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _explanationsEnabled = prefs.getBool('explanations_enabled') ?? true;
      _volume = prefs.getDouble('explanation_volume') ?? 0.7;

      // Inicializar diretório temporário para Windows
      if (_isWindows) {
        try {
          final tempDirectory = await getTemporaryDirectory();
          _tempDir = tempDirectory.path;
          debugPrint('Diretório temporário para áudios no Windows: $_tempDir');

          // Pré-extrair os arquivos de áudio para o diretório temporário
          await _preExtractAudioFiles();
        } catch (e) {
          debugPrint('Erro ao inicializar diretório temporário no Windows: $e');
          // Continuar mesmo com erro
        }
      }

      debugPrint('AudioExplanationService inicializado: explanationsEnabled=$_explanationsEnabled, volume=$_volume, isWindows=$_isWindows');
    } catch (e) {
      debugPrint('Erro ao inicializar AudioExplanationService: $e');
    }
  }

  // Método para pré-extrair arquivos de áudio no Windows
  Future<void> _preExtractAudioFiles() async {
    if (!_isWindows || _tempDir == null) return;

    final audioFiles = [
      'login_explanation.mp3',
      'api_config_explanation.mp3',
      'edital_analyze_explanation.mp3',
      'cargo_select_explanation.mp3',
      'questionnaire_explanation.mp3'
    ];

    for (final audioFile in audioFiles) {
      try {
        final assetPath = 'assets/audio_explanations/$audioFile';
        final tempFilePath = '$_tempDir/$audioFile';

        // Verificar se o arquivo já existe no diretório temporário
        final tempFile = File(tempFilePath);
        if (!await tempFile.exists()) {
          // Extrair o arquivo do asset para o diretório temporário
          final data = await rootBundle.load(assetPath);
          final bytes = data.buffer.asUint8List();
          await tempFile.writeAsBytes(bytes);
          debugPrint('Arquivo de áudio extraído para: $tempFilePath');
        }

        // Armazenar o caminho do arquivo temporário
        final audioName = audioFile.split('.').first;
        _tempFiles[audioName] = tempFilePath;
      } catch (e) {
        debugPrint('Erro ao extrair arquivo de áudio $audioFile: $e');
      }
    }
  }

  // Verificar se as explicações estão habilitadas
  bool get isExplanationsEnabled => _explanationsEnabled;

  // Obter o volume atual
  double get volume => _volume;

  // Habilitar/desabilitar explicações
  Future<void> setExplanationsEnabled(bool enabled) async {
    _explanationsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('explanations_enabled', enabled);
      debugPrint('Explicações ${enabled ? 'habilitadas' : 'desabilitadas'}');
    } catch (e) {
      debugPrint('Erro ao salvar configuração de explicações: $e');
    }
  }

  // Definir volume
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);

    // Atualizar volume em todos os players ativos
    for (final player in _players.values) {
      player.setVolume(_volume);
    }

    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('explanation_volume', _volume);
      debugPrint('Volume de explicações definido para $_volume');
    } catch (e) {
      debugPrint('Erro ao salvar volume de explicações: $e');
    }
  }

  // Reproduzir um áudio de explicação
  Future<void> playExplanation(String screenName) async {
    debugPrint('Tentando reproduzir explicação para tela: $screenName');

    if (!_explanationsEnabled) {
      debugPrint('Explicações estão desativadas. Ignorando.');
      return;
    }

    final audioName = '${screenName}_explanation';
    debugPrint('Nome do arquivo de áudio: $audioName.mp3');

    try {
      // Parar qualquer explicação que esteja tocando
      await stopAllExplanations();
      debugPrint('Explicações anteriores interrompidas');

      // Abordagem específica para Windows
      if (_isWindows) {
        return await _playExplanationWindows(audioName);
      }

      // Abordagem padrão para outras plataformas
      // Verificar se já existe um player para este áudio
      if (!_players.containsKey(audioName)) {
        debugPrint('Criando novo player para $audioName');
        final player = AudioPlayer();
        try {
          await player.setAsset('assets/audio_explanations/$audioName.mp3');
          debugPrint('Asset carregado com sucesso: assets/audio_explanations/$audioName.mp3');
          player.setVolume(_volume);
          _players[audioName] = player;
        } catch (assetError) {
          debugPrint('Erro ao carregar asset: $assetError');
          return;
        }
      } else {
        debugPrint('Usando player existente para $audioName');
      }

      final player = _players[audioName]!;

      // Reiniciar o player se necessário
      if (player.position != Duration.zero) {
        await player.seek(Duration.zero);
        debugPrint('Player reiniciado para o início');
      }

      await player.play();
      debugPrint('Reproduzindo explicação: $audioName com volume $_volume');
    } catch (e) {
      debugPrint('Erro ao reproduzir explicação $audioName: $e');
    }
  }

  // Método específico para reproduzir áudio no Windows
  Future<void> _playExplanationWindows(String audioName) async {
    debugPrint('Usando abordagem específica para Windows');

    // Verificar se o arquivo temporário existe
    if (!_tempFiles.containsKey(audioName)) {
      debugPrint('Arquivo temporário não encontrado para $audioName');
      return;
    }

    final filePath = _tempFiles[audioName]!;
    debugPrint('Usando arquivo temporário: $filePath');

    // Verificar se já existe um player para este áudio
    if (!_players.containsKey(audioName)) {
      debugPrint('Criando novo player para $audioName no Windows');
      final player = AudioPlayer();
      try {
        // Usar o arquivo do sistema de arquivos em vez do asset
        await player.setFilePath(filePath);
        debugPrint('Arquivo carregado com sucesso: $filePath');
        player.setVolume(_volume);
        _players[audioName] = player;
      } catch (fileError) {
        debugPrint('Erro ao carregar arquivo: $fileError');
        return;
      }
    } else {
      debugPrint('Usando player existente para $audioName no Windows');
    }

    final player = _players[audioName]!;

    // Reiniciar o player se necessário
    if (player.position != Duration.zero) {
      await player.seek(Duration.zero);
      debugPrint('Player reiniciado para o início');
    }

    await player.play();
    debugPrint('Reproduzindo explicação no Windows: $audioName com volume $_volume');
  }

  // Parar todas as explicações
  Future<void> stopAllExplanations() async {
    for (final player in _players.values) {
      if (player.playing) {
        await player.stop();
        await player.seek(Duration.zero);
      }
    }
  }

  // Reproduzir explicação da tela de login
  Future<void> playLoginExplanation() async {
    await playExplanation('login');
  }

  // Reproduzir explicação da tela de configuração da API
  Future<void> playApiConfigExplanation() async {
    debugPrint('Reproduzindo explicação da tela de configuração da API');
    await playExplanation('api_config');
  }

  // Reproduzir explicação da tela de análise de edital
  Future<void> playEditalAnalyzeExplanation() async {
    await playExplanation('edital_analyze');
  }

  // Reproduzir explicação da tela de seleção de cargos
  Future<void> playCargoSelectExplanation() async {
    await playExplanation('cargo_select');
  }

  // Reproduzir explicação da tela de questionário
  Future<void> playQuestionnaireExplanation() async {
    await playExplanation('questionnaire');
  }

  // Métodos adicionais para compatibilidade
  Future<void> playNavigation() async {
    // Não faz nada, apenas para compatibilidade
  }

  Future<void> playSuccess() async {
    // Não faz nada, apenas para compatibilidade
  }

  Future<void> playError() async {
    // Não faz nada, apenas para compatibilidade
  }

  Future<void> playAlert() async {
    // Não faz nada, apenas para compatibilidade
  }

  Future<void> playProcessStart() async {
    // Não faz nada, apenas para compatibilidade
  }

  Future<void> playProcessComplete() async {
    // Não faz nada, apenas para compatibilidade
  }

  // Liberar recursos
  Future<void> dispose() async {
    await stopAllExplanations();
    for (final player in _players.values) {
      await player.dispose();
    }
    _players.clear();

    // Limpar arquivos temporários no Windows
    if (_isWindows) {
      await _cleanupTempFiles();
    }

    super.dispose();
  }

  // Limpar arquivos temporários no Windows
  Future<void> _cleanupTempFiles() async {
    if (!_isWindows) return;

    for (final filePath in _tempFiles.values) {
      try {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('Arquivo temporário removido: $filePath');
        }
      } catch (e) {
        debugPrint('Erro ao remover arquivo temporário $filePath: $e');
      }
    }

    _tempFiles.clear();
  }
}
