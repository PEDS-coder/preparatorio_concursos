import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import 'interfaces/ia_service_interface.dart';
import 'ia_service_factory.dart';
import 'base_ia_service.dart';
import 'gemini_service.dart';
import '../../utils/logger_adapter.dart';

/// Classe principal para interação com serviços de IA
/// Atua como uma fachada (facade) para as implementações específicas
class IAService extends ChangeNotifier implements IAServiceInterface {
  // Instância do serviço de IA atual
  late IAServiceInterface _currentService;

  // Fábrica de serviços de IA
  final IAServiceFactory _factory = IAServiceFactory();

  // Construtor
  IAService() {
    // Inicializar com o serviço padrão (Gemini)
    _currentService = _factory.getDefaultService();

    // Escutar mudanças no serviço atual
    if (_currentService is ChangeNotifier) {
      (_currentService as ChangeNotifier).addListener(_onServiceChanged);
    }
  }

  // Método para lidar com mudanças no serviço atual
  void _onServiceChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    // Remover listener do serviço atual
    if (_currentService is ChangeNotifier) {
      (_currentService as ChangeNotifier).removeListener(_onServiceChanged);
    }
    super.dispose();
  }

  // Método para trocar o serviço atual
  void switchService(String apiType) {
    // Remover listener do serviço atual
    if (_currentService is ChangeNotifier) {
      (_currentService as ChangeNotifier).removeListener(_onServiceChanged);
    }

    // Obter nova instância do serviço
    _currentService = _factory.createService(apiType);

    // Adicionar listener ao novo serviço
    if (_currentService is ChangeNotifier) {
      (_currentService as ChangeNotifier).addListener(_onServiceChanged);
    }

    notifyListeners();
  }

  @override
  bool get isConfigured => _currentService.isConfigured;

  @override
  String get apiType => _currentService.apiType;

  @override
  String? get apiKey => _currentService.apiKey;

  // Método para configurar o tipo de API
  void setApiType(String apiType) {
    switchService(apiType);
  }

  // Getters e setters para controle de cache
  bool get forceCacheMode => _currentService is BaseIAService
      ? (_currentService as BaseIAService).forceCacheMode
      : false;

  void setForceCacheMode(bool value) {
    if (_currentService is BaseIAService) {
      (_currentService as BaseIAService).setForceCacheMode(value);
      notifyListeners();
    }
  }

  @override
  Future<void> initCache() async {
    await _currentService.initCache();
  }

  @override
  Future<bool> clearCache() async {
    return await _currentService.clearCache();
  }

  @override
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) async {
    // Trocar para o serviço correto se necessário
    if (this.apiType != apiType) {
      switchService(apiType);
    }

    // Delegar para o serviço atual
    return await _currentService.setApiKey(apiKey, apiType);
  }

  @override
  bool isWithinTokenLimit(String texto) {
    return _currentService.isWithinTokenLimit(texto);
  }

  @override
  Future<bool> configurarApiKey(String apiKey) async {
    return await _currentService.configurarApiKey(apiKey);
  }

  @override
  Future<String> callApiWithPrompt(String prompt) async {
    return await _currentService.callApiWithPrompt(prompt);
  }

  // Método para analisar JSON da resposta
  dynamic parseJsonResponse(String jsonString) {
    if (_currentService is BaseIAService) {
      return (_currentService as BaseIAService).parseJsonResponse(jsonString);
    } else {
      try {
        return json.decode(jsonString);
      } catch (e) {
        AppLogger.e('IAService', 'Erro ao fazer parse do JSON', e);
        throw Exception('Resposta não é um JSON válido: $e');
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt) async {
    return await _currentService.gerarRespostaJson(prompt);
  }

  @override
  Future<List<Flashcard>> gerarFlashcards(
    String userId,
    String? editalId,
    String materia,
    String texto,
  ) async {
    return await _currentService.gerarFlashcards(userId, editalId, materia, texto);
  }

  @override
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName}) async {
    return await _currentService.analisarEditalPdf(pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName}) async {
    return await _currentService.extrairCargosEdital(pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) async {
    return await _currentService.extrairInfoBasicasEdital(pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairConcursoConteudo(Uint8List pdfBytes, String cargoAlvo, {String? pdfName}) async {
    return await _currentService.extrairConcursoConteudo(pdfBytes, cargoAlvo, pdfName: pdfName);
  }

  @override
  Future<String> extrairConteudoProgramatico(Uint8List pdfBytes, String cargoAlvo, {String? pdfName}) async {
    return await _currentService.extrairConteudoProgramatico(pdfBytes, cargoAlvo, pdfName: pdfName);
  }

  @override
  Future<String> gerarResumo(String texto) async {
    return await _currentService.gerarResumo(texto);
  }

  @override
  Future<String> gerarEsquema(String texto, {String? titulo}) async {
    return await _currentService.gerarEsquema(texto, titulo: titulo);
  }

  @override
  Future<String> gerarQuestoes(String texto, String materia, String dificuldade, int quantidade) async {
    return await _currentService.gerarQuestoes(texto, materia, dificuldade, quantidade);
  }

  @override
  Future<String> callApi(String prompt) async {
    return await _currentService.callApi(prompt);
  }

  // Método para chamar a API do Gemini com PDF
  Future<String> callGeminiApiWithPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    if (_currentService is GeminiService) {
      return await (_currentService as GeminiService).callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
    } else {
      throw Exception('O serviço atual não suporta processamento de PDF');
    }
  }

}

