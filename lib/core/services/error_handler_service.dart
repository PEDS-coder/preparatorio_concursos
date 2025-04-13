import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../exceptions/app_exception.dart';
import '../utils/logger.dart';

/// Interface para o serviço de tratamento de erros
abstract class ErrorHandlerServiceInterface {
  /// Captura e processa uma exceção
  Future<void> handleException(dynamic error, {StackTrace? stackTrace, String? context});
  
  /// Converte uma exceção em uma AppException
  AppException convertToAppException(dynamic error, {StackTrace? stackTrace, String? context});
  
  /// Registra uma exceção no sistema de logs
  void logException(AppException exception, {String? context});
  
  /// Exibe uma mensagem de erro para o usuário
  void showErrorMessage(String message);
}

/// Implementação do serviço de tratamento de erros
class ErrorHandlerService implements ErrorHandlerServiceInterface {
  final Logger _logger;
  
  ErrorHandlerService(this._logger);
  
  @override
  Future<void> handleException(dynamic error, {StackTrace? stackTrace, String? context}) async {
    // Converte o erro para uma AppException
    final appException = convertToAppException(error, stackTrace: stackTrace, context: context);
    
    // Registra a exceção
    logException(appException, context: context);
    
    // Exibe uma mensagem de erro para o usuário
    showErrorMessage(_getUserFriendlyMessage(appException));
  }
  
  @override
  AppException convertToAppException(dynamic error, {StackTrace? stackTrace, String? context}) {
    // Captura a stack trace se não for fornecida
    stackTrace ??= StackTrace.current;
    
    // Converte diferentes tipos de erro para AppException
    if (error is AppException) {
      // Já é uma AppException, apenas retorna
      return error;
    } else if (error is SocketException || error is TimeoutException) {
      // Erro de rede
      return NetworkException(
        'Erro de conexão. Verifique sua internet e tente novamente.',
        details: error.toString(),
        stackTrace: stackTrace,
      );
    } else if (error is FormatException) {
      // Erro de formato de dados
      return DataProcessingException(
        'Erro ao processar dados. Formato inválido.',
        details: error.toString(),
        stackTrace: stackTrace,
      );
    } else if (error is FileSystemException) {
      // Erro de sistema de arquivos
      return StorageException(
        'Erro ao acessar arquivos do sistema.',
        details: error.toString(),
        stackTrace: stackTrace,
      );
    } else {
      // Erro desconhecido
      return UnknownException(
        'Ocorreu um erro inesperado.',
        details: error.toString(),
        stackTrace: stackTrace,
      );
    }
  }
  
  @override
  void logException(AppException exception, {String? context}) {
    final contextInfo = context != null ? ' [Contexto: $context]' : '';
    
    // Log com nível apropriado baseado no tipo de exceção
    if (exception is NetworkException) {
      _logger.warning('${exception.toString()}$contextInfo');
    } else if (exception is ValidationException) {
      _logger.info('${exception.toString()}$contextInfo');
    } else if (exception is AuthException) {
      _logger.warning('${exception.toString()}$contextInfo');
    } else if (exception is ApiException) {
      if (exception.statusCode != null && exception.statusCode! >= 500) {
        _logger.error('${exception.toString()}$contextInfo');
      } else {
        _logger.warning('${exception.toString()}$contextInfo');
      }
    } else {
      _logger.error('${exception.toString()}$contextInfo');
    }
    
    // Em modo de desenvolvimento, imprime a stack trace completa
    if (kDebugMode) {
      print('Exception details: ${exception.toString()}');
      if (exception.stackTrace != null) {
        print('Stack trace: ${exception.stackTrace}');
      }
    }
  }
  
  @override
  void showErrorMessage(String message) {
    // Esta implementação será substituída por uma que usa o sistema de UI
    // Por enquanto, apenas imprime a mensagem
    if (kDebugMode) {
      print('ERROR: $message');
    }
    
    // Aqui seria implementada a lógica para mostrar um snackbar, dialog, etc.
  }
  
  /// Retorna uma mensagem amigável para o usuário com base no tipo de exceção
  String _getUserFriendlyMessage(AppException exception) {
    if (exception is NetworkException) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    } else if (exception is ValidationException) {
      return exception.message; // Mensagens de validação já são amigáveis
    } else if (exception is AuthException) {
      return 'Erro de autenticação. Por favor, faça login novamente.';
    } else if (exception is ApiException) {
      if (exception.statusCode != null) {
        if (exception.statusCode! >= 500) {
          return 'O servidor está com problemas. Tente novamente mais tarde.';
        } else if (exception.statusCode! == 404) {
          return 'O recurso solicitado não foi encontrado.';
        } else if (exception.statusCode! == 401 || exception.statusCode! == 403) {
          return 'Você não tem permissão para acessar este recurso.';
        }
      }
      return 'Erro ao comunicar com o servidor. Tente novamente.';
    } else if (exception is DataProcessingException) {
      return 'Erro ao processar dados. Por favor, tente novamente.';
    } else if (exception is StorageException) {
      return 'Erro ao acessar armazenamento. Verifique as permissões do aplicativo.';
    } else if (exception is ConfigurationException) {
      return 'Erro de configuração. Por favor, reinicie o aplicativo.';
    } else if (exception is PermissionException) {
      return 'Permissão negada. Verifique as configurações do seu dispositivo.';
    } else {
      return 'Ocorreu um erro inesperado. Por favor, tente novamente.';
    }
  }
}

/// Função global para facilitar o tratamento de erros em qualquer parte do código
Future<T> runWithErrorHandling<T>(
  Future<T> Function() function,
  ErrorHandlerServiceInterface errorHandler, {
  String? context,
}) async {
  try {
    return await function();
  } catch (error, stackTrace) {
    await errorHandler.handleException(error, stackTrace: stackTrace, context: context);
    rethrow; // Propaga o erro para que o chamador possa lidar com ele se necessário
  }
}
