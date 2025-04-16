import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/repositories/edital_repository.dart';
import 'package:preparatorio_concursos/core/data/repositories/plano_estudo_repository.dart';
import 'package:preparatorio_concursos/core/data/repositories/user_repository.dart';
import 'package:preparatorio_concursos/core/di/service_locator.dart';

@module
abstract class RepositoryModule {
  // Singleton para o EditalRepository
  @singleton
  EditalRepository provideEditalRepository() => EditalRepository(
    logger: getIt.get(),
  );

  // Singleton para o PlanoEstudoRepository
  @singleton
  PlanoEstudoRepository providePlanoEstudoRepository() => PlanoEstudoRepository(
    logger: getIt.get(),
  );

  // Singleton para o UserRepository
  @singleton
  UserRepository provideUserRepository() => UserRepository(
    logger: getIt.get(),
  );
}
