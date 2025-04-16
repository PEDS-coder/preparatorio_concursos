import 'package:flutter/foundation.dart';

/// Classe utilitária para logging na aplicação
class AppLogger {
  /// Log de informação
  static void i(String tag, String message) {
    if (kDebugMode) {
      print('INFO [$tag]: $message');
    }
  }

  /// Log de aviso
  static void w(String tag, String message) {
    if (kDebugMode) {
      print('WARN [$tag]: $message');
    }
  }

  /// Log de erro
  static void e(String tag, String message, [dynamic error]) {
    if (kDebugMode) {
      print('ERROR [$tag]: $message');
      if (error != null) {
        print('ERROR DETAILS: $error');
      }
    }
  }

  /// Log de depuração
  static void d(String tag, String message) {
    if (kDebugMode) {
      print('DEBUG [$tag]: $message');
    }
  }
}
