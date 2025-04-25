import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/data/services/interfaces/ia_service_interface.dart';
import '../../../core/utils/logger.dart';
import '../../data/models/flashcard.dart';
import 'ia_service_implementations.dart';

class IAService extends ChangeNotifier with IAServiceImplementations implements IAServiceInterface {
  final Logger _logger = Logger();
  String _apiKey = '';
  String _apiType = 'gemini'; // Padrão para Gemini
  bool _isConfigured = false;

  // Getters
  @override
  String? get apiKey => _apiKey;
  @override
  String get apiType => _apiType;
  @override
  bool get isConfigured => _isConfigured;

  // Inicializar o cache
  @override
  Future<void> initCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedApiKey = prefs.getString('api_key');
      final savedApiType = prefs.getString('api_type');

      if (savedApiKey != null && savedApiKey.isNotEmpty) {
        _apiKey = savedApiKey;
        _isConfigured = true;
      }

      if (savedApiType != null && savedApiType.isNotEmpty) {
        _apiType = savedApiType;
      }

      _logger.info('IAService: Cache inicializado com sucesso');
    } catch (e) {
      _logger.error('IAService: Erro ao inicializar cache: $e');
    }
  }

  // Configurar API Key
  @override
  Future<bool> configurarApiKey(String apiKey) async {
    try {
      if (apiKey.isEmpty) {
        _logger.warning('IAService: API Key vazia');
        return false;
      }

      _apiKey = apiKey;
      _isConfigured = true;

      // Salvar no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', apiKey);

      _logger.info('IAService: API Key configurada com sucesso');
      notifyListeners();
      return true;
    } catch (e) {
      _logger.error('IAService: Erro ao configurar API Key: $e');
      return false;
    }
  }

  // Configurar API Key sem validação
  void configurarApiKeySemValidacao(String apiKey) {
    _apiKey = apiKey;
    _isConfigured = true;
    notifyListeners();
  }

  // Definir o tipo de API
  @override
  Future<void> setApiType(String apiType) async {
    try {
      _apiType = apiType;

      // Salvar no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_type', apiType);

      _logger.info('IAService: Tipo de API configurado para $apiType');
      notifyListeners();
    } catch (e) {
      _logger.error('IAService: Erro ao configurar tipo de API: $e');
    }
  }

  // Limpar configuração
  Future<void> limparConfiguracao() async {
    try {
      _apiKey = '';
      _isConfigured = false;

      // Remover do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_key');

      _logger.info('IAService: Configuração limpa com sucesso');
      notifyListeners();
    } catch (e) {
      _logger.error('IAService: Erro ao limpar configuração: $e');
    }
  }

  // Método para analisar texto (stub)
  @override
  Future<String> analisarTexto(String texto, {String? prompt}) async {
    if (!_isConfigured) {
      _logger.warning('IAService: Serviço não configurado');
      return 'Erro: Serviço de IA não configurado';
    }

    // Implementação básica
    return 'Análise simulada do texto: ${texto.substring(0, texto.length > 50 ? 50 : texto.length)}...';
  }

  // Método para gerar texto (stub)
  @override
  Future<String> gerarTexto(String prompt) async {
    if (!_isConfigured) {
      _logger.warning('IAService: Serviço não configurado');
      return 'Erro: Serviço de IA não configurado';
    }

    // Implementação básica
    return 'Texto gerado a partir do prompt: ${prompt.substring(0, prompt.length > 50 ? 50 : prompt.length)}...';
  }

  @override
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) async {
    try {
      _apiKey = apiKey;
      _apiType = apiType;
      _isConfigured = true;

      // Salvar no SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_key', apiKey);
      await prefs.setString('api_type', apiType);

      notifyListeners();
      return {'success': true, 'message': 'API configurada com sucesso'};
    } catch (e) {
      return {'success': false, 'message': 'Erro ao configurar API: $e'};
    }
  }

  @override
  Future<bool> testApiKey(String apiKey, String apiType) async {
    // Implementação simulada
    return apiKey.isNotEmpty;
  }

  @override
  Future<bool> testApiConnection() async {
    // Implementação simulada
    return _isConfigured;
  }

  @override
  Future<Map<String, dynamic>> configureOAuth(String clientId, String clientSecret) async {
    // Implementação simulada
    return {'success': true, 'message': 'OAuth configurado com sucesso'};
  }

  @override
  Future<Map<String, dynamic>> authenticateWithGoogle() async {
    // Implementação simulada
    return {'success': true, 'message': 'Autenticado com Google com sucesso'};
  }

  @override
  Future<String> callApi(String prompt) async {
    // Implementação simulada
    return 'Resposta da API para: ${prompt.substring(0, prompt.length > 30 ? 30 : prompt.length)}...';
  }

  @override
  Future<String> callApiWithPrompt(String prompt) async {
    return callApi(prompt);
  }

  @override
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt) async {
    // Implementação simulada
    return {'resposta': 'Resposta simulada para: $prompt'};
  }

  @override
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName}) async {
    // Implementação simulada
    return 'Análise simulada do edital ${pdfName ?? "sem nome"}';
  }

  @override
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName}) async {
    // Implementação simulada
    return 'Cargos simulados do edital ${pdfName ?? "sem nome"}';
  }

  @override
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) async {
    // Implementação simulada
    return 'Informações básicas simuladas do edital ${pdfName ?? "sem nome"}';
  }

  @override
  Future<Map<String, dynamic>> extrairConcursoConteudo({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) async {
    // Implementação simulada
    return {
      'concurso': {
        'cargo': cargoAlvo,
        'conteudo_programatico': {
          'Gerais': ['Português Simulado', 'Raciocínio Lógico Simulado'],
          'Específicas': ['Conhecimento Específico Simulado 1', 'Conhecimento Específico Simulado 2']
        }
      }
    };
  }

  @override
  Future<String> extrairConteudoProgramatico({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) async {
    // Implementação simulada
    return 'Conteúdo programático simulado para o cargo $cargoAlvo';
  }

  @override
  Future<String> gerarResumo(String texto) async {
    // Implementação simulada
    return 'Resumo simulado do texto: ${texto.substring(0, texto.length > 30 ? 30 : texto.length)}...';
  }

  @override
  Future<String> gerarEsquema({required String texto, String? titulo}) async {
    // Implementação simulada
    return 'Esquema simulado para ${titulo ?? "texto"}: ${texto.substring(0, texto.length > 30 ? 30 : texto.length)}...';
  }

  @override
  Future<String> gerarQuestoes({required String texto, required String materia, required String dificuldade, required int quantidade}) async {
    // Implementação simulada
    return '$quantidade questões simuladas de $materia com dificuldade $dificuldade';
  }

  @override
  Future<List<Flashcard>> gerarFlashcards({required String userId, String? editalId, required String materia, required String texto}) async {
    // Implementação simulada
    return [
      Flashcard(
        id: '1',
        userId: userId,
        editalId: editalId,
        materia: materia,
        pergunta: 'Pergunta simulada 1',
        resposta: 'Resposta simulada 1',
        fonte: 'ia',
      ),
      Flashcard(
        id: '2',
        userId: userId,
        editalId: editalId,
        materia: materia,
        pergunta: 'Pergunta simulada 2',
        resposta: 'Resposta simulada 2',
        fonte: 'ia',
      ),
    ];
  }

  @override
  bool isWithinTokenLimit(String texto) {
    // Implementação simulada
    return texto.length < 10000;
  }

  @override
  Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('api_key');
      await prefs.remove('api_type');
      return true;
    } catch (e) {
      return false;
    }
  }

  // Método adicional para extrair cargos detalhados
  Future<String> extrairCargosDetalhados(Uint8List pdfBytes, {String? pdfName}) async {
    // Implementação simulada
    return 'Cargos detalhados simulados do edital ${pdfName ?? "sem nome"}';
  }

  // Método para gerar plano de estudos
  @override
  Future<String> gerarPlanoEstudos({required String cargoAlvo, required Map<String, dynamic> dadosCargo}) async {
    if (!_isConfigured) {
      _logger.warning('IAService: Serviço não configurado');
      return 'Erro: Serviço de IA não configurado';
    }

    // Implementação simulada
    return '{"ciclo_estudos": [{"dia": 1, "blocos": [{"ordem": 1, "materia": "Português", "duracao_minutos": 90, "ferramenta": "Videoaulas"}]}], "materias_prioritarias": [{"nome": "Português", "pontuacao_prioridade": 31}]}';
  }

  @override
  Future<String> processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    // Implementação simulada
    return 'Processamento simulado do PDF ${pdfName ?? "sem nome"} com prompt: ${prompt.substring(0, prompt.length > 30 ? 30 : prompt.length)}...';
  }
}
