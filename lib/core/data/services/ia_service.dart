import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/flashcard.dart';
import '../../utils/text_utils.dart';
import '../../services/prompt_service.dart';

class IAService extends ChangeNotifier {
  // URLs base para as APIs
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final String _openaiBaseUrl = 'https://api.openai.com/v1';
  final String _openrouterBaseUrl = 'https://openrouter.ai/api/v1'; // URL base para OpenRouter
  final String _requestryBaseUrl = 'https://router.requesty.ai/v1'; // URL base para Requestry

  // Modelos
  final String _geminiModel = 'gemini-2.5-pro-exp-03-25';
  final String _openaiModel = 'gpt-3.5-turbo';
  final String _openrouterModel = 'anthropic/claude-3.7-sonnet'; // Modelo padrão para OpenRouter
  final String _requestryModel = 'openai/gpt-4o'; // Modelo padrão para Requestry

  // Chaves de API
  String? _apiKey; // Chave da API atual
  String? _geminiApiKey; // Chave específica para Gemini
  String? _openaiApiKey; // Chave específica para OpenAI
  String? _openrouterApiKey; // Chave específica para OpenRouter
  String? _requestryApiKey; // Chave específica para Requestry
  String _apiType = 'gemini'; // 'gemini', 'openrouter' ou 'requestry'

  // Serviço de prompts
  final PromptService _promptService = PromptService();

