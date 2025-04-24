import 'package:flutter/foundation.dart';

/// Classe estática para compatibilidade com o código que usa métodos estáticos
class Logger {
  /// Log de erro estático
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) {
        print('[ERROR] Error details: $error');
        if (stackTrace != null) {
          print('[ERROR] Stack trace: $stackTrace');
        }
      }
    }
  }

  /// Log de informação estático
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  /// Log de aviso estático
  static void warning(String message) {
    if (kDebugMode) {
      print('[WARNING] $message');
    }
  }

  /// Log de depuração estático
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }
}
