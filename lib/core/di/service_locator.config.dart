// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../data/repositories/edital_repository.dart' as _i160;
import '../data/repositories/plano_estudo_repository.dart' as _i411;
import '../data/repositories/user_repository.dart' as _i977;
import '../data/services/gemini_service.dart' as _i569;
import '../data/services/ia_service.dart' as _i174;
import '../data/services/ia_service_adapter.dart' as _i570;
import '../data/services/interfaces/analytics_service_interface.dart' as _i681;
import '../data/services/interfaces/remote_config_service_interface.dart'
    as _i318;
import '../data/services/interfaces/secure_storage_service_interface.dart'
    as _i300;
import '../navigation/navigation_service.dart' as _i17;
import '../services/advanced_cache_service.dart' as _i730;
import '../services/analytics_service.dart' as _i222;
import '../services/background_processor_service.dart' as _i235;
import '../services/cache_service.dart' as _i717;
import '../services/calendar_service.dart' as _i1004;
import '../services/data_loader_service.dart' as _i692;
import '../services/error_handler_service.dart' as _i490;
import '../services/feedback_service.dart' as _i879;
import '../services/image_loader_service.dart' as _i1018;
import '../services/input_validation_service.dart' as _i61;
import '../services/remote_config_service.dart' as _i858;
import '../services/secure_storage_service.dart' as _i535;
import '../services/security_service.dart' as _i337;
import '../services/share_service.dart' as _i474;
import '../services/temp_secure_storage_service.dart' as _i600;
import '../services/theme_service.dart' as _i982;
import '../utils/logger.dart' as _i221;
import 'modules/analytics_module.dart' as _i327;
import 'modules/ia_service_module.dart' as _i685;
import 'modules/repository_module.dart' as _i554;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final iAServiceModule = _$IAServiceModule();
    final repositoryModule = _$RepositoryModule();
    final analyticsModule = _$AnalyticsModule();
    gh.singleton<_i569.GeminiService>(
        () => iAServiceModule.provideGeminiService());
    gh.singleton<_i160.EditalRepository>(
        () => repositoryModule.provideEditalRepository());
    gh.singleton<_i411.PlanoEstudoRepository>(
        () => repositoryModule.providePlanoEstudoRepository());
    gh.singleton<_i977.UserRepository>(
        () => repositoryModule.provideUserRepository());
    gh.singleton<_i717.CacheService>(() => _i717.CacheService());
    gh.singleton<_i221.Logger>(() => _i221.Logger());
    gh.singleton<_i570.IAServiceAdapter>(
        () => _i570.IAServiceAdapter(gh<_i174.IAService>()));
    gh.singleton<_i681.IAnalyticsService>(
        () => analyticsModule.provideAnalyticsService(gh<_i221.Logger>()));
    gh.singleton<_i337.SecurityService>(() => _i337.SecurityService(
          gh<_i300.ISecureStorageService>(),
          gh<_i221.Logger>(),
        ));
    gh.singleton<_i160.EditalRepository>(
        () => _i160.EditalRepository(logger: gh<_i221.Logger>()));
    gh.singleton<_i411.PlanoEstudoRepository>(
        () => _i411.PlanoEstudoRepository(logger: gh<_i221.Logger>()));
    gh.singleton<_i977.UserRepository>(
        () => _i977.UserRepository(logger: gh<_i221.Logger>()));
    gh.singleton<_i730.AdvancedCacheService>(
        () => _i730.AdvancedCacheService(gh<_i221.Logger>()));
    gh.singleton<_i222.AnalyticsService>(
        () => _i222.AnalyticsService(gh<_i221.Logger>()));
    gh.singleton<_i235.BackgroundProcessorService>(
        () => _i235.BackgroundProcessorService(gh<_i221.Logger>()));
    gh.singleton<_i692.DataLoaderService>(
        () => _i692.DataLoaderService(gh<_i221.Logger>()));
    gh.singleton<_i490.ErrorHandlerService>(
        () => _i490.ErrorHandlerService(gh<_i221.Logger>()));
    gh.singleton<_i1018.ImageLoaderService>(
        () => _i1018.ImageLoaderService(gh<_i221.Logger>()));
    gh.singleton<_i61.InputValidationService>(
        () => _i61.InputValidationService(gh<_i221.Logger>()));
    gh.singleton<_i535.SecureStorageService>(
        () => _i535.SecureStorageService(gh<_i221.Logger>()));
    gh.singleton<_i600.TempSecureStorageService>(
        () => _i600.TempSecureStorageService(gh<_i221.Logger>()));
    gh.singleton<_i17.NavigationService>(() => _i17.NavigationService(
          gh<_i221.Logger>(),
          gh<_i681.IAnalyticsService>(),
        ));
    gh.singleton<_i1004.CalendarService>(() => _i1004.CalendarService(
          gh<_i221.Logger>(),
          gh<_i681.IAnalyticsService>(),
        ));
    gh.singleton<_i858.RemoteConfigService>(() => _i858.RemoteConfigService(
          gh<_i221.Logger>(),
          gh<_i681.IAnalyticsService>(),
        ));
    gh.singleton<_i474.ShareService>(() => _i474.ShareService(
          gh<_i221.Logger>(),
          gh<_i681.IAnalyticsService>(),
        ));
    gh.singleton<_i982.ThemeService>(() => _i982.ThemeService(
          gh<_i221.Logger>(),
          gh<_i681.IAnalyticsService>(),
        ));
    gh.singleton<_i879.FeedbackService>(() => _i879.FeedbackService(
          gh<_i221.Logger>(),
          gh<_i681.IAnalyticsService>(),
          gh<_i318.IRemoteConfigService>(),
        ));
    return this;
  }
}

class _$IAServiceModule extends _i685.IAServiceModule {}

class _$RepositoryModule extends _i554.RepositoryModule {}

class _$AnalyticsModule extends _i327.AnalyticsModule {}
