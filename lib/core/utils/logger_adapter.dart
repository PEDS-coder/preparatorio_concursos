import 'package:flutter/foundation.dart';

/// Classe estática para compatibilidade com o código existente
/// que usa os métodos estáticos do AppLogger antigo
class AppLogger {
  /// Log detalhado para depuração profunda
  static void v(String tag, String message) {
    if (kDebugMode) {
      print('[VERBOSE][$tag] $message');
    }
  }

  /// Log de depuração
  static void d(String tag, String message) {
    if (kDebugMode) {
      print('[DEBUG][$tag] $message');
    }
  }

  /// Log de informação
  static void i(String tag, String message) {
    print('[INFO][$tag] $message');
  }

  /// Log de aviso
  static void w(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    print('[WARNING][$tag] $message');
    if (error != null) {
      print('[WARNING][$tag] Error details: $error');
      if (stackTrace != null) {
        print('[WARNING][$tag] Stack trace: $stackTrace');
      }
    }
  }

  /// Log de erro
  static void e(String tag, String message, [dynamic error, StackTrace? stackTrace]) {
    print('[ERROR][$tag] $message');
    if (error != null) {
      print('[ERROR][$tag] Error details: $error');
      if (stackTrace != null) {
        print('[ERROR][$tag] Stack trace: $stackTrace');
      }
    }
  }

  /// Define o nível de log atual
  static void setLogLevel(int level) {
    // Não faz nada, apenas para compatibilidade
  }
}
