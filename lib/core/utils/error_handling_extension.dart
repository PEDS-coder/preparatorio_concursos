import 'package:preparatorio_concursos/core/data/repositories/base_repository.dart';
import 'package:preparatorio_concursos/core/utils/global_error_handling.dart' as global_error;

/// Extensão para facilitar o uso do runWithErrorHandling
extension ErrorHandlingExtension on BaseRepository {
  /// Executa uma função com tratamento de erros
  Future<T> runWithErrorHandlingExt<T>(
    Future<T> Function() function, {
    String? context,
  }) async {
    try {
      return await function();
    } catch (e) {
      // Temporariamente simplificado para evitar problemas de injeção de dependência
      print('Erro em $tag${context != null ? ' ($context)' : ''}: $e');
      rethrow;
    }
  }
}
