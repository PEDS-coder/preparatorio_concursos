import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:preparatorio_concursos/core/utils/error_handling_extension.dart';

/// Classe base para todos os repositórios
abstract class BaseRepository {
  final Logger logger;
  // Temporariamente removido para evitar problemas de injeção de dependência
  // final ErrorHandlerService errorHandler;
  final String _tag;

  BaseRepository({
    required this.logger,
    // Temporariamente removido para evitar problemas de injeção de dependência
    // required this.errorHandler,
    required String tag,
  }) : _tag = tag;

  /// Tag do repositório
  String get tag => _tag;
}
