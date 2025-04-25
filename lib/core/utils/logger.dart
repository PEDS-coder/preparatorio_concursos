import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'package:injectable/injectable.dart';

/// Enum para os níveis de log
enum LogLevel {
  verbose(0, 'VERBOSE'),
  debug(1, 'DEBUG'),
  info(2, 'INFO'),
  warning(3, 'WARNING'),
  error(4, 'ERROR'),
  none(5, 'NONE');

  final int value;
  final String name;
  const LogLevel(this.value, this.name);
}

@singleton
class Logger {
  // Nível atual de log (pode ser alterado em tempo de execução)
  LogLevel _currentLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Define o nível de log atual
  void setLogLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// Obtém o nível de log atual
  LogLevel getLogLevel() {
    return _currentLevel;
  }

  /// Log detalhado para depuração profunda
  void verbose(String message, {String? tag, dynamic data}) {
    _log(LogLevel.verbose, message, tag: tag, data: data);
  }

  /// Log de depuração
  void debug(String message, {String? tag, dynamic data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log de informação
  void info(String message, {String? tag, dynamic data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log de aviso
  void warning(String message, {String? tag, dynamic data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log de erro
  void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      data: error,
      stackTrace: stackTrace
    );
  }

  /// Método interno para registrar logs
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic data,
    StackTrace? stackTrace
  }) {
    if (level.value < _currentLevel.value) return;

    final timestamp = DateTime.now().toIso8601String();
    final tagInfo = tag != null ? '/$tag' : '';
    var logMessage = '[$timestamp] ${level.name}$tagInfo: $message';

    // Adiciona detalhes se disponíveis
    if (data != null) {
      String dataStr = data.toString();
      logMessage += '\nData: $dataStr';
    }

    // Adiciona stack trace se disponível
    if (stackTrace != null) {
      logMessage += '\nStack trace: $stackTrace';
    }

    // Exibe o log no console
    if (kDebugMode) {
      debugPrint(logMessage);
    }
  }

  /// Limpa os logs armazenados
  Future<void> clearLogs() async {
    // Implementação básica
    return;
  }

  /// Obtém os logs armazenados
  Future<String> getLogs() async {
    // Implementação básica
    return '';
  }
}

/// Implementação avançada do logger
class AppLogger extends Logger {
  static final AppLogger _instance = AppLogger._internal();

  /// Factory para obter a instância singleton
  factory AppLogger() => _instance;

  AppLogger._internal();

  // Nível atual de log (pode ser alterado em tempo de execução)
  @override
  LogLevel _currentLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  // Arquivo para armazenar logs
  File? _logFile;
  final _logBuffer = <String>[];
  static const int _maxBufferSize = 100;
  static const int _maxLogFileSize = 5 * 1024 * 1024; // 5 MB
  bool _initialized = false;

  /// Inicializa o logger
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (!kIsWeb) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/logs';
        await Directory(path).create(recursive: true);
        _logFile = File('$path/app_log.txt');

        // Verifica o tamanho do arquivo de log
        if (await _logFile!.exists()) {
          final fileSize = await _logFile!.length();
          if (fileSize > _maxLogFileSize) {
            // Se o arquivo for muito grande, cria um backup e limpa
            final backupFile = File('$path/app_log_backup.txt');
            if (await backupFile.exists()) {
              await backupFile.delete();
            }
            await _logFile!.copy('$path/app_log_backup.txt');
            await _logFile!.writeAsString('');
          }
        }
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Erro ao inicializar logger: $e');
    }
  }

  // Nenhuma necessidade de sobrescrever setLogLevel e getLogLevel
  // pois estamos estendendo a classe Logger

  // Sobrescrevemos os métodos de log para usar nossa implementação personalizada

  /// Método interno para registrar logs
  @override
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    dynamic data,
    StackTrace? stackTrace
  }) {
    if (level.value < _currentLevel.value) return;

    final timestamp = DateTime.now().toIso8601String();
    final tagInfo = tag != null ? '/$tag' : '';
    var logMessage = '[$timestamp] ${level.name}$tagInfo: $message';

    // Adiciona detalhes se disponíveis
    if (data != null) {
      String dataStr;
      if (data is Map || data is List) {
        try {
          dataStr = const JsonEncoder.withIndent('  ').convert(data);
        } catch (e) {
          dataStr = data.toString();
        }
      } else {
        dataStr = data.toString();
      }
      logMessage += '\nData: $dataStr';
    }

    // Adiciona stack trace se disponível
    if (stackTrace != null) {
      logMessage += '\nStack trace: $stackTrace';
    }

    // Exibe o log no console
    if (kDebugMode) {
      debugPrint(logMessage);
    } else {
      print(logMessage);
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

  @override
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

  @override
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
}
