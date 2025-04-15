import 'package:preparatorio_concursos/core/data/repositories/base_repository.dart';
import 'package:preparatorio_concursos/core/utils/global_error_handling.dart' as global_error;

/// Extensão para facilitar o uso do runWithErrorHandling
extension ErrorHandlingExtension on BaseRepository {
  /// Executa uma função com tratamento de erros
  Future<T> runWithErrorHandlingExt<T>(
    Future<T> Function() function, {
    String? context,
  }) async {
    return await global_error.runWithErrorHandling<T>(
      function,
      errorHandler,
      context: context ?? tag,
    );
  }
}
