/// Interface para o serviço de tratamento de erros
abstract class IErrorHandlerService {
  /// Registra um erro
  Future<void> logError(dynamic error, StackTrace? stackTrace, {String? message});

  /// Exibe uma mensagem de erro para o usuário
  void showErrorMessage(String message);

  /// Trata um erro e retorna uma mensagem amigável
  String handleError(dynamic error);
}
