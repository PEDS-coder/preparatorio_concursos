import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:preparatorio_concursos/core/utils/error_handling_extension.dart';

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

  /// Tag do repositório
  String get tag => _tag;
}
