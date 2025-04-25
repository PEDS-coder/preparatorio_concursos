import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// Importar o arquivo gerado pelo injectable
import 'service_locator.config.dart';

// Importar serviços necessários
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/navigation_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/remote_config_service_interface.dart';
import 'package:preparatorio_concursos/core/services/local_analytics_service.dart';
import 'package:preparatorio_concursos/core/services/local_config_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:preparatorio_concursos/core/navigation/navigation_service.dart';
import 'package:preparatorio_concursos/core/data/services/edital_service.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // changed to true
)
void configureDependencies() {
  try {
    // Registrar Logger primeiro para garantir que esteja disponível
    if (!getIt.isRegistered<Logger>()) {
      getIt.registerSingleton<Logger>(Logger());
    }

    // Inicializar os serviços via GetIt.init()
    try {
      getIt.init();
    } catch (e) {
      print('Erro ao inicializar serviços via GetIt.init(): $e');
      // Continuar mesmo com erro
    }

    // Verificar se os serviços essenciais estão registrados
    if (!getIt.isRegistered<IAnalyticsService>()) {
      print('Registrando IAnalyticsService manualmente...');
      getIt.registerSingleton<IAnalyticsService>(LocalAnalyticsService(getIt<Logger>()));
    }

    // Verificar se o RemoteConfigService está registrado
    if (!getIt.isRegistered<IRemoteConfigService>()) {
      print('Registrando IRemoteConfigService manualmente...');
      getIt.registerSingleton<IRemoteConfigService>(
        LocalConfigService(getIt<Logger>(), getIt<IAnalyticsService>())
      );
    }

    // Registrar o EditalService
    if (!getIt.isRegistered<EditalService>()) {
      print('Registrando EditalService manualmente...');
      getIt.registerSingleton<EditalService>(EditalService());
    }

    // Verificar se o NavigationService está registrado
    if (!getIt.isRegistered<NavigationService>()) {
      print('Registrando NavigationService manualmente...');
      final analyticsService = getIt.isRegistered<IAnalyticsService>()
          ? getIt<IAnalyticsService>()
          : LocalAnalyticsService(getIt<Logger>());
      final navigationService = NavigationService(getIt<Logger>(), analyticsService);
      getIt.registerSingleton<NavigationService>(navigationService);

      // Registrar também como INavigationService
      if (!getIt.isRegistered<INavigationService>()) {
        print('Registrando INavigationService manualmente...');
        getIt.registerSingleton<INavigationService>(navigationService);
      }
    }
  } catch (e) {
    print('ERRO FATAL ao inicializar injeção de dependência: $e');
  }
}
