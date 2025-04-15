import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// Comentado temporariamente para resolver problemas de compilação
// import 'service_locator.config.dart';

final GetIt getIt = GetIt.instance;

// @InjectableInit(
//   initializerName: 'init', // default
//   preferRelativeImports: true, // default
//   asExtension: true, // changed to true
// )
void configureDependencies() {
  // Comentado temporariamente para resolver problemas de compilação
  // getIt.init();

  // Registrar manualmente os serviços necessários
  // getIt.registerFactory(() => IAService());
}
