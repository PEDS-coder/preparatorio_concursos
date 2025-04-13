// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../data/repositories/edital_repository.dart' as _i3;
import '../data/repositories/plano_estudo_repository.dart' as _i4;
import '../data/repositories/user_repository.dart' as _i5;
import '../data/services/base_ia_service.dart' as _i6;
import '../data/services/gemini_service.dart' as _i7;
import '../data/services/ia_service.dart' as _i8;
import '../data/services/ia_service_factory.dart' as _i9;
import '../services/cache_service.dart' as _i10;
import '../services/error_handler_service.dart' as _i11;
import '../services/prompt_service.dart' as _i12;
import '../utils/logger.dart' as _i13;
import 'modules/ia_service_module.dart' as _i14;
import 'modules/repository_module.dart' as _i15;
import 'modules/service_module.dart' as _i16;

extension GetItInjectableX on _i1.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i1.GetIt init({
    String? environment,
    _i2.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i2.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final serviceModule = _$ServiceModule();
    final repositoryModule = _$RepositoryModule();
    final iAServiceModule = _$IAServiceModule();
    gh.singleton<_i3.EditalRepository>(repositoryModule.provideEditalRepository());
    gh.singleton<_i4.PlanoEstudoRepository>(
        repositoryModule.providePlanoEstudoRepository());
    gh.singleton<_i5.UserRepository>(repositoryModule.provideUserRepository());
    gh.factory<_i6.BaseIAService>(() => iAServiceModule.provideBaseIAService());
    gh.factory<_i7.GeminiService>(() => iAServiceModule.provideGeminiService());
    gh.singleton<_i8.IAService>(() => iAServiceModule.provideIAService());
    gh.singleton<_i9.IAServiceFactory>(
        () => iAServiceModule.provideIAServiceFactory());
    gh.singleton<_i10.CacheService>(serviceModule.provideCacheService());
    gh.singleton<_i11.ErrorHandlerService>(
        serviceModule.provideErrorHandlerService(gh<_i13.Logger>()));
    gh.singleton<_i12.PromptService>(serviceModule.providePromptService(
      gh<_i10.CacheService>(),
      gh<_i13.Logger>(),
    ));
    gh.singleton<_i13.Logger>(serviceModule.provideLogger());
    return this;
  }
}

class _$ServiceModule extends _i16.ServiceModule {}

class _$RepositoryModule extends _i15.RepositoryModule {}

class _$IAServiceModule extends _i14.IAServiceModule {}
