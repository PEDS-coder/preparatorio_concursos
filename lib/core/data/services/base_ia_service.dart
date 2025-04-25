import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as Math;
import 'package:flutter/foundation.dart';
import '../models/flashcard.dart';
import 'interfaces/ia_service_interface.dart';
import '../../services/cache_service.dart';
import '../../services/prompt_service.dart';
import '../../utils/logger_adapter.dart';
import '../../utils/text_utils.dart';

/// Classe base abstrata para serviços de IA
abstract class BaseIAService extends ChangeNotifier implements IAServiceInterface {
  // Serviço de prompts
  final PromptService _promptService = PromptService();

  // Serviço de cache
  final CacheService _cacheService = CacheService();

  // Controle de cache
  bool _forceCacheMode = true; // Modo de desenvolvimento: usar cache mesmo com API válida

  // Chave de API
  String? apiKey_;
  String _apiType;

  // Construtor
  BaseIAService(this._apiType) {
    _carregarChaveAPI();
  }

  /// Carrega a chave de API salva
  Future<void> _carregarChaveAPI() async {
    try {
      // Implementação específica para carregar a chave API
      // Será implementada nas classes concretas
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao carregar chave API', e);
    }
  }

  @override
  bool get isConfigured => apiKey_ != null && apiKey_!.isNotEmpty;

  @override
  String get apiType => _apiType;

  @override
  String? get apiKey => apiKey_;

  // Getters e setters para controle de cache
  bool get forceCacheMode => _forceCacheMode;

  void setForceCacheMode(bool value) {
    _forceCacheMode = value;
    notifyListeners();
  }

  // Método para configurar o tipo de API
  @override
  void setApiType(String apiType) {
    _apiType = apiType;
    notifyListeners();
  }

  @override
  Future<void> initCache() async {
    await _cacheService.init();
  }

  @override
  Future<bool> clearCache() async {
    return await _cacheService.clearCache();
  }

  @override
  Future<Map<String, dynamic>> setApiKey(String apiKey, String apiType) async {
    // Implementação base que será sobrescrita nas classes concretas
    throw UnimplementedError('Método setApiKey deve ser implementado nas classes concretas');
  }

  @override
  Future<bool> configurarApiKey(String apiKey) async {
    try {
      final result = await setApiKey(apiKey, _apiType);
      return result['success'] as bool;
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao configurar API key', e);
      return false;
    }
  }

