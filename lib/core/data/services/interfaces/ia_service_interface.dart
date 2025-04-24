import 'dart:typed_data';
import 'dart:io';
import '../../models/flashcard.dart';

/// Interface para serviços de IA
abstract class IAServiceInterface {
  /// Verifica se o serviço está configurado
  bool get isConfigured;

  /// Tipo de API (gemini, openai, etc.)
  String get apiType;

  /// Chave da API
  String? get apiKey;

  /// Configura a chave de API
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType);

  /// Configura a chave de API (método simplificado)
  Future<bool> configurarApiKey(String apiKey);

  /// Define o tipo de API a ser usado
  void setApiType(String apiType);

  /// Testa se a chave de API é válida
  Future<bool> testApiKey(String apiKey, String apiType);

  /// Testa a conexão com a API
  Future<bool> testApiConnection();

  /// Configura as credenciais OAuth
  Future<Map<String, dynamic>> configureOAuth(String clientId, String clientSecret);

  /// Autentica com o Google usando OAuth
  Future<Map<String, dynamic>> authenticateWithGoogle();

  /// Chama a API com um prompt
  Future<String> callApi(String prompt);

  /// Chama a API com um prompt (método público para uso em outros serviços)
  Future<String> callApiWithPrompt(String prompt);

  /// Analisa um texto
  Future<String> analisarTexto(String texto, {String? prompt});

  /// Gera um texto a partir de um prompt
  Future<String> gerarTexto(String prompt);

  /// Gera uma resposta em formato JSON
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt);

  /// Analisa um edital a partir de um PDF
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName});

  /// Extrai cargos de um edital
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName});

  /// Extrai informações básicas de um edital
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName});

  /// Extrai cargos detalhados de um edital
  @deprecated
  Future<String> extrairCargosDetalhados(Uint8List pdfBytes, {String? pdfName});

  /// Extrai dados do concurso e conteúdo programático para um cargo específico
  Future<String> extrairConcursoConteudo({
    required Uint8List pdfBytes,
    required String cargoAlvo,
    String? pdfName,
  });

  /// Extrai conteúdo programático para um cargo específico
  @deprecated
  Future<String> extrairConteudoProgramatico({
    required Uint8List pdfBytes,
    required String cargoAlvo,
    String? pdfName,
  });

  /// Gera um resumo a partir de um texto
  Future<String> gerarResumo(String texto);

  /// Gera um esquema/mapa mental a partir de um texto
  Future<String> gerarEsquema({
    required String texto,
    String? titulo,
  });

  /// Gera questões a partir de um texto
  Future<String> gerarQuestoes({
    required String texto,
    required String materia,
    required String dificuldade,
    required int quantidade,
  });

  /// Gera flashcards a partir de um texto
  Future<List<Flashcard>> gerarFlashcards({
    required String userId,
    String? editalId,
    required String materia,
    required String texto,
  });


  /// Verifica se o texto está dentro do limite de tokens para o modelo atual
  bool isWithinTokenLimit(String texto);

  /// Inicializa o cache
  Future<void> initCache();

  /// Limpa o cache
  Future<bool> clearCache();

  /// Gera um plano de estudos para um cargo específico
  Future<String> gerarPlanoEstudos({
    required String cargoAlvo,
    required Map<String, dynamic> dadosCargo,
  });

  /// Analisa um edital na primeira chamada (primeira etapa)
  /// Extrai informações básicas e cargos
  Future<Map<String, dynamic>> analisarEditalPrimeiraChamada(
    List<File> files,
    Function(String, double) onProgress,
  );

  /// Analisa um edital na segunda chamada (segunda etapa)
  /// Extrai informações detalhadas do cargo selecionado
  Future<Map<String, dynamic>> analisarEditalSegundaChamada(
    String editalId,
    String cargoId,
    String cargoNome,
    Function(String, double) onProgress,
  );

  /// Processa um PDF com um prompt personalizado
  Future<String> processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName});
}
