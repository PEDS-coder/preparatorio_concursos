import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/remote_config_service_interface.dart';
import 'package:preparatorio_concursos/core/services/local_config_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Módulo de injeção de dependência para o serviço de configuração
@module
abstract class ConfigModule {
  /// Fornece uma instância de IRemoteConfigService
  @singleton
  IRemoteConfigService provideRemoteConfigService(
    Logger logger,
    IAnalyticsService analyticsService,
  ) => LocalConfigService(logger, analyticsService);
}
