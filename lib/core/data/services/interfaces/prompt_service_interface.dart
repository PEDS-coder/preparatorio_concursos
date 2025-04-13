/// Interface para serviços de prompt
abstract class PromptServiceInterface {
  /// Carrega um prompt para análise de edital em PDF
  Future<String> loadPdfEditalAnalysisPrompt();
  
  /// Carrega um prompt para extração de cargos de edital
  Future<String> loadCargosEditalPrompt();
  
  /// Carrega um prompt para extração de informações básicas de edital
  Future<String> loadBasicInfoEditalPrompt();
  
  /// Carrega um prompt para extração de informações básicas de edital em formato JSON
  Future<String> loadJsonEditalAnalysisPrompt();
  
  /// Carrega um prompt de fallback para extração de informações básicas de edital
  Future<String> loadFallbackBasicInfoPrompt();
  
  /// Carrega um prompt para extração de dados do concurso e conteúdo programático
  Future<String> loadConcursoConteudoPrompt();
  
  /// Carrega um prompt para extração de conteúdo programático em formato JSON
  Future<String> loadContentJsonPrompt();
  
  /// Carrega um prompt para extração de conteúdo programático
  Future<String> loadContentEditalPrompt();
  
  /// Carrega um prompt de fallback para extração de informações de cargo
  Future<String> loadFallbackCargoInfoPrompt();
  
  /// Carrega um prompt para geração de resumo
  Future<String> loadSummaryGenerationPrompt();
  
  /// Carrega um prompt para geração de mapa mental
  Future<String> loadMindmapGenerationPrompt();
  
  /// Carrega um prompt para geração de questões
  Future<String> loadQuestionGenerationPrompt();
  
  /// Carrega um prompt para geração de flashcards
  Future<String> loadFlashcardGenerationPrompt();
  
  /// Personaliza um prompt com variáveis
  String customizePrompt(String promptTemplate, Map<String, String> variables);
}
