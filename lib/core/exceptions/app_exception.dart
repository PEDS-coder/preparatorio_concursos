/// Classe base para todas as exceções do aplicativo
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  final StackTrace? stackTrace;

  AppException(
    this.message, {
    this.code,
    this.details,
    this.stackTrace,
  });

  @override
  String toString() {
    String result = 'AppException';
    if (code != null) {
      result += '[$code]';
    }
    result += ': $message';
    if (details != null) {
      result += '\nDetalhes: $details';
    }
    if (stackTrace != null) {
      result += '\n$stackTrace';
    }
    return result;
  }
}

/// Exceção lançada quando ocorre um erro de rede
class NetworkException extends AppException {
  NetworkException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'NETWORK_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro de autenticação
class AuthException extends AppException {
  AuthException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'AUTH_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro de validação
class ValidationException extends AppException {
  ValidationException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'VALIDATION_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro de API
class ApiException extends AppException {
  final int? statusCode;

  ApiException(
    String message, {
    this.statusCode,
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'API_ERROR',
          details: details,
          stackTrace: stackTrace,
        );

  @override
  String toString() {
    String result = 'ApiException';
    if (code != null) {
      result += '[$code]';
    }
    if (statusCode != null) {
      result += ' (Status: $statusCode)';
    }
    result += ': $message';
    if (details != null) {
      result += '\nDetalhes: $details';
    }
    if (stackTrace != null) {
      result += '\n$stackTrace';
    }
    return result;
  }
}

/// Exceção lançada quando ocorre um erro de processamento de dados
class DataProcessingException extends AppException {
  DataProcessingException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'DATA_PROCESSING_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro de armazenamento
class StorageException extends AppException {
  StorageException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'STORAGE_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro de configuração
class ConfigurationException extends AppException {
  ConfigurationException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'CONFIGURATION_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro de permissão
class PermissionException extends AppException {
  PermissionException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'PERMISSION_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}

/// Exceção lançada quando ocorre um erro desconhecido
class UnknownException extends AppException {
  UnknownException(
    String message, {
    String? code,
    dynamic details,
    StackTrace? stackTrace,
  }) : super(
          message,
          code: code ?? 'UNKNOWN_ERROR',
          details: details,
          stackTrace: stackTrace,
        );
}
