import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/base_ia_service.dart';
import 'package:preparatorio_concursos/core/data/services/gemini_service.dart';
import 'package:preparatorio_concursos/core/data/services/ia_service.dart';
import 'package:preparatorio_concursos/core/data/services/ia_service_factory.dart';

@module
abstract class IAServiceModule {
  // Factory para o GeminiService
  @injectable
  GeminiService provideGeminiService() => GeminiService();

  // Factory para o BaseIAService
  @injectable
  BaseIAService provideBaseIAService() => BaseIAService();

  // Singleton para o IAService
  @singleton
  IAService provideIAService() => IAService();

  // Singleton para o IAServiceFactory
  @singleton
  IAServiceFactory provideIAServiceFactory() => IAServiceFactory();
}
