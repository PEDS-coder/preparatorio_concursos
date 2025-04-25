import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/services/local_analytics_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Módulo de injeção de dependência para o serviço de analytics
@module
abstract class AnalyticsModule {
  /// Fornece uma instância de IAnalyticsService
  @singleton
  IAnalyticsService provideAnalyticsService(Logger logger) => LocalAnalyticsService(logger);
}
