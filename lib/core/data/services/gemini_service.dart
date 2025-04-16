import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:preparatorio_concursos/core/data/services/base_ia_service.dart';
import 'package:preparatorio_concursos/core/data/models/flashcard.dart';
import 'package:preparatorio_concursos/core/services/prompt_service.dart';

/// Implementação do serviço de IA para o Gemini
class GeminiService extends BaseIAService {
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  String _geminiModel = 'gemini-2.5-pro-exp-03-25';
  final List<String> _geminiModelsAlternatives = [
    'gemini-2.5-pro-exp-03-25',
  ];

  final PromptService _promptService = PromptService();

  GeminiService() : super('gemini');

  @override
  bool get isConfigured => apiKey_ != null && apiKey_!.isNotEmpty;

  @override
  String get apiType => 'gemini';

  @override
  String? get apiKey => apiKey_;

  @override
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) async {
    apiKey_ = apiKey;
    return {'success': true};
  }

  @override
  Future<bool> configurarApiKey(String apiKey) async {
    apiKey_ = apiKey;
    return true;
  }

  @override
  Future<bool> testApiKey(String apiKey, String apiType) async {
    try {
      final url = '$_geminiBaseUrl/${_geminiModelsAlternatives.first}:generateContent?key=$apiKey';
      final testBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': 'Olá, teste de conexão.'}
            ]
          }
        ],
        'generationConfig': {'maxOutputTokens': 10}
      });
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: testBody,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> testApiConnection() async {
    if (!isConfigured) return false;
    return await testApiKey(apiKey_!, apiType);
  }

  @override
  Future<Map<String, dynamic>> configureOAuth(String clientId, String clientSecret) async {
    throw UnimplementedError('configureOAuth não implementado');
  }

  @override
  Future<Map<String, dynamic>> authenticateWithGoogle() async {
    throw UnimplementedError('authenticateWithGoogle não implementado');
  }

  @override
  Future<String> callApi(String prompt) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }
    final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$apiKey_';
    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 2048,
        'topP': 0.95,
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'}
      ]
    };
    final body = jsonEncode(requestBody);
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String text = '';
      if (jsonResponse['candidates'] != null &&
          jsonResponse['candidates'].isNotEmpty &&
          jsonResponse['candidates'][0]['content'] != null &&
          jsonResponse['candidates'][0]['content']['parts'] != null &&
          jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {
        text = jsonResponse['candidates'][0]['content']['parts'][0]['text'] ?? '';
      }
      if (text.isEmpty) {
        throw Exception('Resposta vazia da API Gemini');
      }
      return text;
    } else {
      throw Exception('Falha na chamada da API Gemini: ${response.statusCode} ${response.body}');
    }
  }

  @override
  Future<String> callApiWithPrompt(String prompt) async {
    return await callApi(prompt);
  }

  @override
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt) async {
    final response = await callApi(prompt);
    try {
      return jsonDecode(response) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> gerarResumo(String texto) async {
    final promptTemplate = await _promptService.loadSummaryGenerationPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {'TEXTO': texto});
    return await callApi(prompt);
  }

  @override
  Future<String> gerarQuestoes({required String texto, required String materia, required String dificuldade, required int quantidade}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadQuestionGenerationPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'TEXTO': texto,
      'MATERIA': materia,
      'DIFICULDADE': dificuldade,
      'QUANTIDADE': quantidade.toString(),
    });
    return await callApi(prompt);
  }

  @override
  bool isWithinTokenLimit(String texto) {
    // Implementação simples, ajuste conforme necessário
    return texto.length < 16000;
  }

  @override
  Future<void> initCache() async {}

  @override
  Future<bool> clearCache() async => true;

  @override
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadPdfEditalAnalysisPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {'PDF_NAME': pdfName ?? ''});
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadCargosEditalPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {'PDF_NAME': pdfName ?? ''});
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadBasicInfoEditalPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {'PDF_NAME': pdfName ?? ''});
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairConcursoConteudo({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadConcursoConteudoPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'PDF_NAME': pdfName ?? '',
      'CARGO_ALVO': cargoAlvo,
    });
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairConteudoProgramatico({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadContentEditalPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'PDF_NAME': pdfName ?? '',
      'CARGO_ALVO': cargoAlvo,
    });
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> gerarEsquema({required String texto, String? titulo}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadMindmapGenerationPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'TEXTO': texto,
      'TITULO': titulo ?? '',
    });
    return await callApi(prompt);
  }

  @override
  Future<List<Flashcard>> gerarFlashcards({
    required String userId,
    String? editalId,
    required String materia,
    required String texto,
  }) async {
    // Prompt para geração de flashcards
    final promptTemplate = await _promptService.loadFlashcardGenerationPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'USER_ID': userId,
      'EDITAL_ID': editalId ?? '',
      'MATERIA': materia,
      'TEXTO': texto,
    });
    final response = await callApi(prompt);
    // Aqui espera-se que a resposta seja um JSON de flashcards
    final List<dynamic> jsonList = jsonDecode(response);
    return jsonList.map((json) => Flashcard(
      id: json['id'] ?? '',
      userId: json['userId'] ?? userId,
      editalId: json['editalId'] ?? editalId,
      materia: json['materia'] ?? materia,
      pergunta: json['pergunta'] ?? '',
      resposta: json['resposta'] ?? '',
      fonte: json['fonte'] ?? 'ia',
    )).toList();
  }

  @override
  Future<String> processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  Future<String> callGeminiApiWithPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    // Verificar conectividade com a internet antes de fazer a chamada
    final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$apiKey_';
    final String pdfBase64 = base64Encode(pdfBytes);
    final String fileName = pdfName ?? 'edital.pdf';

    final Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'application/pdf',
                'data': pdfBase64
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.0,
        'maxOutputTokens': 64000,
      }
    };
    final body = jsonEncode(requestBody);
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse.containsKey('candidates') &&
          jsonResponse['candidates'].isNotEmpty &&
          jsonResponse['candidates'][0].containsKey('content') &&
          jsonResponse['candidates'][0]['content'].containsKey('parts') &&
          jsonResponse['candidates'][0]['content']['parts'].isNotEmpty &&
          jsonResponse['candidates'][0]['content']['parts'][0].containsKey('text')) {
        return jsonResponse['candidates'][0]['content']['parts'][0]['text'];
      } else {
        throw Exception('Estrutura de resposta inesperada do Gemini.');
      }
    } else {
      throw Exception('Erro na chamada à API Gemini: ${response.statusCode}');
    }
  }
}
