import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/secure_storage_service_interface.dart';
import 'package:preparatorio_concursos/core/services/advanced_cache_service.dart';
import 'package:preparatorio_concursos/core/services/api_config_service.dart';
import 'package:preparatorio_concursos/core/services/background_processor_service.dart';
import 'package:preparatorio_concursos/core/services/cache_service.dart';
import 'package:preparatorio_concursos/core/services/data_loader_service.dart';
import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/services/image_loader_service.dart';
import 'package:preparatorio_concursos/core/services/input_validation_service.dart';
import 'package:preparatorio_concursos/core/services/prompt_service.dart';
import 'package:preparatorio_concursos/core/services/secure_storage_service.dart';
import 'package:preparatorio_concursos/core/services/security_service.dart';
import 'package:preparatorio_concursos/core/services/temp_secure_storage_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

@module
abstract class ServiceModule {
  // Singleton para o Logger
  @singleton
  Logger provideLogger() => Logger();

  // Singleton para o ErrorHandlerService
  @singleton
  ErrorHandlerService provideErrorHandlerService(Logger logger) =>
      ErrorHandlerService(logger);

  // Singleton para o CacheService
  @singleton
  CacheService provideCacheService() => CacheService();

  // Singleton para o AdvancedCacheService
  @singleton
  AdvancedCacheService provideAdvancedCacheService(Logger logger) =>
      AdvancedCacheService(logger);

  // Singleton para o DataLoaderService
  @singleton
  DataLoaderService provideDataLoaderService(Logger logger) =>
      DataLoaderService(logger);

  // Singleton para o ImageLoaderService
  @singleton
  ImageLoaderService provideImageLoaderService(Logger logger) =>
      ImageLoaderService(logger);

  // Singleton para o BackgroundProcessorService
  @singleton
  BackgroundProcessorService provideBackgroundProcessorService(Logger logger) =>
      BackgroundProcessorService(logger);

  // Singleton para o SecureStorageService
  @singleton
  ISecureStorageService provideSecureStorageService(Logger logger) {
    // Usar implementação temporária no Windows para evitar problemas com o flutter_secure_storage
    // No ambiente web, usar a implementação padrão
    if (!kIsWeb && Platform.isWindows) {
      return TempSecureStorageService(logger);
    } else {
      return SecureStorageService(logger);
    }
  }

  // Singleton para o SecurityService
  @singleton
  SecurityService provideSecurityService(ISecureStorageService secureStorage, Logger logger) =>
      SecurityService(secureStorage, logger);

  // Singleton para o InputValidationService
  @singleton
  InputValidationService provideInputValidationService(Logger logger) =>
      InputValidationService(logger);

  // Singleton para o AnalyticsService
  @singleton
  IAnalyticsService provideAnalyticsService(Logger logger) =>
      AnalyticsService(logger);

  // Singleton para o RemoteConfigService
  @singleton
  RemoteConfigService provideRemoteConfigService(Logger logger, AnalyticsService analyticsService) =>
      RemoteConfigService(logger, analyticsService);

  // Singleton para o FeedbackService
  @singleton
  FeedbackService provideFeedbackService(
    Logger logger,
    AnalyticsService analyticsService,
    RemoteConfigService remoteConfigService
  ) => FeedbackService(logger, analyticsService, remoteConfigService);

  // Singleton para o NavigationService
  @singleton
  NavigationService provideNavigationService(
    Logger logger,
    AnalyticsService analyticsService
  ) => NavigationService(logger, analyticsService);

  // Singleton para o ThemeService
  @singleton
  ThemeService provideThemeService(
    Logger logger,
    AnalyticsService analyticsService
  ) => ThemeService(logger, analyticsService);

  // Singleton para o CalendarService
  @singleton
  CalendarService provideCalendarService(
    Logger logger,
    AnalyticsService analyticsService
  ) => CalendarService(logger, analyticsService);

  // Singleton para o ShareService
  @singleton
  ShareService provideShareService(
    Logger logger,
    AnalyticsService analyticsService
  ) => ShareService(logger, analyticsService);

  // Singleton para o PromptService
  @singleton
  PromptService providePromptService(
    CacheService cacheService,
    Logger logger
  ) => PromptService(cacheService: cacheService, logger: logger);

  // Singleton para o ApiConfigService
  @singleton
  ApiConfigService provideApiConfigService(
    ISecureStorageService secureStorage,
    Logger logger
  ) => ApiConfigService(secureStorage, logger);
}
