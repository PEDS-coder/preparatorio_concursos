import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

/// Logger especializado para rastrear o ciclo de vida dos dados do plano de estudos
class PlanoDataLogger {
  static final PlanoDataLogger _instance = PlanoDataLogger._internal();

  factory PlanoDataLogger() => _instance;

  PlanoDataLogger._internal();

  // Arquivo para armazenar logs
  File? _logFile;
  final _logBuffer = <String>[];
  static const int _maxBufferSize = 1000;
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10 MB
  bool _initialized = false;

  /// Inicializa o logger
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (!kIsWeb) {
        // Usar a pasta raiz do projeto em vez de getApplicationDocumentsDirectory()
        final path = '${Directory.current.path}/logs';
        await Directory(path).create(recursive: true);
        _logFile = File('$path/plano_data_log.txt');

        // Verifica o tamanho do arquivo de log
        if (await _logFile!.exists()) {
          final fileSize = await _logFile!.length();
          if (fileSize > _maxLogFileSize) {
            // Se o arquivo for muito grande, cria um backup e limpa
            final backupFile = File('$path/plano_data_log_backup.txt');
            if (await backupFile.exists()) {
              await backupFile.delete();
            }
            await _logFile!.copy('$path/plano_data_log_backup.txt');
            await _logFile!.writeAsString('');
          }
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar PlanoDataLogger: $e');
    }
  }

  /// Registra a extração de dados do edital
  void logExtracao(String editalId, String campo, dynamic valor) {
    _log('EXTRAÇÃO', 'Edital: $editalId, Campo: $campo, Valor: $valor');
  }

  /// Registra o armazenamento de dados
  void logArmazenamento(String planoId, String tipo, dynamic dados) {
    String dadosStr;
    if (dados is Map || dados is List) {
      try {
        dadosStr = const JsonEncoder.withIndent('  ').convert(dados);
      } catch (e) {
        dadosStr = dados.toString();
      }
    } else {
      dadosStr = dados.toString();
    }

    _log('ARMAZENAMENTO', 'Plano: $planoId, Tipo: $tipo, Dados: $dadosStr');
  }

  /// Registra o processamento de dados da LLM
  void logProcessamentoLLM(String planoId, String etapa, dynamic dados) {
    String dadosStr;
    if (dados is Map || dados is List) {
      try {
        dadosStr = const JsonEncoder.withIndent('  ').convert(dados);
      } catch (e) {
        dadosStr = dados.toString();
      }
    } else {
      dadosStr = dados.toString();
    }

    _log('PROCESSAMENTO_LLM', 'Plano: $planoId, Etapa: $etapa, Dados: $dadosStr');
  }

  /// Registra a recuperação de dados
  void logRecuperacao(String planoId, String campo, dynamic valor) {
    String valorStr;
    if (valor is Map || valor is List) {
      try {
        valorStr = const JsonEncoder.withIndent('  ').convert(valor);
      } catch (e) {
        valorStr = valor.toString();
      }
    } else {
      valorStr = valor.toString();
    }

    _log('RECUPERAÇÃO', 'Plano: $planoId, Campo: $campo, Valor: $valorStr');
  }

  /// Registra a apresentação de dados na interface
  void logApresentacao(String planoId, String componente, dynamic dados) {
    String dadosStr;
    if (dados is Map || dados is List) {
      try {
        dadosStr = const JsonEncoder.withIndent('  ').convert(dados);
      } catch (e) {
        dadosStr = dados.toString();
      }
    } else {
      dadosStr = dados.toString();
    }

    _log('APRESENTAÇÃO', 'Plano: $planoId, Componente: $componente, Dados: $dadosStr');
  }

  /// Registra interações do usuário
  void logInteracao(String planoId, String acao, dynamic detalhes) {
    String detalhesStr;
    if (detalhes is Map || detalhes is List) {
      try {
        detalhesStr = const JsonEncoder.withIndent('  ').convert(detalhes);
      } catch (e) {
        detalhesStr = detalhes.toString();
      }
    } else {
      detalhesStr = detalhes.toString();
    }

    _log('INTERAÇÃO', 'Plano: $planoId, Ação: $acao, Detalhes: $detalhesStr');
  }

  /// Registra navegação entre telas
  void logNavegacao(String planoId, String evento, dynamic destino) {
    String destinoStr;
    if (destino is Map || destino is List) {
      try {
        destinoStr = const JsonEncoder.withIndent('  ').convert(destino);
      } catch (e) {
        destinoStr = destino.toString();
      }
    } else {
      destinoStr = destino.toString();
    }

    _log('NAVEGAÇÃO', 'Plano: $planoId, Evento: $evento, Destino: $destinoStr');
  }

  /// Registra dados do questionário
  void logQuestionario(String planoId, String etapa, dynamic dados) {
    String dadosStr;
    if (dados is Map || dados is List) {
      try {
        dadosStr = const JsonEncoder.withIndent('  ').convert(dados);
      } catch (e) {
        dadosStr = dados.toString();
      }
    } else {
      dadosStr = dados.toString();
    }

    _log('QUESTIONÁRIO', 'Plano: $planoId, Etapa: $etapa, Dados: $dadosStr');
  }

  /// Método interno para registrar logs
  void _log(String categoria, String mensagem) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
    final logMessage = '[$timestamp] [$categoria] $mensagem';

    // Exibe o log no console
    if (kDebugMode) {
      debugPrint(logMessage);
    }

    // Armazena o log no buffer
    _logBuffer.add(logMessage);
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }

    // Salva o log no arquivo se não estiver na web
    _writeLogToFile(logMessage);
  }

  /// Escreve o log no arquivo
  Future<void> _writeLogToFile(String logMessage) async {
    if (kIsWeb || _logFile == null) return;

    try {
      await init();
      await _logFile!.writeAsString('$logMessage\n', mode: FileMode.append);
    } catch (e) {
      debugPrint('Erro ao escrever log no arquivo: $e');
    }
  }

  /// Limpa os logs armazenados
  Future<void> clearLogs() async {
    _logBuffer.clear();

    if (!kIsWeb && _logFile != null) {
      try {
        await init();
        if (await _logFile!.exists()) {
          await _logFile!.writeAsString('');
        }
      } catch (e) {
        debugPrint('Erro ao limpar logs: $e');
      }
    }
  }

  /// Obtém os logs armazenados
  Future<String> getLogs() async {
    if (kIsWeb || _logFile == null) {
      return _logBuffer.join('\n');
    }

    try {
      await init();
      if (await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (e) {
      debugPrint('Erro ao ler logs: $e');
    }

    return _logBuffer.join('\n');
  }

  /// Exporta os logs para um arquivo
  Future<String?> exportLogs() async {
    if (kIsWeb) return null;

    try {
      await init();
      // Usar a pasta raiz do projeto em vez de getApplicationDocumentsDirectory()
      final path = '${Directory.current.path}/logs';
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final exportPath = '$path/plano_data_log_$timestamp.txt';

      final exportFile = File(exportPath);
      await exportFile.writeAsString(await getLogs());

      return exportPath;
    } catch (e) {
      debugPrint('Erro ao exportar logs: $e');
      return null;
    }
  }
}