  @override
  Future<String> callApiWithPrompt(String prompt) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }
    return await callApi(prompt);
  }

  @override
  Future<String> callApi(String prompt) async {
    try {
      AppLogger.i('BaseIAService', 'Iniciando chamada à API...');
      AppLogger.d('BaseIAService', 'Prompt: ${prompt.substring(0, Math.min(100, prompt.length))}...');

      // Verificar se a API está configurada
      if (!isConfigured) {
        AppLogger.e('BaseIAService', 'API Key não configurada');
        throw Exception('API Key não configurada');
      }

      // Implementação base que será sobrescrita nas classes concretas
      throw UnimplementedError('Método callApi deve ser implementado nas classes concretas');
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro na chamada à API', e);
      rethrow;
    }
  }

  // Método para analisar JSON da resposta
  dynamic parseJsonResponse(String jsonString) {
    try {
      return json.decode(jsonString);
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao fazer parse do JSON', e);
      throw Exception('Resposta não é um JSON válido: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> gerarRespostaJson(String prompt) async {
    if (!isConfigured) {
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
        AppLogger.i('BaseIAService', 'Usando resultado do cache para plano de estudo');
        try {
          return json.decode(cachedResult) as Map<String, dynamic>;
        } catch (e) {
          AppLogger.e('BaseIAService', 'Erro ao decodificar JSON do cache', e);
          // Continuar com a chamada normal se o cache estiver corrompido
        }
      }
    }

    try {
      final String resposta = await callApi(prompt);
      AppLogger.d('BaseIAService', 'Resposta bruta da API: ${resposta.substring(0, resposta.length < 200 ? resposta.length : 200)}...');

      // Extrair o JSON da resposta
      String jsonStr = resposta.trim();

      // Verificar se o texto contém delimitadores de código JSON
      final RegExp jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
      final match = jsonRegex.firstMatch(jsonStr);

      if (match != null && match.groupCount >= 1) {
        jsonStr = match.group(1)!.trim();
        AppLogger.d('BaseIAService', 'Encontrado JSON entre delimitadores de código');
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
        AppLogger.i('BaseIAService', 'Resultado do plano de estudo salvo no cache para uso futuro');

        return result;
      } catch (jsonError) {
        AppLogger.e('BaseIAService', 'Erro ao decodificar JSON', jsonError);
        AppLogger.e('BaseIAService', 'JSON malformado: $jsonStr');

        // Criar um JSON de fallback para não quebrar o fluxo
        return _criarJsonFallback();
      }
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao gerar resposta JSON', e);
      return _criarJsonFallback();
    }
  }

  // Método para corrigir JSON malformado
  String _corrigirJsonMalformado(String jsonStr) {
    // Substituir aspas simples por aspas duplas
    jsonStr = jsonStr.replaceAll("'", '"');

    // Remover caracteres de controle
    jsonStr = jsonStr.replaceAll(RegExp(r'[\u0000-\u001F]'), '');

    // Remover comentários
    jsonStr = jsonStr.replaceAll(RegExp(r'//.*'), '');
    jsonStr = jsonStr.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

    return jsonStr;
  }

  // Método para criar um JSON de fallback em caso de erro
  Map<String, dynamic> _criarJsonFallback() {
    return {
      'erro': true,
      'mensagem': 'Não foi possível gerar o plano de estudo. Tente novamente mais tarde.'
    };
  }

  @override
  Future<String> analisarEditalPdf(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      AppLogger.i('BaseIAService', 'Iniciando análise de edital PDF...');

      // Carregar o prompt para análise direta de PDF
      final String promptTemplate = await _promptService.loadPdfEditalAnalysisPrompt();
      AppLogger.i('BaseIAService', 'Prompt carregado com sucesso: ${promptTemplate.substring(0, Math.min(100, promptTemplate.length))}...');

      // Implementação específica para cada provedor
      AppLogger.i('BaseIAService', 'Chamando processamento de PDF...');

      // Implementação abstrata - cada provedor deve implementar seu próprio método
      return await processarPdf(promptTemplate, pdfBytes, pdfName: pdfName);
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao analisar edital PDF', e);
      rethrow;
    }
  }

  @override
  Future<String> extrairCargosEdital(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      AppLogger.i('BaseIAService', 'Iniciando extração de cargos do edital...');

      // Carregar o prompt para extração de cargos
      String promptTemplate;
      try {
        // Usar o prompt para análise de PDF
        AppLogger.i('BaseIAService', 'Carregando prompt para extração de cargos...');
        promptTemplate = await _promptService.loadPdfEditalAnalysisPrompt();
        AppLogger.i('BaseIAService', 'Prompt carregado com sucesso: ${promptTemplate.substring(0, Math.min(100, promptTemplate.length))}...');
      } catch (e) {
        AppLogger.e('BaseIAService', 'Erro ao carregar prompt de cargos', e);
        // Usar prompt de fallback em caso de erro
        AppLogger.i('BaseIAService', 'Usando prompt de fallback...');
        promptTemplate = await _promptService.loadFallbackBasicInfoPrompt();
      }

      // Implementação específica para cada provedor
      AppLogger.i('BaseIAService', 'Chamando processarPdf para processar o PDF...');
      final resultado = await processarPdf(promptTemplate, pdfBytes, pdfName: pdfName);
      AppLogger.i('BaseIAService', 'PDF processado com sucesso!');
      return resultado;
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao extrair cargos do edital', e);
      rethrow;
    }
  }

  @override
  Future<String> extrairInfoBasicasEdital(Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    try {
      // Carregar o prompt para extração de informações básicas em formato JSON
      String promptTemplate;
      try {
        // Usar o prompt JSON em vez do prompt YAML
        promptTemplate = await _promptService.loadJsonEditalAnalysisPrompt();
      } catch (e) {
        AppLogger.e('BaseIAService', 'Erro ao carregar prompt JSON', e);
        // Usar prompt de fallback em caso de erro
        promptTemplate = await _promptService.loadFallbackBasicInfoPrompt();
      }

      // Implementação específica para cada provedor
      AppLogger.i('BaseIAService', 'Chamando processarPdf para processar o PDF...');
      final resultado = await processarPdf(promptTemplate, pdfBytes, pdfName: pdfName);
      AppLogger.i('BaseIAService', 'PDF processado com sucesso!');
      return resultado;
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao extrair informações básicas do edital', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> extrairConcursoConteudo({
    required Uint8List pdfBytes,
    required String cargoAlvo,
    String? pdfName,
  });

  @override
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

        return await callApi(prompt);
      } else {
        // Para textos longos, processar cada parte separadamente e combinar os resultados
        final List<String> resumosParciais = [];

        for (int i = 0; i < textChunks.length; i++) {
          // Carregar o prompt base para geração de resumos
          String promptTemplate = await _promptService.loadSummaryGenerationPrompt();

          // Personalizar o prompt com o texto específico
          final Map<String, String> variables = {
            'texto': textChunks[i]
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables);

          // Adicionar informação sobre a parte atual
          final promptComInfo = '''
$prompt

OBSERVAÇÃO IMPORTANTE: Você está resumindo a parte ${i+1} de ${textChunks.length} de um documento maior.
''';

          final resumoParcial = await callApi(promptComInfo);
          resumosParciais.add(resumoParcial);
        }

        // Combinar todos os resumos parciais
        final resumosCombinados = resumosParciais.join('\n\n--- PRÓXIMA PARTE ---\n\n');

        // Se o resumo combinado for muito grande, fazer um resumo final
        if (resumosCombinados.length > 10000) {
          // Carregar o prompt base para geração de resumos
          String promptTemplate = await _promptService.loadSummaryGenerationPrompt();

          // Personalizar o prompt com o texto específico
          final Map<String, String> variables = {
            'texto': resumosCombinados
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables);

          // Adicionar informação sobre o resumo final
          final promptComInfo = '''
$prompt

OBSERVAÇÃO IMPORTANTE: Este é um resumo de resumos parciais. Mantenha apenas as informações mais importantes.
''';

          return await callApi(promptComInfo);
        }

        return resumosCombinados;
      }
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao gerar resumo', e);
      throw Exception('Erro ao gerar resumo: $e');
    }
  }

  @override
  Future<String> gerarEsquema({
    required String texto,
    String? titulo,
  }) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

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
          'titulo': titulo ?? 'Mapa Mental'
        };

        final prompt = _promptService.customizePrompt(promptTemplate, variables);

        return await callApi(prompt);
      } else {
        // Para textos longos, processar cada parte separadamente e combinar os resultados
        final List<String> esquemasParciais = [];

        for (int i = 0; i < textChunks.length; i++) {
          // Carregar o prompt base para geração de mapas mentais
          String promptTemplate = await _promptService.loadMindmapGenerationPrompt();

          // Personalizar o prompt com o texto específico e título
          final Map<String, String> variables = {
            'texto': textChunks[i],
            'titulo': titulo != null ? '$titulo - Parte ${i+1}' : 'Mapa Mental - Parte ${i+1}'
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables);

          // Adicionar informação sobre a parte atual
          final promptComInfo = '''
$prompt

OBSERVAÇÃO IMPORTANTE: Você está criando um mapa mental para a parte ${i+1} de ${textChunks.length} de um documento maior.
''';

          final esquemaParcial = await callApi(promptComInfo);
          esquemasParciais.add(esquemaParcial);
        }

        // Combinar todos os esquemas parciais
        return esquemasParciais.join('\n\n--- PRÓXIMA PARTE ---\n\n');
      }
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao gerar esquema', e);
      throw Exception('Erro ao gerar esquema: $e');
    }
  }

  @override
  Future<String> gerarQuestoes({
    required String texto,
    required String materia,
    required String dificuldade,
    required int quantidade,
  }) async {
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

        return await callApi(prompt);
      } else {
        // Para textos longos, processar cada parte separadamente e combinar os resultados
        final List<String> todasQuestoes = [];
        final int questoesPorParte = (quantidade / textChunks.length).ceil();

        for (int i = 0; i < textChunks.length; i++) {
          // Carregar o prompt base para geração de questões
          String promptTemplate = await _promptService.loadQuestionGenerationPrompt();

          // Personalizar o prompt com o texto específico
          final Map<String, String> variables = {
            'texto': textChunks[i],
            'materia': materia,
            'dificuldade': dificuldade,
            'quantidade': questoesPorParte.toString()
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables);

          // Adicionar informação sobre a parte atual
          final promptComInfo = '''
$prompt

OBSERVAÇÃO IMPORTANTE: Você está analisando a parte ${i+1} de ${textChunks.length} de um documento maior.
Crie apenas $questoesPorParte questões para esta parte específica do texto.
''';

          final questoesParciais = await callApi(promptComInfo);
          todasQuestoes.add(questoesParciais);
        }

        // Combinar todas as questões geradas
        return todasQuestoes.join('\n\n--- PRÓXIMA PARTE ---\n\n');
      }
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao gerar questões', e);
      throw Exception('Erro ao gerar questões: $e');
    }
  }

  @override
  Future<List<Flashcard>> gerarFlashcards({
    required String userId,
    String? editalId,
    required String materia,
    required String texto,
  }) async {
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

        final response = await callApi(prompt);
        return _parseFlashcardsFromText(response, userId, editalId, materia);
      } else {
        // Para textos longos, processar cada parte separadamente e combinar os resultados
        for (int i = 0; i < textChunks.length; i++) {
          // Carregar o prompt base para geração de flashcards
          String promptTemplate = await _promptService.loadFlashcardGenerationPrompt();

          // Personalizar o prompt com o texto específico
          final Map<String, String> variables = {
            'texto': textChunks[i],
            'materia': materia
          };

          final prompt = _promptService.customizePrompt(promptTemplate, variables);

          // Adicionar informação sobre a parte atual
          final promptComInfo = '''
$prompt

OBSERVAÇÃO IMPORTANTE: Você está analisando a parte ${i+1} de ${textChunks.length} de um documento maior.
''';

          final response = await callApi(promptComInfo);
          final flashcards = _parseFlashcardsFromText(response, userId, editalId, materia);
          allFlashcards.addAll(flashcards);
        }

        return allFlashcards;
      }
    } catch (e) {
      AppLogger.e('BaseIAService', 'Erro ao gerar flashcards', e);
      throw Exception('Erro ao gerar flashcards: $e');
    }
  }

  // Método abstrato para processar PDF - deve ser implementado nas classes concretas
  @override
  Future<String> processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName});

  // Método para verificar se o texto está dentro do limite de tokens
  @override
  bool isWithinTokenLimit(String texto) {
    // Implementação base que será sobrescrita nas classes concretas
    throw UnimplementedError('Método isWithinTokenLimit deve ser implementado nas classes concretas');
  }

  // Método para analisar flashcards a partir do texto
  List<Flashcard> _parseFlashcardsFromText(String text, String userId, String? editalId, String materia) {
    final List<Flashcard> flashcards = [];

    // Expressão regular para encontrar flashcards no formato:
    // Flashcard X:
    // Pergunta: ...
    // Resposta: ...
    final RegExp flashcardRegex = RegExp(
      r'(?:Flashcard\s+\d+:|Flashcard:|Cartão\s+\d+:|Cartão:)\s*(?:\n|\r\n?)(Pergunta|Q|Questão|Frente):\s*(.*?)(?:\n|\r\n?)(Resposta|R|A|Verso):\s*(.*?)(?=(?:\n|\r\n?)(?:Flashcard\s+\d+:|Flashcard:|Cartão\s+\d+:|Cartão:)|$)',
      caseSensitive: false,
      dotAll: true,
    );

    // Encontrar todos os flashcards no texto
    final matches = flashcardRegex.allMatches(text);

    for (final match in matches) {
      if (match.groupCount >= 4) {
        final pergunta = match.group(2)?.trim() ?? '';
        final resposta = match.group(4)?.trim() ?? '';

        if (pergunta.isNotEmpty && resposta.isNotEmpty) {
          final flashcard = Flashcard(
            id: DateTime.now().millisecondsSinceEpoch.toString() + flashcards.length.toString(),
            userId: userId,
            editalId: editalId,
            materia: materia,
            pergunta: pergunta,
            resposta: resposta,
            fonte: 'ia',
          );

          flashcards.add(flashcard);
        }
      }
    }

    return flashcards;
  }
}
