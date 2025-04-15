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
import '../data/services/analytics_service.dart' as _i6;
import '../data/services/gemini_service.dart' as _i7;
import '../data/services/ia_service.dart' as _i8;
import '../data/services/ia_service_factory.dart' as _i9;
import '../services/advanced_cache_service.dart' as _i10;
import '../services/api_config_service.dart' as _i11;
import '../services/background_processor_service.dart' as _i12;
import '../services/calendar_service.dart' as _i13;
import '../services/data_loader_service.dart' as _i14;
import '../services/feedback_service.dart' as _i15;
import '../services/image_loader_service.dart' as _i16;
import '../services/input_validation_service.dart' as _i17;
import '../services/navigation_service.dart' as _i18;
import '../services/remote_config_service.dart' as _i19;
import '../services/secure_storage_service.dart' as _i20;
import '../services/security_service.dart' as _i21;
import '../services/share_service.dart' as _i22;
import '../services/theme_service.dart' as _i23;
import 'modules/service_module.dart' as _i24;

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
    gh.factory<_i3.EditalRepository>(() => _i3.EditalRepository());
    gh.factory<_i4.PlanoEstudoRepository>(() => _i4.PlanoEstudoRepository());
    gh.factory<_i5.UserRepository>(() => _i5.UserRepository());
    gh.factory<_i6.AnalyticsService>(() => _i6.AnalyticsService());
    gh.factory<_i7.GeminiService>(() => _i7.GeminiService());
    gh.factory<_i8.IAService>(() => _i8.IAService());
    gh.factory<_i9.IAServiceFactory>(() => _i9.IAServiceFactory());
    gh.factory<_i10.AdvancedCacheService>(() => _i10.AdvancedCacheService());
    gh.factory<_i11.ApiConfigService>(() => _i11.ApiConfigService());
    gh.factory<_i12.BackgroundProcessorService>(
        () => _i12.BackgroundProcessorService());
    gh.factory<_i13.CalendarService>(() => _i13.CalendarService());
    gh.factory<_i14.DataLoaderService>(() => _i14.DataLoaderService());
    gh.factory<_i15.FeedbackService>(() => _i15.FeedbackService());
    gh.factory<_i16.ImageLoaderService>(() => _i16.ImageLoaderService());
    gh.factory<_i17.InputValidationService>(() => _i17.InputValidationService());
    gh.factory<_i18.NavigationService>(() => _i18.NavigationService());
    gh.factory<_i19.RemoteConfigService>(() => _i19.RemoteConfigService());
    gh.factory<_i20.SecureStorageService>(() => _i20.SecureStorageService());
    gh.factory<_i21.SecurityService>(() => _i21.SecurityService());
    gh.factory<_i22.ShareService>(() => _i22.ShareService());
    gh.factory<_i23.ThemeService>(() => _i23.ThemeService());
    return this;
  }
}

class _$ServiceModule extends _i24.ServiceModule {}
