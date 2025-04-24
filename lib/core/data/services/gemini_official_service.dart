import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:preparatorio_concursos/core/data/services/base_ia_service.dart';
import 'package:preparatorio_concursos/core/data/models/flashcard.dart';
import 'package:preparatorio_concursos/core/services/prompt_service.dart';
import 'package:preparatorio_concursos/core/utils/app_logger.dart';
import 'ia_service_implementations.dart';

/// Implementação oficial do serviço de IA para o Gemini
class GeminiOfficialService extends BaseIAService with IAServiceImplementations {
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  String _geminiModel = 'gemini-2.5-pro-exp-03-25';
  final List<String> _geminiModelsAlternatives = [
    'gemini-2.5-pro-exp-03-25',
  ];

  final PromptService _promptService = PromptService();

  GeminiOfficialService() : super('gemini_official');

  @override
  bool get isConfigured => apiKey_ != null && apiKey_!.isNotEmpty;

  @override
  String get apiType => 'gemini_official';

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
        'maxOutputTokens': 65536,
        'topP': 0.2,
      },
      'thinking': true,
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
  Future<String> analisarTexto(String texto, {String? prompt}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptFinal = prompt ?? 'Analise o seguinte texto e forneça insights relevantes:\n\n$texto';
    return await callApi(promptFinal);
  }

  @override
  Future<String> gerarTexto(String prompt) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    return await callApi(prompt);
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
  Future<String> extrairCargosDetalhados(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadCargosEditalPrompt();
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

  @override
  Future<String> gerarPlanoEstudos({required String cargoAlvo, required Map<String, dynamic> dadosCargo}) async {
    if (!isConfigured) throw Exception('API Key não configurada');

    try {
      // Carregar o prompt para geração de ciclo de estudos
      final promptTemplate = await _promptService.loadStudyPlanCycleGenerationPrompt();

      // Preparar os dados para o prompt
      final DateTime dataInicio = DateTime.now();
      final DateTime dataFim = dataInicio.add(Duration(days: 90)); // 3 meses por padrão
      final int totalDias = dataFim.difference(dataInicio).inDays;

      // Extrair apenas as matérias do cargo
      final List<String> materias = dadosCargo['materias'] as List<String>? ?? [];

      // Personalizar o prompt com os dados do cargo
      final Map<String, String> variables = {
        'dados_concurso': json.encode(dadosCargo),
        'data_inicio': '${dataInicio.day}/${dataInicio.month}/${dataInicio.year}',
        'data_fim': '${dataFim.day}/${dataFim.month}/${dataFim.year}',
        'total_dias': totalDias.toString(),
        'disponibilidade_semanal': 'Segunda a Sexta: 2 horas por dia\nSábado e Domingo: 4 horas por dia',
        'horarios_especificos': 'Segunda a Sexta: 19h às 21h\nSábado e Domingo: 14h às 18h',
        'materias_cargo': materias.join(', '),
        'proficiencia_materias': materias.map((m) => '$m: Iniciante').join('\n'),
        'ferramentas_estudo': 'Videoaulas, PDFs/Livros, Plataformas de Questões',
        'peso_materias': materias.map((m) => '$m: 1').join('\n'),
        'criterios_desempate': 'Português, Legislação',
        'numero_questoes': materias.map((m) => '$m: 10').join('\n'),
      };

      final prompt = _promptService.customizePrompt(promptTemplate, variables);
      return await callApi(prompt);
    } catch (e) {
      throw Exception('Erro ao gerar plano de estudos: $e');
    }
  }

  Future<String> callGeminiApiWithPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Verificar conectividade com a internet antes de fazer a chamada
      final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$apiKey_';
      final String pdfBase64 = base64Encode(pdfBytes);
      final String fileName = pdfName ?? 'edital.pdf';

      // Log para depuração
      print('[GeminiOfficialService] Enviando PDF para análise: ${fileName} (${pdfBytes.length} bytes)');

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
          'maxOutputTokens': 65536,
          'topP': 0.2,
        }
      };
      final body = jsonEncode(requestBody);

      // Log para depuração
      print('[GeminiOfficialService] Enviando requisição para: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // Log para depuração
      print('[GeminiOfficialService] Resposta recebida: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        // Log para depuração
        print('[GeminiOfficialService] Estrutura da resposta: ${jsonResponse.keys.join(', ')}');

        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts') &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty &&
            jsonResponse['candidates'][0]['content']['parts'][0].containsKey('text')) {

          final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          // Log para depuração
          print('[GeminiOfficialService] Texto extraído com sucesso (${text.length} caracteres)');
          return text;
        } else {
          // Resposta com estrutura inesperada, tentar extrair o máximo de informações possível
          print('[GeminiOfficialService] Estrutura de resposta inesperada: ${jsonResponse}');

          // Tentar extrair qualquer texto disponível
          if (jsonResponse.containsKey('candidates') &&
              jsonResponse['candidates'].isNotEmpty) {
            final candidate = jsonResponse['candidates'][0];
            print('[GeminiOfficialService] Candidato encontrado: ${candidate.keys.join(', ')}');

            // Tentar diferentes caminhos para encontrar o texto
            if (candidate.containsKey('content')) {
              final content = candidate['content'];
              if (content is Map && content.containsKey('text')) {
                return content['text'];
              } else if (content is String) {
                return content;
              }
            }
          }

          // Se não conseguir extrair o texto, retornar uma resposta padrão
          return '{"titulo": "Edital não processado", "banca": "Não identificada", "cargos": [{"nome": "Cargo não identificado", "vagas": 0, "salario": 0.0, "escolaridade": "Não identificada"}]}';
        }
      } else {
        // Log para depuração
        print('[GeminiOfficialService] Erro na chamada à API: ${response.statusCode} - ${response.body}');

        // Retornar uma resposta padrão em caso de erro
        return '{"titulo": "Erro ao processar edital", "banca": "Não identificada", "cargos": [{"nome": "Erro: ${response.statusCode}", "vagas": 0, "salario": 0.0, "escolaridade": "Não identificada"}]}';
      }
    } catch (e, stackTrace) {
      // Log para depuração
      print('[GeminiOfficialService] Exceção ao processar PDF: $e');
      print('[GeminiOfficialService] Stack trace: $stackTrace');

      // Retornar uma resposta padrão em caso de exceção
      return '{"titulo": "Exceção ao processar edital", "banca": "Não identificada", "cargos": [{"nome": "Erro: ${e.toString()}", "vagas": 0, "salario": 0.0, "escolaridade": "Não identificada"}]}';
    }
  }
}
