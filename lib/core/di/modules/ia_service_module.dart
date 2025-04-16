import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/gemini_service.dart';

@module
abstract class IAServiceModule {
  // Singleton para o GeminiService
  @singleton
  GeminiService provideGeminiService() => GeminiService();
}