  // Método para configurar o tipo de API
  void setApiType(String apiType) {
    _apiType = apiType;
    notifyListeners();
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  String get apiType => _apiType;
  String? get apiKey => _apiKey;

  // Método para configurar a chave de API
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) async {
    try {
      // Verificar se a API key é válida
      bool isValid = false;
      String errorMessage = '';

      if (apiType == 'gemini') {
        // Teste simples para verificar se a API key do Gemini funciona
        final url = '$_geminiBaseUrl/gemini-2.5-pro-exp-03-25:generateContent?key=$apiKey';
        final testBody = jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'Olá, teste de conexão.'
                }
              ]
            }
          ],
          'generationConfig': {
            'maxOutputTokens': 10,
          }
        });

        print('Testando API Gemini com modelo: gemini-2.5-pro-exp-03-25');
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: testBody,
        );

        isValid = response.statusCode == 200;
        if (!isValid) {
          errorMessage = 'API Key Gemini inválida: ${response.statusCode} ${response.body}';
          print(errorMessage);
        } else {
          print('API Gemini validada com sucesso');
        }
      } else if (apiType == 'openrouter') {
        // Teste simples para verificar se a API key do OpenRouter funciona
        // Verificar o formato e fazer uma chamada de teste
        if (!apiKey.startsWith('sk-')) {
          isValid = false;
          errorMessage = 'API Key OpenRouter inválida: Deve começar com "sk-"';
          print(errorMessage);
        } else {
          try {
            // Fazer uma chamada de teste para listar modelos disponíveis
            final url = '$_openrouterBaseUrl/models';
            final response = await http.get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $apiKey',
              },
            );

            isValid = response.statusCode == 200;
            if (!isValid) {
              errorMessage = 'API Key OpenRouter inválida: ${response.statusCode} ${response.body}';
              print(errorMessage);
            } else {
              print('API OpenRouter validada com sucesso');
            }
          } catch (e) {
            isValid = false;
            errorMessage = 'Erro ao validar API Key OpenRouter: $e';
            print(errorMessage);
          }
        }
      } else if (apiType == 'requestry') {
        // Teste simples para verificar se a API key do Requestry funciona
        // Verificar o formato e fazer uma chamada de teste
        if (!apiKey.startsWith('sk-')) {
          isValid = false;
          errorMessage = 'API Key Requestry inválida: Deve começar com "sk-"';
          print(errorMessage);
        } else {
          try {
            // Fazer uma chamada de teste para listar modelos disponíveis
            final url = '$_requestryBaseUrl/models';
            final response = await http.get(
              Uri.parse(url),
              headers: {
                'Authorization': 'Bearer $apiKey',
              },
            );

            isValid = response.statusCode == 200;
            if (!isValid) {
              errorMessage = 'API Key Requestry inválida: ${response.statusCode} ${response.body}';
              print(errorMessage);
            } else {
              print('API Requestry validada com sucesso');
            }
          } catch (e) {
            // Se ocorrer um erro de conexão, vamos considerar válido apenas pelo formato
            // Isso permite que o usuário teste a API mesmo sem conexão
            isValid = true;
            print('Aviso: Não foi possível conectar ao servidor Requestry. Validando apenas o formato da chave.');
          }
        }
      }

      if (isValid) {
        _apiKey = apiKey;
        _apiType = apiType;

        // Definir a chave específica com base no tipo
        if (apiType == 'gemini') {
          _geminiApiKey = apiKey;
        } else if (apiType == 'openrouter') {
          // Armazenar a chave do OpenRouter
          _openrouterApiKey = apiKey;
        } else if (apiType == 'requestry') {
          // Armazenar a chave do Requestry
          _requestryApiKey = apiKey;
        } else if (apiType == 'openai') {
          // Armazenar a chave da OpenAI
          _openaiApiKey = apiKey;
        }

        notifyListeners();
        return {
          'success': true,
          'message': 'API Key validada com sucesso!'
        };
      } else {
        return {
          'success': false,
          'message': errorMessage.isEmpty ? 'Falha na validação da API Key' : errorMessage
        };
      }
    } catch (e) {
      print('Erro ao configurar API key: $e');
      throw e; // Propagar o erro para ser tratado na tela
    }
  }

  // Detectar automaticamente o tipo de API key
  String _detectarTipoApiKey(String apiKey) {
    // API keys do Gemini geralmente começam com "AI" seguido por caracteres alfanuméricos
    if (apiKey.startsWith('AI')) {
      return 'gemini';
    }
    // API keys do OpenRouter e Requestry também começam com "sk-" como as da OpenAI
    // Neste caso, precisamos confiar no tipo selecionado pelo usuário
    else if (apiKey.startsWith('sk-')) {
      // Se o tipo atual já for openrouter ou requestry, manter
      if (_apiType == 'openrouter' || _apiType == 'requestry') {
        return _apiType;
      }
      // Caso contrário, assumir OpenAI (legado)
      return 'openai';
    }
    // Se não conseguir detectar, manter o tipo atual
    return _apiType;
  }

  /// Verifica se o texto está dentro do limite de tokens para o modelo atual
  bool isWithinTokenLimit(String texto) {
    // Estimar o tamanho do texto em tokens (aproximadamente 4 caracteres por token)
    final int tokenEstimado = texto.length ~/ 4;

    // Definir limite de tokens baseado no modelo e tipo de API
    int limiteTokens;

    if (_apiType == 'gemini') {
      // Limites para modelos Gemini
      switch (_geminiModel) {
        case 'gemini-2.5-pro-exp-03-25':
        case 'gemini-2.5-pro-preview-03-25':
          limiteTokens = 1000000;
          break;
        case 'gemini-2.0-flash':
        case 'gemini-2.0-flash-lite':
          limiteTokens = 1000000;
          break;
        case 'gemini-1.5-pro':
          limiteTokens = 2000000;
          break;
        case 'gemini-1.5-flash':
          limiteTokens = 1000000;
          break;
        default:
          limiteTokens = 30000; // Valor conservador para modelos desconhecidos
      }
    } else {
      // Limites para modelos OpenAI
      switch (_openaiModel) {
        case 'gpt-4':
        case 'gpt-4-turbo':
          limiteTokens = 128000;
          break;
        case 'gpt-3.5-turbo-16k':
          limiteTokens = 16000;
          break;
        case 'gpt-3.5-turbo':
          limiteTokens = 4000;
          break;
        default:
          limiteTokens = 4000; // Valor conservador para modelos desconhecidos
      }
    }

    // Verificar se o texto está dentro do limite (com margem de segurança de 20%)
    return tokenEstimado < (limiteTokens * 0.8);
  }

  // Este método foi substituído pelo setApiKey e não é mais usado
  @deprecated
  Future<bool> configurarApiKey(String apiKey) async {
    try {
      final result = await setApiKey(apiKey, _detectarTipoApiKey(apiKey));
      return result['success'] as bool;
    } catch (e) {
      print('Erro ao configurar API key: $e');
      return false;
    }
  }

  // Método público para chamar a API (para uso em outros serviços)
  Future<String> callApiWithPrompt(String prompt) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }
    return await callApi(prompt);
  }

  // Método para analisar JSON da resposta
  dynamic parseJsonResponse(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      print('Erro ao fazer parse do JSON: $e');
      throw Exception('Resposta não é um JSON válido: $e');
    }
  }

  // Gerar resposta em formato JSON
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      final String resposta = await callApi(prompt);

      // Extrair o JSON da resposta
      String jsonStr = resposta.trim();

      // Encontrar o início do JSON (primeiro '{')
      final int startIndex = jsonStr.indexOf('{');
      if (startIndex >= 0) {
        jsonStr = jsonStr.substring(startIndex);
      }

      // Encontrar o fim do JSON (último '}')
      final int endIndex = jsonStr.lastIndexOf('}');
      if (endIndex >= 0 && endIndex < jsonStr.length - 1) {
        jsonStr = jsonStr.substring(0, endIndex + 1);
      }

      // Decodificar o JSON
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Erro ao gerar resposta JSON: $e');
      return null;
    }
  }

  // Gerar flashcards a partir de um texto
  Future<List<Flashcard>> gerarFlashcards(
    String userId,
    String? editalId,
    String materia,
    String texto,
  ) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Verificar se o texto é muito longo e dividi-lo se necessário
      final List<String> textChunks = TextUtils.splitLongText(texto, maxTokensPerChunk: 10000);
      final List<Flashcard> allFlashcards = [];

      // Se o texto for curto o suficiente, processe-o normalmente
      if (textChunks.length == 1) {
        // Carregar o prompt base para geração de flashcards
        String promptTemplate = await _promptService.loadFlashcardGenerationPrompt();

        // Personalizar o prompt com o texto específico
        final Map<String, String> variables = {
          'texto': texto,
          'materia': materia
        };

        final prompt = _promptService.customizePrompt(promptTemplate, variables);

        final response = await _callApi(prompt);
        return _parseFlashcardsFromText(response, userId, editalId, materia);
      }
      // Se o texto for longo, processe cada parte separadamente e combine os resultados
      else {
        print('Texto muito longo, dividindo em ${textChunks.length} partes para gerar flashcards');

        // Carregar o prompt base para geração de flashcards
        String promptTemplate = await _promptService.loadFlashcardGenerationPrompt();

        for (int i = 0; i < textChunks.length; i++) {
          final chunk = textChunks[i];

          // Personalizar o prompt com o texto específico e informações sobre a parte
          final Map<String, String> variables = {
            'texto': chunk,
            'materia': materia,
            'parte_atual': '${i+1}',
            'total_partes': '${textChunks.length}'
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables) +
          '''

OBSERVAÇÃO IMPORTANTE: Você está analisando a parte ${i+1} de ${textChunks.length} de um documento maior.
          Crie apenas flashcards para os conceitos mais importantes desta parte.
          ''';

          final response = await _callApi(prompt);
          final chunkFlashcards = _parseFlashcardsFromText(response, userId, editalId, materia);
          allFlashcards.addAll(chunkFlashcards);
        }

        return allFlashcards;
      }
    } catch (e) {
      throw Exception('Erro ao gerar flashcards: $e');
    }
  }

  // Método auxiliar para analisar flashcards a partir do texto de resposta
  List<Flashcard> _parseFlashcardsFromText(String text, String userId, String? editalId, String materia) {
    final flashcardsText = text.split('\n');
    final List<Flashcard> flashcards = [];

    for (final line in flashcardsText) {
      if (line.contains('Pergunta:') && line.contains('//') && line.contains('Resposta:')) {
        final parts = line.split('//');
        if (parts.length == 2) {
          final pergunta = parts[0].replaceAll('Pergunta:', '').trim();
          final resposta = parts[1].replaceAll('Resposta:', '').trim();

          flashcards.add(Flashcard(
            id: DateTime.now().millisecondsSinceEpoch.toString() + flashcards.length.toString(),
            userId: userId,
            editalId: editalId,
            materia: materia,
            pergunta: pergunta,
            resposta: resposta,
            fonte: 'ia',
          ));
        }
      }
    }

    return flashcards;
  }

  // Gerar resumo a partir de um texto
  Future<String> gerarResumo(String texto) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Verificar se o texto é muito longo e dividi-lo se necessário
      final List<String> textChunks = TextUtils.splitLongText(texto, maxTokensPerChunk: 10000);

      // Se o texto for curto o suficiente, processe-o normalmente
      if (textChunks.length == 1) {
        // Carregar o prompt base para geração de resumos
        String promptTemplate = await _promptService.loadSummaryGenerationPrompt();

        // Personalizar o prompt com o texto específico
        final Map<String, String> variables = {
          'texto': texto
        };

        final prompt = _promptService.customizePrompt(promptTemplate, variables);

        return await _callApi(prompt);
      }
      // Se o texto for longo, processe cada parte separadamente e combine os resultados
      else {
        print('Texto muito longo, dividindo em ${textChunks.length} partes');
        List<String> resumos = [];

        // Carregar o prompt base para geração de resumos
        String promptTemplate = await _promptService.loadSummaryGenerationPrompt();

        for (int i = 0; i < textChunks.length; i++) {
          final chunk = textChunks[i];

          // Personalizar o prompt com o texto específico e informações sobre a parte
          final Map<String, String> variables = {
            'texto': chunk
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables) +
          '''

OBSERVAÇÃO IMPORTANTE: Você está analisando a parte ${i+1} de ${textChunks.length} de um documento maior.
          Seja objetivo e direto, focando apenas nas informações mais importantes desta parte.
          ''';

          final resumoParcial = await _callApi(prompt);
          resumos.add(resumoParcial);
        }

        // Se houver muitas partes, podemos precisar resumir os resumos
        if (resumos.length > 3) {
          final resumoCombinado = resumos.join('\n\n--- PRÓXIMA PARTE ---\n\n');
          final promptFinal = '''
          Abaixo estão resumos de diferentes partes de um documento maior.
          Combine esses resumos em um único resumo coeso e bem estruturado,
          mantendo as informações mais importantes e eliminando redundâncias.
          Organize o resumo final em tópicos com marcadores para facilitar a leitura.

          Resumos parciais:
          $resumoCombinado
          ''';

          return await _callApi(promptFinal);
        } else {
          // Se houver poucas partes, podemos simplesmente combinar os resumos
          return resumos.join('\n\n--- PRÓXIMA PARTE ---\n\n');
        }
      }
    } catch (e) {
      throw Exception('Erro ao gerar resumo: $e');
    }
  }

  // Gerar esquema/mapa mental a partir de um texto
  Future<String> gerarEsquema(String texto, {String? titulo}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    // Usar título fornecido ou gerar um título padrão
    final tituloMapa = titulo ?? 'Mapa Mental';

    try {
      // Verificar se o texto é muito longo e dividi-lo se necessário
      final List<String> textChunks = TextUtils.splitLongText(texto, maxTokensPerChunk: 10000);

      // Se o texto for curto o suficiente, processe-o normalmente
      if (textChunks.length == 1) {
        // Carregar o prompt base para geração de mapas mentais
        String promptTemplate = await _promptService.loadMindmapGenerationPrompt();

        // Personalizar o prompt com o texto específico e título
        final Map<String, String> variables = {
          'texto': texto,
          'titulo': tituloMapa
        };

        final prompt = _promptService.customizePrompt(promptTemplate, variables);

        return await _callApi(prompt);
      }
      // Se o texto for longo, processe cada parte separadamente e combine os resultados
      else {
        print('Texto muito longo, dividindo em ${textChunks.length} partes para gerar esquema');
        List<String> esquemas = [];

        // Carregar o prompt base para geração de mapas mentais
        String promptTemplate = await _promptService.loadMindmapGenerationPrompt();

        for (int i = 0; i < textChunks.length; i++) {
          final chunk = textChunks[i];

          // Personalizar o prompt com o texto específico, título e informações sobre a parte
          final Map<String, String> variables = {
            'texto': chunk,
            'titulo': '$tituloMapa (Parte ${i+1})'
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables) +
          '''

OBSERVAÇÃO IMPORTANTE: Você está analisando a parte ${i+1} de ${textChunks.length} de um documento maior.
          Estruture apenas os conceitos chave desta parte em formato de tópicos e subtópicos.
          ''';

          final esquemaParcial = await _callApi(prompt);
          esquemas.add(esquemaParcial);
        }

        // Se houver muitas partes, podemos precisar consolidar os esquemas
        if (esquemas.length > 3) {
          final esquemaCombinado = esquemas.join('\n\n--- PRÓXIMA PARTE ---\n\n');
          final promptFinal = '''
          Abaixo estão esquemas de diferentes partes de um documento maior.
          Combine esses esquemas em um único esquema coeso e bem estruturado,
          mantendo os conceitos mais importantes e eliminando redundâncias.
          Organize o esquema final em tópicos e subtópicos claros.

          IMPORTANTE: Mantenha o formato markmap.js exatamente como mostrado nos exemplos,
          incluindo o cabeçalho YAML com title e markmap.

          Esquemas parciais:
          $esquemaCombinado

          Título do mapa mental: $tituloMapa
          ''';

          return await _callApi(promptFinal);
        } else {
          // Se houver poucas partes, podemos simplesmente combinar os esquemas
          return esquemas.join('\n\n--- PRÓXIMA PARTE ---\n\n');
        }
      }
    } catch (e) {
      throw Exception('Erro ao gerar esquema: $e');
    }
  }

  // Gerar questões a partir de um texto
  Future<String> gerarQuestoes(String texto, String materia, String dificuldade, int quantidade) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Verificar se o texto é muito longo e dividi-lo se necessário
      final List<String> textChunks = TextUtils.splitLongText(texto, maxTokensPerChunk: 10000);

      // Se o texto for curto o suficiente, processe-o normalmente
      if (textChunks.length == 1) {
        // Carregar o prompt base para geração de questões
        String promptTemplate = await _promptService.loadQuestionGenerationPrompt();

        // Personalizar o prompt com o texto específico
        final Map<String, String> variables = {
          'texto': texto,
          'materia': materia,
          'dificuldade': dificuldade,
          'quantidade': quantidade.toString()
        };

        final prompt = _promptService.customizePrompt(promptTemplate, variables);

        return await _callApi(prompt);
      }
      // Se o texto for longo, processe cada parte separadamente e combine os resultados
      else {
        print('Texto muito longo, dividindo em ${textChunks.length} partes para gerar questões');
        List<String> todasQuestoes = [];
        int questoesPorParte = (quantidade / textChunks.length).ceil();

        // Carregar o prompt base para geração de questões
        String promptTemplate = await _promptService.loadQuestionGenerationPrompt();

        for (int i = 0; i < textChunks.length; i++) {
          final chunk = textChunks[i];

          // Personalizar o prompt com o texto específico e informações sobre a parte
          final Map<String, String> variables = {
            'texto': chunk,
            'materia': materia,
            'dificuldade': dificuldade,
            'quantidade': questoesPorParte.toString()
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables) +
          '''

OBSERVAÇÃO IMPORTANTE: Você está analisando a parte ${i+1} de ${textChunks.length} de um documento maior.
          Crie apenas ${questoesPorParte} questões para esta parte específica do texto.
          ''';

          final questoesParciais = await _callApi(prompt);
          todasQuestoes.add(questoesParciais);
        }

        // Combinar todas as questões geradas
        return todasQuestoes.join('\n\n--- PRÓXIMA PARTE ---\n\n');
      }
    } catch (e) {
      throw Exception('Erro ao gerar questões: $e');
    }
  }

  // Método para chamar a API (Gemini ou OpenAI)
  Future<String> _callApi(String prompt) async {
    return await callApi(prompt);
  }

  // Método público para chamar a API
  Future<String> callApi(String prompt) async {
    try {
      if (_apiType == 'gemini') {
        try {
          return await _callGeminiApi(prompt);
        } catch (e) {
          print('Erro específico da API Gemini: $e');
          // Verificar se é um erro de modelo não encontrado
          if (e.toString().contains('models/gemini-2.0-flash is not found') ||
              e.toString().contains('not found')) {
            throw Exception('O modelo Gemini 2.0 Flash não está disponível. Verifique se sua API key tem acesso a este modelo.');
          }
          rethrow;
        }
      } else if (_apiType == 'openrouter') {
        try {
          return await _callOpenRouterApi(prompt);
        } catch (e) {
          print('Erro específico da API OpenRouter: $e');
          rethrow;
        }
      } else if (_apiType == 'requestry') {
        try {
          return await _callRequestryApi(prompt);
        } catch (e) {
          print('Erro específico da API Requestry: $e');
          rethrow;
        }
      } else if (_apiType == 'openai') {
        // OpenAI (legado)
        return await _callOpenAIApi(prompt);
      } else {
        throw Exception('Tipo de API não suportado: $_apiType');
      }
    } catch (e) {
      print('Erro ao chamar API: $e');
      rethrow;
    }
  }

  // Método para chamar a API do Gemini com retry
  Future<String> _callGeminiApi(String prompt) async {
    final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$_apiKey';

    // Parâmetros de retry
    final int maxRetries = 3;
    final int initialDelayMs = 1000; // 1 segundo
    int currentRetry = 0;
    int delayMs = initialDelayMs;

    // Detectar o tipo de tarefa com base no conteúdo do prompt
    // Detectar se é uma extração de edital
    bool isEditalExtraction = prompt.contains('edital') &&
                            (prompt.contains('extrair') || prompt.contains('extração') ||
                             prompt.contains('analise') || prompt.contains('análise'));

    // Detectar se é uma extração de edital em formato YAML
    bool isYamlExtraction = isEditalExtraction &&
                          (prompt.contains('YAML') || prompt.contains('yaml'));

    // Detectar se é uma extração de edital em formato JSON
    bool isJsonExtraction = isEditalExtraction &&
                          (prompt.contains('JSON') || prompt.contains('json')) &&
                          !isYamlExtraction; // Priorizar YAML se ambos estiverem presentes

    // Adicionar logs para depuração
    debugPrint('isYamlExtraction: $isYamlExtraction');
    debugPrint('isJsonExtraction: $isJsonExtraction');

    debugPrint('Prompt contém "edital": ${prompt.contains('edital')}');
    debugPrint('Prompt contém "JSON" ou "json": ${prompt.contains('JSON') || prompt.contains('json')}');
    debugPrint('Prompt contém termos de análise: ${prompt.contains('extrair') || prompt.contains('extração') || prompt.contains('analise') || prompt.contains('análise')}');
    debugPrint('isEditalExtraction: $isEditalExtraction');

    // Detectar se é um plano de estudo - verificar de forma mais específica
    bool isPlanoEstudo = (prompt.contains('plano de estudo') || prompt.contains('plano de estudos')) &&
                         (prompt.contains('cronograma semanal') || prompt.contains('distribuição de horas')) &&
                         (prompt.contains('matérias prioritárias') || prompt.contains('metas'));

    debugPrint('Prompt contém "plano de estudo" ou "plano de estudos": ${prompt.contains('plano de estudo') || prompt.contains('plano de estudos')}');
    debugPrint('Prompt contém "cronograma semanal" ou "distribuição de horas": ${prompt.contains('cronograma semanal') || prompt.contains('distribuição de horas')}');
    debugPrint('Prompt contém "matérias prioritárias" ou "metas": ${prompt.contains('matérias prioritárias') || prompt.contains('metas')}');
    debugPrint('isPlanoEstudo: $isPlanoEstudo');

    // Otimizar parâmetros com base no tipo de tarefa
    double temperature;
    String maxOutputTokens; // Alterado para String para evitar erro de tipo
    String? responseMimeType;
    Map<String, dynamic>? responseSchema;

    if (isEditalExtraction) {
      // Para extração de dados de edital, usar temperatura baixa para respostas mais precisas
      temperature = 0.1;
      maxOutputTokens = '64000'; // Aumentado para o limite máximo do Gemini 2.5 Pro

      // Definir o formato da resposta com base no tipo de extração
      // Sempre usar YAML para extração de edital
      responseMimeType = null; // Não definir responseMimeType para permitir resposta em YAML
      print('Configurando chamada para extração de edital com Gemini 2.5 Pro (formato YAML)');

      // Definir schema para extração de edital
      responseSchema = {
        'type': 'object',
        'properties': {
          'titulo': {'type': 'string', 'description': 'Título do edital ou concurso'},
          'orgao': {'type': 'string', 'description': 'Órgão responsável pelo concurso'},
          'banca': {'type': 'string', 'description': 'Banca organizadora do concurso'},
          'inicioInscricao': {'type': 'string', 'description': 'Data de início das inscrições (formato YYYY-MM-DD)'},
          'fimInscricao': {'type': 'string', 'description': 'Data de término das inscrições (formato YYYY-MM-DD)'},
          'valorTaxa': {'type': 'number', 'description': 'Valor da taxa de inscrição'},
          'localProva': {'type': 'string', 'description': 'Local de realização da prova'},
          'cargos': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'nome': {'type': 'string', 'description': 'Nome do cargo'},
                'vagas': {'type': 'integer', 'description': 'Número de vagas'},
                'salario': {'type': 'number', 'description': 'Salário do cargo'},
                'escolaridade': {'type': 'string', 'description': 'Escolaridade exigida'},
                'conteudoProgramatico': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'description': 'Lista de disciplinas e conteúdos programáticos'
                }
              },
              'required': ['nome']
            }
          }
        },
        'required': ['titulo', 'cargos']
      };

      // Removido log duplicado
    } else if (isPlanoEstudo) {
      // Para geração de plano de estudo, usar temperatura moderada para criatividade controlada
      temperature = 0.3;
      maxOutputTokens = '8192'; // Alterado para string para compatibilidade com a API
      responseMimeType = 'application/json'; // Solicitar resposta em formato JSON

      // Definir schema para plano de estudo
      responseSchema = {
        'type': 'object',
        'properties': {
          'materiasPrioritarias': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'nome': {'type': 'string', 'description': 'Nome da matéria'},
                'peso': {'type': 'integer', 'description': 'Peso/prioridade da matéria (1-5)'},
                'estrategia': {'type': 'string', 'description': 'Estratégia de estudo recomendada'}
              }
            }
          },
          'cronogramaSemanal': {
            'type': 'object',
            'properties': {
              'segunda': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}},
              'terca': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}},
              'quarta': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}},
              'quinta': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}},
              'sexta': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}},
              'sabado': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}},
              'domingo': {'type': 'array', 'items': {'type': 'object', 'properties': {'materia': {'type': 'string'}, 'horas': {'type': 'number'}}}}
            }
          },
          'recursosRecomendados': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'tipo': {'type': 'string', 'description': 'Tipo de recurso (livro, vídeo, etc.)'},
                'descricao': {'type': 'string', 'description': 'Descrição do recurso'}
              }
            }
          },
          'dicasGerais': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Dicas gerais para o estudo'
          }
        },
        'required': ['materiasPrioritarias', 'cronogramaSemanal']
      };

      print('Configurando chamada para geração de plano de estudo com Gemini 2.5 Pro (formato JSON)');
    } else {
      // Para outras tarefas, usar configurações padrão
      temperature = 0.2;
      maxOutputTokens = '4096'; // Alterado para string para compatibilidade com a API
      print('Configurando chamada padrão para Gemini 2.5 Pro');
    }

    print('Parâmetros: temperature=$temperature, maxOutputTokens=$maxOutputTokens, responseMimeType=$responseMimeType');

    // Construir o corpo da requisição
    Map<String, dynamic> requestBody = {
      'contents': [
        {
          'parts': [
            {
              'text': prompt
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': temperature,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': maxOutputTokens,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        }
      ]
    };

    // Adicionar responseMimeType se especificado
    if (responseMimeType != null) {
      requestBody['generationConfig']['responseMimeType'] = responseMimeType;
    }

    // Adicionar responseSchema se especificado
    // Não adicionar diretamente para evitar erro de tipo
    // O Gemini API não suporta o parâmetro responseSchema na versão atual
    // Vamos usar apenas responseMimeType para solicitar JSON

    final body = jsonEncode(requestBody);

    // Loop de retry
    while (true) {
      try {
        print('Enviando requisição para a API Gemini (tentativa ${currentRetry + 1} de $maxRetries)...');
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 200) {
        print('Resposta recebida com sucesso da Gemini. Analisando JSON...');
        final jsonResponse = jsonDecode(response.body);
        print('Estrutura da resposta Gemini: ${jsonResponse.keys.toList()}');

        // Extrair o texto da resposta
        String text = '';
        if (jsonResponse.containsKey('candidates') &&
            jsonResponse['candidates'].isNotEmpty &&
            jsonResponse['candidates'][0].containsKey('content') &&
            jsonResponse['candidates'][0]['content'].containsKey('parts') &&
            jsonResponse['candidates'][0]['content']['parts'].isNotEmpty) {

          text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          print('Texto extraído com sucesso da Gemini: ${text.substring(0, min<int>(100, text.length))}...');
        } else {
          print('Estrutura de resposta inesperada: $jsonResponse');
          // Tentar extrair o texto de forma alternativa
          if (jsonResponse.containsKey('text')) {
            text = jsonResponse['text'];
          } else if (jsonResponse.containsKey('content') && jsonResponse['content'].containsKey('text')) {
            text = jsonResponse['content']['text'];
          } else {
            throw Exception('Não foi possível extrair o texto da resposta: $jsonResponse');
          }
        }

        // Se estiver usando responseMimeType ou responseSchema, verificar se o texto é um JSON válido
        if (responseMimeType == 'application/json' || responseSchema != null || isEditalExtraction) {
          try {
            // Tentar extrair JSON da resposta
            String jsonText = text;

            // Verificar se o texto contém delimitadores de código
            final RegExp jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
            final match = jsonRegex.firstMatch(jsonText);

            if (match != null && match.groupCount >= 1) {
              jsonText = match.group(1)!.trim();
              print('Encontrado JSON entre delimitadores de código');
            }

            // Verificar se o texto já é um JSON válido
            try {
              json.decode(jsonText); // Apenas para verificar se já é válido
              print('Resposta contém JSON válido');
              return jsonText;
            } catch (jsonError) {
              print('JSON não válido após extrair delimitadores. Tentando extrair JSON...');

              // Remover texto antes do primeiro { ou [
              final int jsonStart = jsonText.indexOf('{') != -1 ? jsonText.indexOf('{') : jsonText.indexOf('[');
              if (jsonStart > 0) {
                jsonText = jsonText.substring(jsonStart);
                print('Removido texto antes do JSON');
              }

              // Remover texto após o último } ou ]
              final int jsonEnd = jsonText.lastIndexOf('}') != -1 ? jsonText.lastIndexOf('}') + 1 : jsonText.lastIndexOf(']') + 1;
              if (jsonEnd > 0 && jsonEnd < jsonText.length) {
                print('Removido texto após o JSON');
                jsonText = jsonText.substring(0, jsonEnd);
              }

              // Verificar se o texto limpo é um JSON válido
              try {
                json.decode(jsonText); // Verificar se é válido após limpeza
                print('JSON extraído com sucesso após limpeza');
                return jsonText; // Se não lançar exceção, usar o JSON limpo
              } catch (cleanJsonError) {
                print('Falha ao extrair JSON mesmo após limpeza: $cleanJsonError');
                // Retornar o texto original
              }
            }
          } catch (e) {
            print('Erro ao processar resposta JSON: $e');
            // Retornar o texto original mesmo que não seja JSON válido
            // O processador de JSON irá tentar corrigir depois
          }
        }

        return text;
      } else {
          print('Erro na API Gemini: ${response.statusCode} ${response.body}');

          // Verificar se é um erro de sobrecarga (503) e se ainda podemos tentar novamente
          if (response.statusCode == 503 && currentRetry < maxRetries - 1) {
            currentRetry++;
            // Aumentar o tempo de espera exponencialmente (backoff exponencial)
            delayMs *= 2;
            print('Modelo sobrecarregado. Tentando novamente em ${delayMs}ms...');
            await Future.delayed(Duration(milliseconds: delayMs));
            continue; // Tentar novamente
          }

          // Se não for um erro de sobrecarga ou já tentamos o máximo de vezes, lançar exceção
          throw Exception('Falha na chamada da API Gemini: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        print('Exceção ao chamar API Gemini: $e');

        // Verificar se ainda podemos tentar novamente
        if (currentRetry < maxRetries - 1) {
          currentRetry++;
          // Aumentar o tempo de espera exponencialmente (backoff exponencial)
          delayMs *= 2;
          print('Erro ao conectar. Tentando novamente em ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue; // Tentar novamente
        }

        // Se já tentamos o máximo de vezes, lançar exceção
        throw Exception('Erro ao conectar com a API Gemini: $e');
      }

      // Se chegamos aqui, significa que a requisição foi bem-sucedida
      break;
    } // Fim do loop while
  }

  // Método para chamar a API do OpenRouter (compatível com OpenAI)
  Future<String> _callOpenRouterApi(String prompt) async {
    final url = '$_openrouterBaseUrl/chat/completions';

    // Verificar se o prompt é para extração de dados de edital
    bool isEditalExtraction = prompt.contains('edital') &&
                            (prompt.contains('extrair') || prompt.contains('extração') ||
                             prompt.contains('analise') || prompt.contains('análise'));

    // Detectar se é uma extração de edital em formato YAML
    bool isYamlExtraction = isEditalExtraction &&
                          (prompt.contains('YAML') || prompt.contains('yaml'));

    // Configurar parâmetros específicos para extração de dados de edital
    double temperature = isEditalExtraction ? 0.0 : 0.1;
    int maxTokens = isEditalExtraction ? 8192 : 4096;

    print('Configurando chamada para OpenRouter: isEditalExtraction=$isEditalExtraction, temperature=$temperature, maxTokens=$maxTokens');

    // Configurar o formato da resposta - sempre usar formato de texto para permitir resposta em YAML
    Map<String, dynamic> responseFormat = { 'type': 'text' };
    print('Configurando chamada para extração de edital com OpenRouter (formato YAML)');

    final body = jsonEncode({
      'model': _openrouterModel,
      'messages': [
        {
          'role': 'system',
          'content': isEditalExtraction
              ? 'Você é um especialista em análise de editais de concursos públicos brasileiros. Sua tarefa é extrair informações estruturadas e retornar APENAS um documento YAML válido, sem texto adicional. NÃO retorne a resposta em formato JSON.'
              : 'Você é um assistente especializado em preparação para concursos públicos brasileiros.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': responseFormat
    });

    try {
      print('Enviando requisição para a API OpenRouter...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openrouterApiKey',
          'HTTP-Referer': 'https://preparatorio-concursos.app', // Opcional, para rankings no openrouter.ai
          'X-Title': 'Preparatorio Concursos', // Opcional, para rankings no openrouter.ai
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Resposta recebida com sucesso da OpenRouter. Analisando JSON...');
        final jsonResponse = jsonDecode(response.body);
        print('Estrutura da resposta OpenRouter: ${jsonResponse.keys.toList()}');

        // Extrair o texto da resposta - método principal
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          return jsonResponse['choices'][0]['message']['content'];
        }
        // Fallback para outros formatos de resposta
        else if (jsonResponse.containsKey('text')) {
          return jsonResponse['text'];
        } else {
          throw Exception('Formato de resposta não reconhecido: $jsonResponse');
        }
      } else {
        print('Erro na API OpenRouter: ${response.statusCode} ${response.body}');
        throw Exception('Falha na chamada da API OpenRouter: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exceção ao chamar API OpenRouter: $e');
      throw Exception('Erro ao conectar com a API OpenRouter: $e');
    }
  }

  // Método para chamar a API do Requestry (compatível com OpenAI)
  Future<String> _callRequestryApi(String prompt) async {
    final url = '$_requestryBaseUrl/chat/completions';

    // Verificar se o prompt é para extração de dados de edital
    bool isEditalExtraction = prompt.contains('edital') &&
                            (prompt.contains('extrair') || prompt.contains('extração') ||
                             prompt.contains('analise') || prompt.contains('análise'));

    // Detectar se é uma extração de edital em formato YAML
    bool isYamlExtraction = isEditalExtraction &&
                          (prompt.contains('YAML') || prompt.contains('yaml'));

    // Configurar parâmetros específicos para extração de dados de edital
    double temperature = isEditalExtraction ? 0.0 : 0.1;
    int maxTokens = isEditalExtraction ? 8192 : 4096;

    print('Configurando chamada para Requestry: isEditalExtraction=$isEditalExtraction, temperature=$temperature, maxTokens=$maxTokens');

    // Configurar o formato da resposta - sempre usar formato de texto para permitir resposta em YAML
    Map<String, dynamic> responseFormat = { 'type': 'text' };
    print('Configurando chamada para extração de edital com Requestry (formato YAML)');

    final body = jsonEncode({
      'model': _requestryModel,
      'messages': [
        {
          'role': 'system',
          'content': isEditalExtraction
              ? 'Você é um especialista em análise de editais de concursos públicos brasileiros. Sua tarefa é extrair informações estruturadas e retornar APENAS um documento YAML válido, sem texto adicional. NÃO retorne a resposta em formato JSON.'
              : 'Você é um assistente especializado em preparação para concursos públicos brasileiros.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': responseFormat
    });

    try {
      print('Enviando requisição para a API Requestry...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_requestryApiKey',
          'HTTP-Referer': 'https://preparatorio-concursos.app', // Opcional, para análise
          'X-Title': 'Preparatorio Concursos', // Opcional, para análise
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Resposta recebida com sucesso da Requestry. Analisando JSON...');
        final jsonResponse = jsonDecode(response.body);
        print('Estrutura da resposta Requestry: ${jsonResponse.keys.toList()}');

        // Extrair o texto da resposta - método principal
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {
          return jsonResponse['choices'][0]['message']['content'];
        }
        // Fallback para outros formatos de resposta
        else if (jsonResponse.containsKey('text')) {
          return jsonResponse['text'];
        } else {
          throw Exception('Formato de resposta não reconhecido: $jsonResponse');
        }
      } else {
        print('Erro na API Requestry: ${response.statusCode} ${response.body}');
        throw Exception('Falha na chamada da API Requestry: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Exceção ao chamar API Requestry: $e');
      throw Exception('Erro ao conectar com a API Requestry: $e');
    }
  }

  // Método para chamar a API da OpenAI
  Future<String> _callOpenAIApi(String prompt) async {
    final url = '$_openaiBaseUrl/chat/completions';

    // Verificar se o prompt é para extração de dados de edital
    bool isEditalExtraction = prompt.contains('edital') &&
                            (prompt.contains('extrair') || prompt.contains('extração') ||
                             prompt.contains('analise') || prompt.contains('análise'));

    // Detectar se é uma extração de edital em formato YAML
    bool isYamlExtraction = isEditalExtraction &&
                          (prompt.contains('YAML') || prompt.contains('yaml'));

    // Detectar se é uma extração de edital em formato JSON
    bool isJsonExtraction = isEditalExtraction &&
                          (prompt.contains('JSON') || prompt.contains('json')) &&
                          !isYamlExtraction; // Priorizar YAML se ambos estiverem presentes

    // Configurar parâmetros específicos para extração de dados de edital
    double temperature = isEditalExtraction ? 0.0 : 0.1;
    int maxTokens = isEditalExtraction ? 8192 : 4096;

    print('Configurando chamada para OpenAI: isEditalExtraction=$isEditalExtraction, temperature=$temperature, maxTokens=$maxTokens');

    // Configurar o formato da resposta com base no tipo de prompt
    // Sempre usar formato de texto para permitir resposta em YAML
    Map<String, dynamic> responseFormat = { 'type': 'text' };
    print('Configurando chamada para extração de edital com OpenAI (formato YAML)');

    final body = jsonEncode({
      'model': _openaiModel,
      'messages': [
        {
          'role': 'system',
          'content': isEditalExtraction
              ? 'Você é um especialista em análise de editais de concursos públicos brasileiros. Sua tarefa é extrair informações estruturadas e retornar APENAS um documento YAML válido, sem texto adicional. NÃO retorne a resposta em formato JSON.'
              : 'Você é um assistente especializado em preparação para concursos públicos brasileiros.'
        },
        {
          'role': 'user',
          'content': prompt
        }
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
      'response_format': responseFormat
    });

    try {
      print('Enviando requisição para a API OpenAI...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        print('Resposta recebida com sucesso da OpenAI. Analisando JSON...');
        final jsonResponse = jsonDecode(response.body);
        print('Estrutura da resposta OpenAI: ${jsonResponse.keys.toList()}');

        // Extrair o texto da resposta - método principal
        if (jsonResponse.containsKey('choices') &&
            jsonResponse['choices'].isNotEmpty &&
            jsonResponse['choices'][0].containsKey('message') &&
            jsonResponse['choices'][0]['message'].containsKey('content')) {

          final text = jsonResponse['choices'][0]['message']['content'];
          print('Texto extraído com sucesso da OpenAI: ${text.substring(0, min<int>(100, text.length))}...');

          // Não precisamos mais verificar se o texto é um JSON válido, pois estamos usando YAML
          if (false) { // Desabilitado
            try {
              // Tentar decodificar o JSON para verificar se é válido
              json.decode(text);
              print('Resposta contém JSON válido');
              return text;
            } catch (e) {
              print('Resposta não é um JSON válido: $e');
              // Tentar extrair JSON da resposta
              final RegExp jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
              final match = jsonRegex.firstMatch(text);

              if (match != null && match.groupCount >= 1) {
                final jsonText = match.group(1)!.trim();
                print('Encontrado JSON entre delimitadores de código');
                try {
                  json.decode(jsonText);
                  print('JSON entre delimitadores é válido');
                  return jsonText;
                } catch (e2) {
                  print('JSON entre delimitadores não é válido: $e2');
                }
              }
              // Retornar o texto original mesmo que não seja JSON válido
              // O processador de JSON irá tentar corrigir depois
            }
          }

          return text;
        }
        // Método alternativo de extração
        else if (jsonResponse.containsKey('choices') &&
                jsonResponse['choices'].isNotEmpty) {
          // Tentar extrair de forma mais flexível
          final choice = jsonResponse['choices'][0];
          print('Estrutura do choice: ${choice.keys.toList()}');

          // Tentar extrair do message diretamente
          if (choice.containsKey('message')) {
            final message = choice['message'];
            print('Estrutura da message: ${message.keys.toList()}');

            // Tentar extrair do content diretamente
            if (message.containsKey('content')) {
              return message['content'];
            }
          }

          // Tentar extrair do texto completo do choice
          return jsonEncode(choice);
        }
        // Último recurso: retornar o corpo completo da resposta
        else {
          print('Não foi possível extrair o texto usando os métodos padrão. Retornando resposta completa.');
          return response.body;
        }
      } else {
        print('Falha na chamada da API OpenAI: ${response.statusCode}');
        print('Corpo da resposta: ${response.body}');
        throw Exception('Falha na chamada da API OpenAI: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Erro ao conectar com a API OpenAI: $e');
      throw Exception('Erro ao conectar com a API OpenAI: $e');
    }
  }
}
