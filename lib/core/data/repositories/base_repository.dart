import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Classe base para todos os repositórios
abstract class BaseRepository {
  final Logger logger;
  final ErrorHandlerService errorHandler;
  final String _tag;

  BaseRepository({
    required this.logger,
    required this.errorHandler,
    required String tag,
  }) : _tag = tag;

  /// Executa uma operação com tratamento de erro
  Future<T> runWithErrorHandling<T>(
    Future<T> Function() operation, {
    String context = '',
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      logger.error(
        'Erro em $context',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      final appException = errorHandler.convertToAppException(e);
      throw appException;
    }
  }
}
