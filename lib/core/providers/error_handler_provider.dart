import 'package:flutter/material.dart';
import '../services/error_handler_service.dart';

import '../widgets/error_display_widget.dart';

/// Provedor para o serviço de tratamento de erros
class ErrorHandlerProvider extends InheritedWidget {
  final ErrorHandlerServiceInterface errorHandler;

  const ErrorHandlerProvider({
    Key? key,
    required this.errorHandler,
    required Widget child,
  }) : super(key: key, child: child);

  /// Obtém a instância do provedor
  static ErrorHandlerProvider of(BuildContext context) {
    final ErrorHandlerProvider? result =
        context.dependOnInheritedWidgetOfExactType<ErrorHandlerProvider>();
    assert(result != null, 'No ErrorHandlerProvider found in context');
    return result!;
  }

  /// Obtém o serviço de tratamento de erros
  static ErrorHandlerServiceInterface getErrorHandler(BuildContext context) {
    return of(context).errorHandler;
  }

  /// Exibe uma mensagem de erro em um snackbar
  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    context.showErrorSnackBar(message, onRetry: onRetry);
  }

  /// Exibe um widget de erro em tela cheia
  static Widget showFullScreenError(
    String message, {
    String? title,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplayWidget(
      message: message,
      title: title,
      onRetry: onRetry,
      fullScreen: true,
    );
  }

  /// Exibe um widget de erro em um container
  static Widget showErrorWidget(
    String message, {
    String? title,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplayWidget(
      message: message,
      title: title,
      onRetry: onRetry,
    );
  }

  @override
  bool updateShouldNotify(ErrorHandlerProvider oldWidget) {
    return errorHandler != oldWidget.errorHandler;
  }
}

/// Extensão para facilitar o uso do tratamento de erros
extension ErrorHandlingExtension on BuildContext {
  /// Obtém o serviço de tratamento de erros
  ErrorHandlerServiceInterface get errorHandler =>
      ErrorHandlerProvider.getErrorHandler(this);

  /// Executa uma função com tratamento de erros
  Future<T> runWithErrorHandling<T>(
    Future<T> Function() function, {
    String? context,
    VoidCallback? onError,
  }) async {
    try {
      return await function();
    } catch (error, stackTrace) {
      await errorHandler.handleException(
        error,
        stackTrace: stackTrace,
        context: context,
      );
      if (onError != null) {
        onError();
      }
      rethrow;
    }
  }
}
