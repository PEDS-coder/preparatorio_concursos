import 'dart:typed_data';
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

  /// Testa se a chave de API é válida
  Future<bool> testApiKey(String apiKey, String apiType);

  /// Chama a API com um prompt
  Future<String> callApi(String prompt);

  /// Chama a API com um prompt (método público para uso em outros serviços)
  Future<String> callApiWithPrompt(String prompt);

  /// Gera uma resposta em formato JSON
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt);

  /// Analisa um edital a partir de um PDF
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName});

  /// Extrai cargos de um edital
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName});

  /// Extrai informações básicas de um edital
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName});

  /// Extrai dados do concurso e conteúdo programático para um cargo específico
  Future<String> extrairConcursoConteudo({
    required Uint8List pdfBytes,
    required String cargoAlvo,
    String? pdfName,
  });

  /// Extrai conteúdo programático para um cargo específico
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
}
