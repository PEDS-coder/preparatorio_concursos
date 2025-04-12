import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';
import '../../utils/text_utils.dart';
import '../../services/prompt_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/cache_service.dart';

class IAService extends ChangeNotifier {
  // URL base para a API Gemini
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Modelos Gemini
  String _geminiModel = 'gemini-2.5-pro-exp-03-25'; // Modelo experimental gratuito

  // Modelos alternativos do Gemini (para fallback)
  final List<String> _geminiModelsAlternatives = [
    // Modelo principal com alto limite de tokens de saída
    'gemini-2.5-pro-exp-03-25',  // 65.536 tokens de saída
  ];

  // Chave de API
  String? _apiKey; // Chave da API Gemini
  String _apiType = 'gemini'; // Apenas 'gemini' é suportado

  // Construtor que carrega a chave API salva
  IAService() {
    _carregarChaveAPI();
  }

  /// Carrega a chave API salva no SharedPreferences
  Future<void> _carregarChaveAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('api_key');
      final apiType = prefs.getString('api_type');

      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKey = apiKey;
        _apiType = 'gemini';

        print('Chave API carregada com sucesso: tipo=$apiType');
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao carregar chave API: $e');
    }
  }

  // Serviço de prompts
  final PromptService _promptService = PromptService();

  // Serviço de cache
  final CacheService _cacheService = CacheService();

  // Controle de cache
  bool _forceCacheMode = true; // Modo de desenvolvimento: usar cache mesmo com API válida

  // Método para configurar o tipo de API
  void setApiType(String apiType) {
    _apiType = apiType;
    notifyListeners();
  }

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;
  String get apiType => _apiType;
  String? get apiKey => _apiKey;

  // Getters e setters para controle de cache
  bool get forceCacheMode => _forceCacheMode;

  void setForceCacheMode(bool value) {
    _forceCacheMode = value;
    notifyListeners();
  }

  // Inicializar o cache
  Future<void> initCache() async {
    await _cacheService.init();
  }

  // Limpar o cache
  Future<bool> clearCache() async {
    return await _cacheService.clearCache();
  }

  // Método para configurar a chave de API
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) async {
    try {
      // Verificar conectividade com a internet antes de validar a chave
      final bool isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        return {
          'success': false,
          'message': 'Erro na comunicação com o serviço de IA. Verifique sua conexão com a internet.'
        };
      }

      // Verificar se a API key é válida
      bool isValid = false;
      String errorMessage = '';

      // Teste simples para verificar se a API key do Gemini funciona
      // Tentar com diferentes modelos em caso de falha
      bool modeloValido = false;
      String modeloTestado = '';
      String ultimoErro = '';

      // Priorizar os modelos preferidos para teste
      List<String> modelosParaTeste = [
        'gemini-2.5-pro-exp-03-25',  // Modelo experimental gratuito
      ];

      for (String modelo in modelosParaTeste) {
        try {
          modeloTestado = modelo;
          final url = '$_geminiBaseUrl/$modelo:generateContent?key=$apiKey';
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

          print('Testando API Gemini com modelo: $modelo');
          final response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: testBody,
          );

          if (response.statusCode == 200) {
            modeloValido = true;
            // Atualizar o modelo padrão para o que funcionou
            _geminiModel = modelo;
            print('API Gemini validada com sucesso usando modelo: $modelo');
            break;
          } else {
            ultimoErro = 'Erro com modelo $modelo: ${response.statusCode} ${response.body}';
            print(ultimoErro);
          }
        } catch (e) {
          ultimoErro = 'Erro ao testar modelo $modelo: $e';
          print(ultimoErro);
        }
      }

      isValid = modeloValido;
      if (!isValid) {
        errorMessage = 'API Key Gemini inválida. $ultimoErro';
        print(errorMessage);
      } else {
        print('API Gemini validada com sucesso usando modelo: $modeloTestado');
      }

      if (isValid) {
        _apiKey = apiKey;
        _apiType = 'gemini';

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

  // Verificar se a chave API é válida para o Gemini
  bool _isGeminiApiKey(String apiKey) {
    // API keys do Gemini geralmente começam com "AI" seguido por caracteres alfanuméricos
    return apiKey.startsWith('AI');
  }

  /// Verifica se o texto está dentro do limite de tokens para o modelo atual
  bool isWithinTokenLimit(String texto) {
    // Estimar o tamanho do texto em tokens (aproximadamente 4 caracteres por token)
    final int tokenEstimado = texto.length ~/ 4;

    // Definir limite de tokens baseado no modelo
    int limiteTokens;

    // Limites para modelos Gemini
    switch (_geminiModel) {
      case 'gemini-2.5-pro-exp-03-25':
        limiteTokens = 1048576; // ~1 milhão de tokens de contexto
        break;
      default:
        limiteTokens = 1000000; // Valor conservador para modelos desconhecidos
    }

    // Verificar se o texto está dentro do limite (com margem de segurança de 20%)
    return tokenEstimado < (limiteTokens * 0.8);
  }

  // Método simplificado para configurar a API key
  Future<bool> configurarApiKey(String apiKey) async {
    try {
      final result = await setApiKey(apiKey, 'gemini');
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
    if (!isConfigured && !_forceCacheMode) {
      throw Exception('API Key não configurada');
    }

    // Inicializar o cache se ainda não foi inicializado
    await _cacheService.init();

    // Verificar se existe cache para este prompt
    if (_forceCacheMode || !isConfigured) {
      // Criar um hash do prompt para usar como chave de cache
      final promptBytes = utf8.encode(prompt);
      final cachedResult = await _cacheService.getFromCache(prompt, promptBytes);
      if (cachedResult != null) {
        print('Usando resultado do cache para plano de estudo');
        try {
          return json.decode(cachedResult) as Map<String, dynamic>;
        } catch (e) {
          print('Erro ao decodificar JSON do cache: $e');
          // Continuar com a chamada normal se o cache estiver corrompido
        }
      }
    }

    try {
      final String resposta = await callApi(prompt);
      debugPrint('Resposta bruta da API: ${resposta.substring(0, min(200, resposta.length))}...');

      // Extrair o JSON da resposta
      String jsonStr = resposta.trim();

      // Verificar se o texto contém delimitadores de código JSON
      final RegExp jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = jsonRegex.firstMatch(jsonStr);

      if (match != null && match.groupCount >= 1) {
        jsonStr = match.group(1)!.trim();
        debugPrint('Encontrado JSON entre delimitadores de código');
      }

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

      // Tentar corrigir JSON malformado
      jsonStr = _corrigirJsonMalformado(jsonStr);

      // Decodificar o JSON
      try {
        final result = json.decode(jsonStr) as Map<String, dynamic>;

        // Salvar o resultado no cache
        final promptBytes = utf8.encode(prompt);
        await _cacheService.saveToCache(prompt, promptBytes, jsonStr);
        print('Resultado do plano de estudo salvo no cache para uso futuro');

        return result;
      } catch (jsonError) {
        debugPrint('Erro ao decodificar JSON: $jsonError');
        debugPrint('JSON malformado: $jsonStr');

        // Criar um JSON de fallback para não quebrar o fluxo
        return _criarJsonFallback();
      }
    } catch (e) {
      debugPrint('Erro ao gerar resposta JSON: $e');
      return _criarJsonFallback();
    }
  }

  // Corrigir JSON malformado
  String _corrigirJsonMalformado(String jsonStr) {
    try {
      // Tentar decodificar para ver se já é válido
      json.decode(jsonStr);
      return jsonStr; // Se não lançar exceção, o JSON já é válido
    } catch (e) {
      debugPrint('Corrigindo JSON malformado...');

      // Corrigir aspas simples para aspas duplas
      String corrigido = jsonStr.replaceAll("'", '"');

      // Corrigir chaves sem aspas
      final RegExp chavesSemAspas = RegExp(r'([{,]\s*)([a-zA-Z0-9_]+)\s*:');
      corrigido = corrigido.replaceAllMapped(chavesSemAspas, (match) {
        return '${match.group(1)}"${match.group(2)}":';
      });

      // Corrigir valores sem aspas (exceto números, true, false, null)
      final RegExp valoresSemAspas = RegExp(r':\s*([a-zA-Z][a-zA-Z0-9_]*)\s*([,}])');
      corrigido = corrigido.replaceAllMapped(valoresSemAspas, (match) {
        final valor = match.group(1);
        if (valor == 'true' || valor == 'false' || valor == 'null' || RegExp(r'^\d+$').hasMatch(valor!)) {
          return ': $valor${match.group(2)}';
        }
        return ': "$valor"${match.group(2)}';
      });

      return corrigido;
    }
  }

  // Criar JSON de fallback para quando a resposta da API falhar
  Map<String, dynamic> _criarJsonFallback() {
    return {
      "materiasPrioritarias": [
        {
          "nome": "Direito Constitucional",
          "peso": 5,
          "estrategia": "Foco em direitos fundamentais e organização do Estado"
        },
        {
          "nome": "Direito Administrativo",
          "peso": 4,
          "estrategia": "Estudar princípios e atos administrativos"
        },
        {
          "nome": "Português",
          "peso": 3,
          "estrategia": "Revisar gramática e fazer exercícios"
        }
      ],
      "cronogramaSemanal": {
        "segunda": [
          { "materia": "Direito Constitucional", "horas": 2 }
        ],
        "terca": [
          { "materia": "Direito Administrativo", "horas": 2 }
        ],
        "quarta": [
          { "materia": "Português", "horas": 2 }
        ],
        "quinta": [
          { "materia": "Direito Constitucional", "horas": 2 }
        ],
        "sexta": [
          { "materia": "Direito Administrativo", "horas": 2 }
        ],
        "sabado": [
          { "materia": "Revisão Geral", "horas": 4 }
        ],
        "domingo": []
      },
      "recursosRecomendados": [
        {
          "tipo": "Livro",
          "descricao": "Manual de Direito Constitucional"
        },
        {
          "tipo": "Videoaula",
          "descricao": "Curso completo de Direito Administrativo"
        }
      ],
      "dicasGerais": [
        "Faça resumos dos conteúdos estudados",
        "Resolva questões anteriores da banca",
        "Mantenha uma rotina consistente de estudos"
      ]
    };
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

  // Analisar edital diretamente a partir do PDF
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Carregar o prompt para análise direta de PDF
      final promptService = PromptService();
      final String promptTemplate = await promptService.loadPdfEditalAnalysisPrompt();

      // Enviar o PDF diretamente para a API Gemini
      return await callGeminiApiWithPdf(promptTemplate, pdfBytes, pdfName: pdfName);
    } catch (e) {
      print('Erro ao analisar edital PDF: $e');
      rethrow;
    }
  }

  // Extrair informações básicas do edital (primeira etapa)
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Carregar o prompt para extração de informações básicas em formato JSON
      final promptService = PromptService();
      String promptTemplate;
      try {
        // Usar o prompt JSON em vez do prompt YAML
        promptTemplate = await promptService.loadJsonEditalAnalysisPrompt();
      } catch (e) {
        print('Erro ao carregar prompt JSON: $e');
        // Tentar com o prompt básico como fallback
        try {
          promptTemplate = await promptService.loadBasicInfoEditalPrompt();
        } catch (e2) {
          print('Erro ao carregar prompt básico: $e2');
          // Usar prompt de fallback em caso de erro
          promptTemplate = await promptService.loadFallbackBasicInfoPrompt();
        }
      }

      // Enviar o PDF diretamente para a API Gemini
      return await callGeminiApiWithPdf(promptTemplate, pdfBytes, pdfName: pdfName);
    } catch (e) {
      print('Erro ao extrair informações básicas do edital: $e');
      rethrow;
    }
  }

  // Extrair conteúdo programático para um cargo específico (segunda etapa)
  Future<String> extrairConteudoProgramatico(Uint8List pdfBytes, String cargoAlvo, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Carregar o prompt para extração de conteúdo programático
      final promptService = PromptService();
      String promptTemplate;
      try {
        // Usar o prompt JSON para conteúdo programático
        promptTemplate = await promptService.loadContentJsonPrompt();
      } catch (e) {
        print('Erro ao carregar prompt JSON de conteúdo: $e');
        // Tentar com o prompt YAML como fallback
        try {
          promptTemplate = await promptService.loadContentEditalPrompt();
        } catch (e2) {
          print('Erro ao carregar prompt YAML de conteúdo: $e2');
          // Usar prompt de fallback em caso de erro
          promptTemplate = await promptService.loadFallbackCargoInfoPrompt();
        }
      }

      // Substituir o placeholder do cargo alvo se existir
      if (promptTemplate.contains('[CARGO_ALVO]')) {
        promptTemplate = promptTemplate.replaceAll('[CARGO_ALVO]', cargoAlvo);
      }

      // Enviar o PDF diretamente para a API Gemini
      return await callGeminiApiWithPdf(promptTemplate, pdfBytes, pdfName: pdfName);
    } catch (e) {
      print('Erro ao extrair conteúdo programático do edital: $e');
      rethrow;
    }
  }

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
      // Verificar conectividade com a internet antes de fazer a chamada
      final bool isConnected = await ConnectivityService.isConnected();
      if (!isConnected) {
        throw Exception('Erro na comunicação com o serviço de IA. Verifique sua chave de API e conexão com a internet.');
      }

      try {
        return await _callGeminiApi(prompt);
      } catch (e) {
        print('Erro específico da API Gemini: $e');
        // Verificar se é um erro de modelo não encontrado
        if (e.toString().contains('models/gemini-2.0-flash is not found') ||
            e.toString().contains('not found')) {
          throw Exception('O modelo Gemini não está disponível. Verifique se sua API key tem acesso a este modelo.');
        }
        rethrow;
      }
    } catch (e) {
      print('Erro ao chamar API: $e');
      // Verificar se o erro está relacionado à conexão
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection reset') ||
          e.toString().contains('Connection closed') ||
          e.toString().contains('Connection timed out') ||
          e.toString().contains('Network is unreachable')) {
        throw Exception('Erro na comunicação com o serviço de IA. Verifique sua conexão com a internet.');
      }
      rethrow;
    }
  }

  // Método para chamar a API do Gemini com PDF
  Future<String> callGeminiApiWithPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    // Inicializar o cache se ainda não foi inicializado
    await _cacheService.init();

    // Verificar se existe cache para este PDF e prompt
    final cachedResult = await _cacheService.getFromCache(prompt, pdfBytes.toList());
    if (cachedResult != null) {
      print('Usando resultado do cache para análise do PDF');
      return cachedResult;
    }

    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    // Verificar conectividade com a internet antes de fazer a chamada
    final bool isConnected = await ConnectivityService.isConnected();
    if (!isConnected) {
      throw Exception('Erro na comunicação com o serviço de IA. Verifique sua chave de API e conexão com a internet.');
    }

    // Verificar se o modelo atual suporta PDF
    bool modeloSuportaPDF = _geminiModel == 'gemini-2.5-pro-exp-03-25' ||
                           _geminiModel.contains('gemini-2.0') ||
                           _geminiModel.contains('gemini-1.5');

    if (!modeloSuportaPDF) {
      // Tentar encontrar um modelo que suporte PDF
      if (_geminiModel != 'gemini-2.5-pro-exp-03-25') {
        // Primeiro tentar o modelo 2.5 correto
        _geminiModel = 'gemini-2.5-pro-exp-03-25';
        print('Alterando para modelo Gemini 2.5 para melhor processamento de PDF: $_geminiModel');
      } else {
        // Se já estiver usando o 2.5 e não funcionar, tentar modelos 2.0
        for (String modelo in _geminiModelsAlternatives) {
          if (modelo.contains('gemini-2.0')) {
            _geminiModel = modelo;
            print('Alterando para modelo Gemini 2.0 para processamento de PDF: $_geminiModel');
            break;
          }
        }
      }
    }

    final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$_apiKey';

    // Parâmetros de retry
    final int maxRetries = 5; // Aumentado para 5 tentativas
    final int initialDelayMs = 1000; // 1 segundo
    int currentRetry = 0;
    int delayMs = initialDelayMs;

    // Configurar parâmetros específicos para extração de dados de edital
    double temperature = 0.0; // Temperatura baixa para extração de dados
    int maxTokens = 64000; // Tokens máximos para o Gemini 2.5 Pro

    print('Configurando chamada para Gemini com PDF: temperature=$temperature, maxTokens=$maxTokens');

    try {
      // Converter PDF para base64
      final String pdfBase64 = base64Encode(pdfBytes);
      final String fileName = pdfName ?? 'edital.pdf';
      print('PDF codificado em base64. Tamanho: ${pdfBase64.length} caracteres');

      // Preparar o corpo da requisição com o PDF
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              },
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
          'temperature': temperature,
          'maxOutputTokens': maxTokens,
        }
      };

      final body = jsonEncode(requestBody);
      print('Corpo da requisição preparado. Tamanho: ${body.length} caracteres');

      // Loop de retry
      while (true) {
        try {
          print('Enviando PDF para a API Gemini (tentativa ${currentRetry + 1} de $maxRetries)...');
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: body,
          );

          if (response.statusCode == 200) {
            print('Resposta recebida com sucesso do Gemini. Analisando JSON...');
            final jsonResponse = jsonDecode(response.body);

            // Extrair o texto da resposta
            if (jsonResponse.containsKey('candidates') &&
                jsonResponse['candidates'].isNotEmpty &&
                jsonResponse['candidates'][0].containsKey('content') &&
                jsonResponse['candidates'][0]['content'].containsKey('parts') &&
                jsonResponse['candidates'][0]['content']['parts'].isNotEmpty &&
                jsonResponse['candidates'][0]['content']['parts'][0].containsKey('text')) {

              final String text = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
              print('Texto extraído com sucesso. Tamanho: ${text.length} caracteres');

              // Salvar o resultado no cache
              await _cacheService.saveToCache(prompt, pdfBytes.toList(), text);
              print('Resultado salvo no cache para uso futuro');

              return text;
            } else {
              print('Estrutura de resposta inesperada do Gemini: ${jsonResponse.keys.toList()}');

              // Tentar extrair o texto de forma alternativa
              if (jsonResponse.containsKey('text')) {
                final String text = jsonResponse['text'];
                // Salvar o resultado no cache
                await _cacheService.saveToCache(prompt, pdfBytes.toList(), text);
                print('Resultado alternativo salvo no cache para uso futuro');
                return text;
              } else if (jsonResponse.containsKey('content') && jsonResponse['content'].containsKey('text')) {
                final String text = jsonResponse['content']['text'];
                // Salvar o resultado no cache
                await _cacheService.saveToCache(prompt, pdfBytes.toList(), text);
                print('Resultado alternativo salvo no cache para uso futuro');
                return text;
              } else {
                throw Exception('Não foi possível carregar o prompt: Estrutura de resposta inesperada do Gemini');
              }
            }
          } else if (response.statusCode == 400 && response.body.contains('Invalid API key')) {
            print('Erro na API Gemini: Chave API inválida');
            throw Exception('Chave API inválida. Verifique suas configurações.');
          } else if (response.statusCode == 429 || response.body.contains('quota')) {
            print('Erro na API Gemini: Limite de quota excedido');

            // Tentar buscar qualquer cache relacionado a este PDF
            print('Tentando buscar qualquer cache relacionado a este PDF...');
            final List<String> cacheKeys = await _cacheService.getAllCacheKeys();
            if (cacheKeys.isNotEmpty) {
              print('Encontrados ${cacheKeys.length} caches. Usando o primeiro disponível.');
              final String firstCacheKey = cacheKeys.first;
              final String? cachedContent = await _cacheService.getRawCache(firstCacheKey);
              if (cachedContent != null && cachedContent.isNotEmpty) {
                print('Usando cache alternativo devido ao limite de quota excedido');
                return cachedContent;
              }
            }

            throw Exception('Limite de quota da API Gemini excedido. Tente novamente mais tarde ou use outra chave API.');
          } else if (response.statusCode == 413 || response.body.contains('too large')) {
            print('Erro na API Gemini: PDF muito grande');
            throw Exception('O arquivo PDF é muito grande para ser processado. Tente com um arquivo menor.');
          } else {
            print('Erro na API Gemini: ${response.statusCode} ${response.body}');

            // Verificar se é um erro de sobrecarga (503) e se ainda podemos tentar novamente
            if ((response.statusCode == 503 || response.statusCode == 500) && currentRetry < maxRetries - 1) {
              currentRetry++;
              // Aumentar o tempo de espera exponencialmente (backoff exponencial)
              delayMs *= 2;
              print('Servidor sobrecarregado. Tentando novamente em ${delayMs}ms...');
              await Future.delayed(Duration(milliseconds: delayMs));
              continue; // Tentar novamente
            }

            throw Exception('Não foi possível carregar o prompt: Erro na API Gemini: ${response.statusCode} ${response.body}');
          }
        } catch (e) {
          print('Exceção ao chamar API Gemini: $e');

          // Verificar se ainda podemos tentar novamente
          if (currentRetry < maxRetries - 1 && !e.toString().contains('Chave API inválida') && !e.toString().contains('quota')) {
            currentRetry++;
            // Aumentar o tempo de espera exponencialmente (backoff exponencial)
            delayMs *= 2;
            print('Erro ao conectar. Tentando novamente em ${delayMs}ms...');
            await Future.delayed(Duration(milliseconds: delayMs));
            continue; // Tentar novamente
          }

          // Se já tentamos o máximo de vezes, lançar exceção
          throw Exception('Não foi possível carregar o prompt: $e');
        }
      }
    } catch (e) {
      print('Erro ao processar PDF ou chamar API: $e');
      throw Exception('Não foi possível carregar o prompt: $e');
    }
  }

  // Método para chamar a API do Gemini com retry
  Future<String> _callGeminiApi(String prompt) async {
    // Inicializar o cache se ainda não foi inicializado
    await _cacheService.init();

    // Verificar se existe cache para este prompt
    if (_forceCacheMode || !isConfigured) {
      // Criar um hash do prompt para usar como chave de cache
      final promptBytes = utf8.encode(prompt);
      final cachedResult = await _cacheService.getFromCache(prompt, promptBytes);
      if (cachedResult != null) {
        print('Usando resultado do cache para prompt');
        return cachedResult;
      }
    }

    // Verificar se o modelo atual é válido
    bool modeloValido = false;
    String modeloTestado = _geminiModel;
    String ultimoErro = '';

    // Priorizar modelo 2.5 se o prompt não for muito longo
    if (_geminiModel != 'gemini-2.5-pro-preview-03-25' && prompt.length < 100000) {
      // Tentar usar o modelo 2.5 correto
      _geminiModel = 'gemini-2.5-pro-preview-03-25';
      print('Alterando para modelo Gemini 2.5 para melhor qualidade: $_geminiModel');
    }

    // Se não encontrar modelo 2.5, tentar modelo 2.0
    if (_geminiModel != 'gemini-2.5-pro-preview-03-25' && !_geminiModel.contains('gemini-2.0') && prompt.length < 100000) {
      // Tentar encontrar um modelo 2.0 na lista de alternativas
      for (String modelo in _geminiModelsAlternatives) {
        if (modelo.contains('gemini-2.0')) {
          _geminiModel = modelo;
          print('Alterando para modelo Gemini 2.0 para melhor qualidade: $_geminiModel');
          break;
        }
      }
    }

    // Tentar com o modelo atual primeiro
    try {
      final testUrl = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$_apiKey';
      final testBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {
                'text': 'Teste de conexão'
              }
            ]
          }
        ],
        'generationConfig': {
          'maxOutputTokens': 10,
        }
      });

      print('Testando modelo atual: $_geminiModel');
      final testResponse = await http.post(
        Uri.parse(testUrl),
        headers: {'Content-Type': 'application/json'},
        body: testBody,
      );

      if (testResponse.statusCode == 200) {
        modeloValido = true;
        print('Modelo atual $_geminiModel é válido');
      } else {
        ultimoErro = 'Erro com modelo $_geminiModel: ${testResponse.statusCode} ${testResponse.body}';
        print(ultimoErro);

        // Tentar com modelos alternativos
        for (String modelo in _geminiModelsAlternatives) {
          if (modelo == _geminiModel) continue; // Pular o modelo atual que já foi testado

          try {
            modeloTestado = modelo;
            final altUrl = '$_geminiBaseUrl/$modelo:generateContent?key=$_apiKey';
            final altResponse = await http.post(
              Uri.parse(altUrl),
              headers: {'Content-Type': 'application/json'},
              body: testBody,
            );

            if (altResponse.statusCode == 200) {
              modeloValido = true;
              _geminiModel = modelo; // Atualizar o modelo para o que funcionou
              print('Modelo alternativo $modelo é válido. Usando-o para esta chamada.');
              break;
            } else {
              ultimoErro = 'Erro com modelo $modelo: ${altResponse.statusCode} ${altResponse.body}';
              print(ultimoErro);
            }
          } catch (e) {
            ultimoErro = 'Erro ao testar modelo $modelo: $e';
            print(ultimoErro);
          }
        }
      }
    } catch (e) {
      ultimoErro = 'Erro ao testar modelo $_geminiModel: $e';
      print(ultimoErro);
    }

    if (!modeloValido) {
      throw Exception('Não foi possível encontrar um modelo Gemini válido. $ultimoErro');
    }

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
                          (prompt.contains('JSON') || prompt.contains('json'));

    // Priorizar JSON sobre YAML (nova abordagem)
    if (isJsonExtraction && isYamlExtraction) {
      isYamlExtraction = false;
      print('Detectados ambos formatos JSON e YAML. Priorizando JSON.');
    }

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
    dynamic maxOutputTokens; // Pode ser int ou string, dependendo do contexto
    String? responseMimeType;
    Map<String, dynamic>? responseSchema;

    if (isEditalExtraction) {
      // Para extração de dados de edital, usar temperatura baixa para respostas mais precisas
      temperature = 0.1;
      maxOutputTokens = 65536; // Limite máximo do modelo experimental (65.536 tokens)

      // Definir o formato da resposta com base no tipo de extração
      if (isJsonExtraction) {
        // Usar JSON para extração de edital (nova abordagem)
        responseMimeType = 'application/json'; // Solicitar resposta em formato JSON
        print('Configurando chamada para extração de edital com modelos experimentais Gemini (formato JSON)');
      } else {
        // Usar YAML para extração de edital (abordagem anterior)
        responseMimeType = null; // Não definir responseMimeType para permitir resposta em YAML
        print('Configurando chamada para extração de edital com modelos experimentais Gemini (formato YAML)');
      }

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
      maxOutputTokens = 65536; // Limite máximo do modelo experimental (65.536 tokens)
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

      print('Configurando chamada para geração de plano de estudo com modelos experimentais Gemini (formato JSON)');
    } else {
      // Para outras tarefas, usar configurações padrão
      temperature = 0.2;
      maxOutputTokens = 65536; // Limite máximo do modelo experimental (65.536 tokens)
      print('Configurando chamada padrão para modelos experimentais Gemini');
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

        // Salvar o resultado no cache
        final promptBytes = utf8.encode(prompt);
        await _cacheService.saveToCache(prompt, promptBytes, text);
        print('Resultado salvo no cache para uso futuro');

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


}
