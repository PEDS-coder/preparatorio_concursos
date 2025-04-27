import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:preparatorio_concursos/core/data/services/base_ia_service.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/ia_service_interface.dart';
import '../../utils/app_logger.dart';
import 'package:preparatorio_concursos/core/data/models/flashcard.dart';
import 'package:preparatorio_concursos/core/services/prompt_service.dart';
import 'package:preparatorio_concursos/core/services/connectivity_service.dart';
import 'package:preparatorio_concursos/core/services/api_quota_service.dart';
import 'ia_service_implementations.dart';

/// Implementação do serviço de IA para o Gemini
class GeminiService extends BaseIAService with IAServiceImplementations {
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final String _geminiModel = 'gemini-2.5-pro-exp-03-25';
  final List<String> _geminiModelsAlternatives = [
    'gemini-2.5-pro-exp-03-25',
    'gemini-2.5-pro-preview-03-25',
    'gemini-2.5-flash-preview-04-17',
  ];

  final PromptService _promptService = PromptService();
  final ApiQuotaService _quotaService = ApiQuotaService();

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
      print('[GeminiService] Testando chave API: ${apiKey.substring(0, 5)}...');

      // Verificar se a chave API tem o formato correto para o Gemini
      if (!apiKey.startsWith('AI')) {
        print('[GeminiService] Formato de chave API inválido: não começa com "AI"');
        return false;
      }

      // Verificar se o serviço da API está acessível
      print('[GeminiService] Verificando disponibilidade do serviço Gemini...');
      final bool serviceReachable = await ConnectivityService.canReachService('https://generativelanguage.googleapis.com');
      if (!serviceReachable) {
        print('[GeminiService] Serviço Gemini inacessível. Verifique sua conexão com a internet.');
        return false;
      }
      print('[GeminiService] Serviço Gemini acessível.');

