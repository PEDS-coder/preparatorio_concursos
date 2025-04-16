import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// Importar o arquivo gerado pelo injectable
import 'service_locator.config.dart';

// Importar serviços necessários
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/services/analytics_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init', // default
  preferRelativeImports: true, // default
  asExtension: true, // changed to true
)
void configureDependencies() {
  try {
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
      // Garantir que temos um Logger
      if (!getIt.isRegistered<Logger>()) {
        getIt.registerSingleton<Logger>(Logger());
      }
      getIt.registerSingleton<IAnalyticsService>(AnalyticsService(getIt<Logger>()));
    }
  } catch (e) {
    print('ERRO FATAL ao inicializar injeção de dependência: $e');
  }
}
