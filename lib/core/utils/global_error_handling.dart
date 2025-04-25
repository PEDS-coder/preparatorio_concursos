import 'package:preparatorio_concursos/core/services/error_handler_service.dart';

/// Função global para executar uma operação com tratamento de erro
Future<T> runWithErrorHandling<T>(
  Future<T> Function() operation,
  ErrorHandlerService errorHandler, {
  String context = '',
}) async {
  try {
    return await operation();
  } catch (e) {
    final appException = errorHandler.convertToAppException(e);
    throw appException;
  }
}