      // Tentar cada modelo alternativo até encontrar um que funcione
      for (final modelo in _geminiModelsAlternatives) {
        try {
          print('[GeminiService] Testando modelo: $modelo');
          final url = '$_geminiBaseUrl/$modelo:generateContent?key=$apiKey';
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

          print('[GeminiService] Enviando requisição para: $url');
          final response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: testBody,
          );

          print('[GeminiService] Resposta do modelo $modelo: ${response.statusCode}');

          if (response.statusCode == 200) {
            print('[GeminiService] Teste bem-sucedido com o modelo: $modelo');
            return true;
          } else if (response.statusCode == 400) {
            // Tentar extrair mensagem de erro mais específica
            try {
              final errorJson = jsonDecode(response.body);
              final errorMessage = errorJson['error']?['message'] ?? 'Requisição inválida';
              print('[GeminiService] Erro 400 com modelo $modelo: $errorMessage');

              // Verificar se o erro é relacionado ao modelo não existir
              if (errorMessage.contains('Model not found') ||
                  errorMessage.contains('not found') ||
                  errorMessage.contains('does not exist')) {
                print('[GeminiService] O modelo $modelo não existe ou não está disponível. Tentando próximo modelo...');
                continue;
              }
            } catch (e) {
              print('[GeminiService] Erro 400 com modelo $modelo sem detalhes: ${response.body}');
            }
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            print('[GeminiService] Chave API inválida ou sem permissão para modelo $modelo: ${response.statusCode}');

            // Tentar extrair mensagem de erro mais específica
            try {
              final errorJson = jsonDecode(response.body);
              final errorMessage = errorJson['error']?['message'] ?? 'Acesso negado';
              print('[GeminiService] Detalhes do erro: $errorMessage');

              // Se o erro for específico para este modelo, tentar o próximo
              if (errorMessage.contains('not have permission') && errorMessage.contains(modelo)) {
                print('[GeminiService] Sem permissão para o modelo $modelo. Tentando próximo modelo...');
                continue;
              }
            } catch (e) {
              print('[GeminiService] Não foi possível extrair detalhes do erro: $e');
            }

            // Se a chave é inválida para um modelo, provavelmente é inválida para todos
            return false;
          } else {
            print('[GeminiService] Erro no teste do modelo $modelo: ${response.statusCode} ${response.body}');
          }
        } catch (e) {
          print('[GeminiService] Exceção ao testar modelo $modelo: $e');
          // Continuar tentando outros modelos
        }
      }

      // Se chegou aqui, nenhum modelo funcionou
      print('[GeminiService] Nenhum modelo disponível funcionou com a chave fornecida');
      return false;
    } catch (e) {
      print('[GeminiService] Exceção geral ao testar chave API: $e');
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
  Future<String> analisarTexto(String texto, {String? prompt}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    final String promptFinal = prompt ?? 'Analise o seguinte texto e forneça insights relevantes:\n\n$texto';
    return await callApi(promptFinal);
  }

  @override
  Future<String> gerarTexto(String prompt) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    return await callApi(prompt);
  }



  @override
  Future<String> callApi(String prompt) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    // Verificar se a cota foi excedida
    if (_quotaService.isQuotaExceeded()) {
      throw Exception('Você atingiu o limite de cotas gratuitas do Gemini. Tente novamente mais tarde ou gere uma nova chave API.');
    }

    // Estimar o número de tokens com base no tamanho do prompt
    final int estimatedTokens = (prompt.length / 4).round(); // Estimativa aproximada: 4 caracteres por token

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
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'}
      ]
    };
    final body = jsonEncode(requestBody);

    try {
      // Registrar a requisição antes de enviá-la
      await _quotaService.registerApiRequest(estimatedTokens: estimatedTokens);

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
    } catch (e) {
      // Se for um erro de cota, formatar a mensagem
      if (e.toString().contains('quota') || e.toString().contains('rate limit')) {
        throw Exception('Você atingiu o limite de cotas gratuitas do Gemini. Tente novamente mais tarde ou gere uma nova chave API.');
      }
      rethrow;
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
    final promptTemplate = await _promptService.loadPdfEditalAnalysisPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {'PDF_NAME': pdfName ?? ''});
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadPdfEditalAnalysisPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {'PDF_NAME': pdfName ?? ''});
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  @override
  Future<Map<String, dynamic>> extrairConcursoConteudo({
    required Uint8List pdfBytes,
    required String cargoAlvo,
    String? pdfName,
  }) async {
    if (!isConfigured) throw Exception('API Key não configurada');
    final promptTemplate = await _promptService.loadConcursoConteudoPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'PDF_NAME': pdfName ?? '',
      'CARGO_ALVO': cargoAlvo,
    });
    final String respostaBruta = await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);

    try {
      // Limpar delimitadores de markdown, se presentes
      String respostaLimpa = respostaBruta.trim();
      if (respostaLimpa.startsWith('```json')) {
        respostaLimpa = respostaLimpa.substring(7);
      }
      if (respostaLimpa.endsWith('```')) {
        respostaLimpa = respostaLimpa.substring(0, respostaLimpa.length - 3);
      }
      respostaLimpa = respostaLimpa.trim();

      // Decodificar o JSON
      final Map<String, dynamic> resultadoJson = jsonDecode(respostaLimpa);
      return resultadoJson;
    } catch (e) {
      AppLogger.e('GeminiService', 'Erro ao decodificar JSON da resposta de extrairConcursoConteudo: $e\nResposta Bruta: $respostaBruta');
      // Relança a exceção para que a camada superior possa tratá-la
      // Ou retorna um mapa de erro padrão, dependendo da estratégia de erro
      rethrow; // Ou: return {'erro': 'Falha ao processar resposta da API', 'detalhes': e.toString()};
    }
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
      final DateTime dataFim = dataInicio.add(const Duration(days: 90)); // 3 meses por padrão
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

    // Configuração de retry
    final int maxRetries = 3;
    int retryCount = 0;
    final List<int> retryStatusCodes = [429, 500, 502, 503, 504]; // Códigos que justificam retry

    try {
      // Verificar conectividade com a internet antes de fazer a chamada
      final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$apiKey_';
      final String pdfBase64 = base64Encode(pdfBytes);
      final String fileName = pdfName ?? 'edital.pdf';
      final int pdfSizeKB = pdfBytes.length ~/ 1024;

      print('[GeminiService] Enviando PDF para análise: $fileName ($pdfSizeKB KB)');

      // Verificar se o PDF não é muito grande
      if (pdfSizeKB > 20000) { // 20MB
        print('[GeminiService] AVISO: O PDF é muito grande ($pdfSizeKB KB). Isso pode causar erros na API.');
      }

      // Estimar o número de tokens com base no tamanho do prompt e do PDF
      final int estimatedTokens = (prompt.length / 4).round() + (pdfBytes.length / 100).round();

      // Registrar a requisição ANTES de fazer a chamada à API
      // Isso garante que a requisição seja contabilizada mesmo se houver erros
      await _quotaService.registerApiRequest(estimatedTokens: estimatedTokens);

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

      http.Response? response;

      // Loop de retry
      while (retryCount <= maxRetries) {
        try {
          print('[GeminiService] Enviando requisição para API Gemini' +
                (retryCount > 0 ? ' (tentativa ${retryCount + 1}/$maxRetries)' : ''));

          response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          print('[GeminiService] Resposta recebida: ${response.statusCode}');

          // Se recebemos uma resposta de sucesso ou um erro que não justifica retry, sair do loop
          if (response.statusCode == 200 || !retryStatusCodes.contains(response.statusCode)) {
            break;
          }

          // Se chegamos aqui, é um erro que justifica retry
          retryCount++;

          if (retryCount <= maxRetries) {
            // Calcular tempo de espera com backoff exponencial (2^tentativa segundos)
            final waitTime = Duration(seconds: pow(2, retryCount).toInt());
            print('[GeminiService] Erro ${response.statusCode}, tentando novamente em ${waitTime.inSeconds} segundos...');
            await Future.delayed(waitTime);
          } else {
            print('[GeminiService] Número máximo de tentativas excedido após erros consecutivos.');
          }
        } catch (e) {
          print('[GeminiService] Erro de rede ao chamar API: $e');
          retryCount++;

          if (retryCount <= maxRetries) {
            final waitTime = Duration(seconds: pow(2, retryCount).toInt());
            print('[GeminiService] Tentando novamente em ${waitTime.inSeconds} segundos...');
            await Future.delayed(waitTime);
          } else {
            print('[GeminiService] Número máximo de tentativas excedido após erros de rede.');
            rethrow; // Relançar o erro de rede se excedemos as tentativas
          }
        }
      }

      // Verificar se temos uma resposta
      if (response == null) {
        throw Exception('Falha na comunicação com a API Gemini após $maxRetries tentativas.');
      }

      // Não é necessário registrar a requisição aqui, pois já foi registrada antes da chamada à API

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts') &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty &&
            jsonResponse['candidates'][0]['content']['parts'][0].containsKey('text')) {

          final text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          print('[GeminiService] Resposta processada com sucesso: ${text.substring(0, text.length > 100 ? 100 : text.length)}...');
          return text;
        } else {
          print('[GeminiService] Estrutura de resposta inesperada: ${jsonResponse.toString().substring(0, 200)}...');
          throw Exception('Estrutura de resposta inesperada do Gemini.');
        }
      } else if (response.statusCode == 500) {
        print('[GeminiService] Erro 500 (Internal Server Error) na API Gemini');

        // Tentar extrair mensagem de erro mais específica
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'Erro interno do servidor';

          // Verificar mensagens específicas
          if (errorMessage.contains('quota') || errorMessage.contains('rate limit')) {
            throw Exception('Você atingiu o limite de cotas gratuitas do Gemini. Tente novamente mais tarde ou gere uma nova chave API.');
          } else if (errorMessage.contains('file too large') || errorMessage.contains('payload too large')) {
            throw Exception('O arquivo PDF é muito grande. Tente usar um arquivo menor.');
          } else {
            throw Exception('Ocorreu um erro nos servidores Google ou você excedeu o limite de cotas gratuitas do Gemini. Tente novamente mais tarde ou gere uma nova chave API.');
          }
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Ocorreu um erro nos servidores Google ou você excedeu o limite de cotas gratuitas do Gemini. Tente novamente mais tarde ou gere uma nova chave API.');
        }
      } else {
        print('[GeminiService] Erro na chamada à API: ${response.statusCode}');
        print('[GeminiService] Detalhes do erro: ${response.body}');

        // Tentar extrair mensagem de erro mais específica
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'Erro desconhecido';
          throw Exception('Erro na chamada à API Gemini: $errorMessage');
        } catch (e) {
          if (e is Exception) rethrow;
          throw Exception('Erro na chamada à API Gemini: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('[GeminiService] Exceção ao processar PDF: $e');
      rethrow;
    }
  }
}
