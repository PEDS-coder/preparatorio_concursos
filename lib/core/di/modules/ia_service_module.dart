import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/gemini_service.dart';
import 'package:preparatorio_concursos/core/data/services/gemini_official_service.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/ia_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/ia_service_factory.dart';

@module
abstract class IAServiceModule {
  // Singleton para o GeminiService
  @singleton
  GeminiService provideGeminiService() => GeminiService();

  // Singleton para o GeminiOfficialService
  @singleton
  GeminiOfficialService provideGeminiOfficialService() => GeminiOfficialService();

  // Singleton para o IAServiceInterface (usando a fábrica)
  @singleton
  @preResolve
  Future<IAServiceInterface> provideIAService() async {
    final factory = IAServiceFactory();
    return await factory.getDefaultService();
  }
}
