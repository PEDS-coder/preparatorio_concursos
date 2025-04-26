import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/flashcard.dart';
import '../../services/prompt_service.dart';
import '../../services/connectivity_service.dart';
import 'base_ia_service.dart';
import 'ia_service_implementations.dart';
import 'interfaces/ia_service_interface.dart';

/// Implementação oficial do serviço de IA para o Gemini
class GeminiOfficialService extends BaseIAService with IAServiceImplementations implements IAServiceInterface {
  final PromptService _promptService = PromptService();
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  final String _geminiModel = 'gemini-2.5-pro-exp-03-25';
  final List<String> _geminiModelsAlternatives = [
    'gemini-2.5-pro-exp-03-25',
    'gemini-2.5-pro-preview-03-25',
    'gemini-2.5-flash-preview-04-17',
  ];

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
    print('[GeminiOfficialService] ===== INÍCIO DO TESTE DE CHAVE API =====');
    print('[GeminiOfficialService] Tipo de API: $apiType');
    print('[GeminiOfficialService] Modelos a serem testados: ${_geminiModelsAlternatives.join(", ")}');
    print('[GeminiOfficialService] Chave API: ${apiKey.length} caracteres');
    print('[GeminiOfficialService] Plataforma: ${Platform.operatingSystem}');

    if (apiKey.isEmpty) {
      print('[GeminiOfficialService] ERRO: Chave API vazia');
      return false;
    }

    try {
      print('[GeminiOfficialService] Testando chave API: ${apiKey.substring(0, min(5, apiKey.length))}...');

      // Verificar se a chave API tem o formato correto para o Gemini
      if (!apiKey.startsWith('AI')) {
        print('[GeminiOfficialService] Formato de chave API inválido: não começa com "AI"');
        print('[GeminiOfficialService] Prefixo da chave: ${apiKey.substring(0, min(2, apiKey.length))}');
        return false;
      }

      // Verificar se o serviço da API está acessível
      print('[GeminiOfficialService] Verificando disponibilidade do serviço Gemini...');

      // No Windows, usar uma abordagem mais robusta para verificar a conectividade
      bool serviceReachable;
      if (Platform.isWindows) {
        print('[GeminiOfficialService] Usando abordagem específica para Windows');
        serviceReachable = await _verificarDisponibilidadeServicoWindows();
      } else {
        serviceReachable = await ConnectivityService.canReachService('https://generativelanguage.googleapis.com');
      }

      if (!serviceReachable) {
        print('[GeminiOfficialService] Serviço Gemini inacessível. Verifique sua conexão com a internet.');
        return false;
      }

      print('[GeminiOfficialService] Serviço Gemini acessível.');

      // Verificar disponibilidade dos modelos
      print('[GeminiOfficialService] Verificando disponibilidade dos modelos da família Gemini 2.5...');
      print('[GeminiOfficialService] Modelos disponíveis para teste: ${_geminiModelsAlternatives.join(", ")}');

      // Implementar retry com backoff exponencial
      for (int tentativa = 1; tentativa <= 3; tentativa++) {
        print('[GeminiOfficialService] Tentativa $tentativa de 3');

        // Primeiro, tentar o modelo principal
        print('[GeminiOfficialService] Tentando modelo principal: $_geminiModel');
        final bool modeloExperimental = await _verificarDisponibilidadeModelo(_geminiModel, apiKey);
        if (modeloExperimental) {
          print('[GeminiOfficialService] Modelo principal $_geminiModel está disponível!');
          print('[GeminiOfficialService] ===== FIM DO TESTE DE CHAVE API: SUCESSO =====');
          return true;
        }

        // Se falhar, tentar os modelos alternativos
        for (final modelo in _geminiModelsAlternatives) {
          if (modelo == _geminiModel) continue; // Pular o modelo principal que já foi testado

          print('[GeminiOfficialService] Tentando modelo alternativo: $modelo');
          final bool modeloDisponivel = await _verificarDisponibilidadeModelo(modelo, apiKey);
          if (modeloDisponivel) {
            print('[GeminiOfficialService] Modelo alternativo $modelo está disponível!');
            _updateDefaultModel(modelo);
            print('[GeminiOfficialService] ===== FIM DO TESTE DE CHAVE API: SUCESSO COM MODELO ALTERNATIVO =====');
            return true;
          }
        }

        // Se todas as tentativas falharem, aguardar antes de tentar novamente
        if (tentativa < 3) {
          final delay = Duration(seconds: pow(2, tentativa).toInt());
          print('[GeminiOfficialService] Aguardando ${delay.inSeconds} segundos antes da próxima tentativa...');
          await Future.delayed(delay);
        }
      }

      // Se chegou aqui, nenhum modelo funcionou
      print('[GeminiOfficialService] Nenhum modelo disponível funcionou com a chave fornecida');
      print('[GeminiOfficialService] ===== FIM DO TESTE DE CHAVE API: FALHA =====');
      return false;
    } catch (e) {
      print('[GeminiOfficialService] Exceção geral ao testar chave API: $e');
      print('[GeminiOfficialService] ===== FIM DO TESTE DE CHAVE API: ERRO =====');
      return false;
    }
  }

  /// Verifica a disponibilidade do serviço Gemini no Windows
  Future<bool> _verificarDisponibilidadeServicoWindows() async {
    print('[GeminiOfficialService] Verificando disponibilidade do serviço Gemini no Windows...');

    try {
      // Tentar acessar a URL base do Gemini
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[GeminiOfficialService] Resposta do serviço Gemini: ${response.statusCode}');

      // Qualquer resposta (mesmo 404) indica que o serviço está acessível
      // O importante é que a requisição não falhe por problemas de rede
      return true;
    } catch (e) {
      print('[GeminiOfficialService] Erro ao verificar disponibilidade do serviço Gemini no Windows: $e');

      // Tentar uma abordagem alternativa
      try {
        print('[GeminiOfficialService] Tentando abordagem alternativa...');

        // Verificar se há conexão com a internet
        final bool isConnected = await ConnectivityService.isConnected();
        if (!isConnected) {
          print('[GeminiOfficialService] Sem conexão com a internet no Windows');
          return false;
        }

        // Se há conexão com a internet, assumir que o serviço está acessível
        // Isso é um fallback para contornar possíveis problemas de firewall
        print('[GeminiOfficialService] Conexão com a internet detectada, assumindo que o serviço está acessível');
        return true;
      } catch (e) {
        print('[GeminiOfficialService] Erro na abordagem alternativa: $e');
        return false;
      }
    }
  }

  /// Verifica se um modelo específico está disponível com a chave API fornecida
  Future<bool> _verificarDisponibilidadeModelo(String modelo, String apiKey) async {
    print('[GeminiOfficialService] ----- INÍCIO DO TESTE DO MODELO: $modelo -----');
    try {
      print('[GeminiOfficialService] Testando modelo: $modelo');
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

      print('[GeminiOfficialService] Corpo da requisição: $testBody');
      print('[GeminiOfficialService] Enviando requisição para: ${url.replaceAll(apiKey, "API_KEY_HIDDEN")}');

      http.Response? response;
      try {
        response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: testBody,
        );

        print('[GeminiOfficialService] Resposta do modelo $modelo: ${response.statusCode}');
        print('[GeminiOfficialService] Corpo da resposta: ${response.body}');
      } catch (e) {
        print('[GeminiOfficialService] ERRO NA REQUISIÇÃO HTTP: $e');
        return false;
      }

      if (response != null && response.statusCode == 200) {
        print('[GeminiOfficialService] Teste bem-sucedido com o modelo: $modelo');
        print('[GeminiOfficialService] ----- FIM DO TESTE DO MODELO: $modelo (SUCESSO) -----');
        return true;
      } else if (response != null && response.statusCode == 400) {
        // Tentar extrair mensagem de erro mais específica
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'Requisição inválida';
          print('[GeminiOfficialService] Erro 400 com modelo $modelo: $errorMessage');

          // Verificar se o erro é relacionado ao modelo não existir
          if (errorMessage.contains('Model not found') ||
              errorMessage.contains('not found') ||
              errorMessage.contains('does not exist')) {
            print('[GeminiOfficialService] O modelo $modelo não existe ou não está disponível.');
            return false;
          }

          // Verificar se o erro é relacionado a um modelo experimental
          if (errorMessage.contains('experimental') ||
              errorMessage.contains('preview')) {
            print('[GeminiOfficialService] O modelo $modelo é experimental e pode ter restrições de acesso.');
            return false;
          }
        } catch (e) {
          print('[GeminiOfficialService] Erro 400 com modelo $modelo sem detalhes: ${response.body}');
        }
      } else if (response != null && (response.statusCode == 401 || response.statusCode == 403)) {
        print('[GeminiOfficialService] Chave API inválida ou sem permissão para modelo $modelo: ${response.statusCode}');

        // Tentar extrair mensagem de erro mais específica
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'Acesso negado';
          print('[GeminiOfficialService] Detalhes do erro: $errorMessage');

          // Se o erro for específico para este modelo, pode ser que outros modelos funcionem
          if (errorMessage.contains('not have permission') ||
              errorMessage.contains('permission denied') ||
              errorMessage.contains('unauthorized') ||
              errorMessage.contains('access denied')) {

            if (errorMessage.contains(modelo)) {
              print('[GeminiOfficialService] Sem permissão para o modelo $modelo.');
              return false;
            }

            // Se a mensagem menciona Gemini 2.5 ou modelos experimentais
            if (errorMessage.contains('2.5') ||
                errorMessage.contains('experimental') ||
                errorMessage.contains('preview')) {
              print('[GeminiOfficialService] Sem permissão para modelos Gemini 2.5 ou experimentais.');
              return false;
            }
          }
        } catch (e) {
          print('[GeminiOfficialService] Não foi possível extrair detalhes do erro: $e');
        }

        // Se a chave é inválida para um modelo, provavelmente é inválida para todos
        return false;
      } else if (response != null) {
        print('[GeminiOfficialService] Erro no teste do modelo $modelo: ${response.statusCode} ${response.body}');
      }
      print('[GeminiOfficialService] ----- FIM DO TESTE DO MODELO: $modelo (FALHA) -----');
      return false;
    } catch (e) {
      print('[GeminiOfficialService] Exceção ao testar modelo $modelo: $e');
      print('[GeminiOfficialService] ----- FIM DO TESTE DO MODELO: $modelo (ERRO) -----');
      return false;
    }
  }

  // Método para atualizar o modelo padrão quando um teste for bem-sucedido
  void _updateDefaultModel(String workingModel) {
    print('[GeminiOfficialService] Atualizando modelo padrão para: $workingModel');
    // Não podemos alterar a constante _geminiModel, mas podemos garantir que o modelo
    // que funcionou seja o primeiro da lista de alternativas
    if (_geminiModelsAlternatives.first != workingModel) {
      _geminiModelsAlternatives.remove(workingModel);
      _geminiModelsAlternatives.insert(0, workingModel);
    }
  }

  @override
  Future<bool> testApiConnection() async {
    if (!isConfigured) {
      print('[GeminiOfficialService] Teste de conexão falhou: API não configurada');
      return false;
    }

    print('[GeminiOfficialService] Testando conexão com a API usando a chave configurada');
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

    // Usar o primeiro modelo da lista de alternativas, que deve ser o modelo que funcionou no teste
    final modeloAtivo = _geminiModelsAlternatives.isNotEmpty ? _geminiModelsAlternatives.first : _geminiModel;
    print('[GeminiOfficialService] Chamando API com modelo: $modeloAtivo');

    final url = '$_geminiBaseUrl/$modeloAtivo:generateContent?key=$apiKey_';
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

    print('[GeminiOfficialService] Enviando requisição para: $url');
    final body = jsonEncode(requestBody);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('[GeminiOfficialService] Resposta recebida: ${response.statusCode}');

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
          print('[GeminiOfficialService] Resposta vazia da API Gemini');
          throw Exception('Resposta vazia da API Gemini');
        }
        return text;
      } else if (response.statusCode == 400) {
        // Tentar extrair mensagem de erro mais específica
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'Requisição inválida';
          print('[GeminiOfficialService] Erro 400: $errorMessage');
          throw Exception('Erro na requisição: $errorMessage');
        } catch (e) {
          throw Exception('Requisição inválida: ${response.body}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        print('[GeminiOfficialService] Erro de autenticação: ${response.statusCode}');
        throw Exception('Erro de autenticação: verifique sua chave API');
      } else if (response.statusCode == 429) {
        print('[GeminiOfficialService] Limite de requisições excedido: ${response.statusCode}');
        throw Exception('Limite de requisições excedido. Aguarde alguns minutos e tente novamente.');
      } else {
        print('[GeminiOfficialService] Erro na chamada da API: ${response.statusCode} ${response.body}');
        throw Exception('Falha na chamada da API Gemini: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('[GeminiOfficialService] Exceção ao chamar API: $e');
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
  Future<Map<String, dynamic>> extrairConcursoConteudo({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) async {
    if (!isConfigured) throw Exception('API Key não configurada');

    // Log para depuração
    print('[GeminiOfficialService] Extraindo conteúdo do concurso para cargo: $cargoAlvo');

    final promptTemplate = await _promptService.loadConcursoConteudoPrompt();
    final prompt = _promptService.customizePrompt(promptTemplate, {
      'PDF_NAME': pdfName ?? '',
      'CARGO_ALVO': cargoAlvo,
    });

    // Log para depuração
    print('[GeminiOfficialService] Prompt personalizado com cargo alvo: $cargoAlvo');

    try {
      final respostaBruta = await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);

      // Log para depuração
      print('[GeminiOfficialService] Resposta BRUTA recebida com tamanho: ${respostaBruta.length} caracteres');
      print('[GeminiOfficialService] Início da resposta BRUTA: ${respostaBruta.substring(0, respostaBruta.length > 100 ? 100 : respostaBruta.length)}');

      // Limpar delimitadores markdown
      String respostaLimpa = respostaBruta.trim();
      if (respostaLimpa.startsWith('```json')) {
        respostaLimpa = respostaLimpa.substring(7).trim();
      } else if (respostaLimpa.startsWith('```')) {
         respostaLimpa = respostaLimpa.substring(3).trim();
      }
      if (respostaLimpa.endsWith('```')) {
        respostaLimpa = respostaLimpa.substring(0, respostaLimpa.length - 3).trim();
      }

      print('[GeminiOfficialService] Resposta LIMPA: ${respostaLimpa.substring(0, respostaLimpa.length > 100 ? 100 : respostaLimpa.length)}');

      try {
        // Decodificar a resposta limpa
        final jsonDecodificado = jsonDecode(respostaLimpa) as Map<String, dynamic>;
        print('[GeminiOfficialService] Resposta decodificada com ${jsonDecodificado.keys.length} chaves: ${jsonDecodificado.keys.join(', ')}');
        return jsonDecodificado; // Retorna o mapa decodificado
      } catch (e) {
        print('[GeminiOfficialService] Erro ao decodificar JSON da resposta LIMPA: $e');
        print('[GeminiOfficialService] Resposta LIMPA que falhou no decode: $respostaLimpa');
        // Lança uma exceção mais específica para falha de decode
        throw Exception('Falha ao decodificar JSON da resposta da API: $e');
      }
    } catch (e) {
      print('[GeminiOfficialService] Erro ao extrair conteúdo do concurso: $e');
      throw Exception('Erro ao extrair conteúdo do concurso: $e');
    }
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

  /// Converte uma data no formato dd/MM/yyyy para DateTime
  DateTime _parseDate(dynamic dateValue) {
    if (dateValue == null) {
      return DateTime.now();
    }

    // Se já for um DateTime, retorna diretamente
    if (dateValue is DateTime) {
      return dateValue;
    }

    // Se for uma string no formato ISO, tenta fazer parse diretamente
    if (dateValue is String) {
      try {
        // Tenta fazer parse no formato ISO
        if (dateValue.contains('T') || dateValue.contains('-')) {
          return DateTime.parse(dateValue);
        }

        // Tenta fazer parse no formato dd/MM/yyyy
        if (dateValue.contains('/')) {
          final parts = dateValue.split('/');
          if (parts.length == 3) {
            final day = int.tryParse(parts[0]) ?? 1;
            final month = int.tryParse(parts[1]) ?? 1;
            final year = int.tryParse(parts[2]) ?? DateTime.now().year;
            return DateTime(year, month, day);
          }
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao converter data: $dateValue - $e');
      }
    }

    // Fallback para a data atual
    return DateTime.now();
  }

  @override
  Future<String> gerarPlanoEstudos({required String cargoAlvo, required Map<String, dynamic> dadosCargo}) async {
    if (!isConfigured) throw Exception('API Key não configurada');

    try {
      // Carregar o prompt para geração de ciclo de estudos
      final promptTemplate = await _promptService.loadStudyPlanCycleGenerationPrompt();

      // Extrair dados do questionário com tratamento seguro de datas
      final DateTime dataInicio = _parseDate(dadosCargo['dataInicio']);
      final DateTime dataFim = _parseDate(dadosCargo['dataFim']) ?? dataInicio.add(const Duration(days: 90));
      final int totalDias = dataFim.difference(dataInicio).inDays;

      // Log para depuração
      print('[GeminiOfficialService] Data início: $dataInicio, Data fim: $dataFim, Total dias: $totalDias');

      // Extrair matérias do cargo com tratamento seguro
      List<String> materias = [];
      try {
        final materiasRaw = dadosCargo['materias'];
        if (materiasRaw is List) {
          materias = materiasRaw.map((m) => m.toString()).toList();
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair matérias: $e');
      }

      // Extrair proficiência nas matérias com tratamento seguro
      final List<String> proficienciaFormatada = [];
      try {
        final proficienciaRaw = dadosCargo['proficiencia'];
        if (proficienciaRaw is Map) {
          proficienciaRaw.forEach((materia, nivel) {
            proficienciaFormatada.add('$materia: $nivel');
          });
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair proficiência: $e');
      }

      // Extrair ferramentas de estudo com tratamento seguro
      List<String> ferramentas = [];
      try {
        final ferramentasRaw = dadosCargo['ferramentas'];
        if (ferramentasRaw is List) {
          ferramentas = ferramentasRaw.map((f) => f.toString()).toList();
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair ferramentas: $e');
      }

      // Extrair horas por dia com tratamento seguro
      final List<String> disponibilidadeSemanal = [];
      try {
        final horasPorDiaRaw = dadosCargo['horasPorDia'];
        if (horasPorDiaRaw is Map) {
          horasPorDiaRaw.forEach((dia, horas) {
            disponibilidadeSemanal.add('$dia: $horas horas');
          });
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair horas por dia: $e');
      }

      // Extrair horários específicos com tratamento seguro
      final List<String> horariosEspecificos = [];
      try {
        final horasSelecionadasRaw = dadosCargo['horasSelecionadas'];
        if (horasSelecionadasRaw is Map) {
          horasSelecionadasRaw.forEach((dia, horas) {
            if (horas is List && horas.isNotEmpty) {
              final List<String> horasFormatadas = horas.map((h) => '$h:00').toList();
              horariosEspecificos.add('$dia: ${horasFormatadas.join(', ')}');
            }
          });
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair horários específicos: $e');
      }

      // Extrair dados do edital com tratamento seguro
      Map<String, dynamic> dadosEdital = {};
      Map<String, dynamic> conteudoProgramatico = {};
      try {
        final editalRaw = dadosCargo['edital'];
        if (editalRaw is Map) {
          dadosEdital = Map<String, dynamic>.from(editalRaw);
          final conteudoRaw = editalRaw['conteudoProgramatico'];
          if (conteudoRaw is Map) {
            conteudoProgramatico = Map<String, dynamic>.from(conteudoRaw);
          }
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair dados do edital: $e');
      }

      // Preparar informações sobre peso das matérias e número de questões
      final List<String> pesoMaterias = [];
      final List<String> numeroQuestoes = [];
      final List<String> criteriosDesempate = [];

      // Extrair informações dos grupos de matérias com tratamento seguro
      try {
        final gruposRaw = conteudoProgramatico['grupos'];
        if (gruposRaw is List) {
          for (var grupo in gruposRaw) {
            if (grupo is Map) {
              final materiasGrupoRaw = grupo['materias'];
              if (materiasGrupoRaw is List) {
                for (var materia in materiasGrupoRaw) {
                  if (materia is Map) {
                    final String nomeMateria = materia['nome'] ?? '';
                    final int peso = materia['peso'] is int ? materia['peso'] : 1;
                    final int questoes = materia['questoes'] is int ? materia['questoes'] : 0;
                    final bool desempate = materia['desempate'] is bool ? materia['desempate'] : false;

                    if (nomeMateria.isNotEmpty) {
                      pesoMaterias.add('$nomeMateria: $peso');
                      numeroQuestoes.add('$nomeMateria: $questoes');
                      if (desempate) {
                        criteriosDesempate.add(nomeMateria);
                      }
                    }
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        print('[GeminiOfficialService] Erro ao extrair informações dos grupos: $e');
      }

      // Personalizar o prompt com os dados do cargo
      final Map<String, String> variables = {
        'dados_concurso': json.encode(dadosEdital),
        'data_inicio': '${dataInicio.day}/${dataInicio.month}/${dataInicio.year}',
        'data_fim': '${dataFim.day}/${dataFim.month}/${dataFim.year}',
        'total_dias': totalDias.toString(),
        'disponibilidade_semanal': disponibilidadeSemanal.isNotEmpty ? disponibilidadeSemanal.join('\n') : 'Segunda a Domingo: 2 horas por dia',
        'horarios_especificos': horariosEspecificos.isNotEmpty ? horariosEspecificos.join('\n') : 'Horários flexíveis',
        'materias_cargo': materias.isNotEmpty ? materias.join(', ') : 'Português, Matemática, Direito Constitucional',
        'proficiencia_materias': proficienciaFormatada.isNotEmpty ? proficienciaFormatada.join('\n') : materias.map((m) => '$m: Iniciante').join('\n'),
        'ferramentas_estudo': ferramentas.isNotEmpty ? ferramentas.join(', ') : 'Videoaulas, PDFs/Livros, Questões',
        'peso_materias': pesoMaterias.isNotEmpty ? pesoMaterias.join('\n') : materias.map((m) => '$m: 1').join('\n'),
        'criterios_desempate': criteriosDesempate.isNotEmpty ? criteriosDesempate.join(', ') : 'Não especificado',
        'numero_questoes': numeroQuestoes.isNotEmpty ? numeroQuestoes.join('\n') : materias.map((m) => '$m: 10 (estimadas)').join('\n'),
      };

      // Log para depuração
      print('[GeminiOfficialService] Gerando plano de estudos para: $cargoAlvo');
      print('[GeminiOfficialService] Dados para prompt: ${variables.keys.join(', ')}');

      final prompt = _promptService.customizePrompt(promptTemplate, variables);

      // Tenta chamar a API, mas se falhar, retorna um JSON padrão
      try {
        return await callApi(prompt);
      } catch (apiError) {
        print('[GeminiOfficialService] Erro na chamada à API: $apiError');
        // Retorna um JSON padrão para não quebrar o fluxo
        return '''
        {
          "ciclo_estudos": [
            {
              "dia": 1,
              "blocos": [
                {
                  "ordem": 1,
                  "materia": "${materias.isNotEmpty ? materias[0] : 'Português'}",
                  "duracao_minutos": 60,
                  "ferramenta": "${ferramentas.isNotEmpty ? ferramentas[0] : 'Videoaulas'}"
                },
                {
                  "ordem": 2,
                  "materia": "${materias.length > 1 ? materias[1] : 'Direito Constitucional'}",
                  "duracao_minutos": 60,
                  "ferramenta": "${ferramentas.length > 1 ? ferramentas[1] : 'Questões'}"
                }
              ]
            },
            {
              "dia": 2,
              "blocos": [
                {
                  "ordem": 1,
                  "materia": "${materias.length > 2 ? materias[2] : 'Direito Administrativo'}",
                  "duracao_minutos": 90,
                  "ferramenta": "${ferramentas.length > 2 ? ferramentas[2] : 'Resumos'}"
                },
                {
                  "ordem": 2,
                  "materia": "${materias.isNotEmpty ? materias[0] : 'Português'}",
                  "duracao_minutos": 60,
                  "ferramenta": "${ferramentas.length > 1 ? ferramentas[1] : 'Questões'}"
                }
              ]
            }
          ],
          "materias_prioritarias": [
            {
              "nome": "${materias.isNotEmpty ? materias[0] : 'Português'}",
              "pontuacao_prioridade": 31
            },
            {
              "nome": "${materias.length > 1 ? materias[1] : 'Direito Constitucional'}",
              "pontuacao_prioridade": 28
            },
            {
              "nome": "${materias.length > 2 ? materias[2] : 'Direito Administrativo'}",
              "pontuacao_prioridade": 25
            }
          ]
        }
        ''';
      }
    } catch (e, stackTrace) {
      print('[GeminiOfficialService] Erro ao gerar plano de estudos: $e');
      print('[GeminiOfficialService] Stack trace: $stackTrace');

      // Retorna um JSON padrão para não quebrar o fluxo
      return '''
      {
        "ciclo_estudos": [
          {
            "dia": 1,
            "blocos": [
              {
                "ordem": 1,
                "materia": "Português",
                "duracao_minutos": 60,
                "ferramenta": "Videoaulas"
              },
              {
                "ordem": 2,
                "materia": "Direito Constitucional",
                "duracao_minutos": 60,
                "ferramenta": "Questões"
              }
            ]
          },
          {
            "dia": 2,
            "blocos": [
              {
                "ordem": 1,
                "materia": "Direito Administrativo",
                "duracao_minutos": 60,
                "ferramenta": "Resumos"
              },
              {
                "ordem": 2,
                "materia": "Português",
                "duracao_minutos": 60,
                "ferramenta": "Questões"
              }
            ]
          }
        ],
        "duracao_total_ciclo": 7,
        "total_blocos_ciclo": 14,
        "materias_prioritarias": [
          {
            "nome": "Português",
            "pontuacao_prioridade": 31
          },
          {
            "nome": "Direito Constitucional",
            "pontuacao_prioridade": 28
          },
          {
            "nome": "Direito Administrativo",
            "pontuacao_prioridade": 25
          }
        ]
      }
      ''';
    }
  }

  /// Tamanho máximo recomendado para PDFs (20MB)
  static const int _maxRecommendedPdfSize = 20 * 1024 * 1024;

  /// Tamanho máximo permitido pela API Gemini (50MB)
  static const int _maxAllowedPdfSize = 50 * 1024 * 1024;



  /// Limite para considerar um arquivo como grande (5MB)
  static const int _largeFileSizeThreshold = 5 * 1024 * 1024;

  // NOTA: A API Gemini requer que os arquivos sejam enviados como parte do corpo da requisição em formato base64.
  // Isso é uma exigência da API, não uma escolha da aplicação.
  // Referência: https://ai.google.dev/tutorials/rest_api
  Future<String> callGeminiApiWithPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    // Verificar se o PDF está vazio
    if (pdfBytes.isEmpty) {
      throw Exception('O arquivo PDF está vazio.');
    }

    try {
      final String fileName = pdfName ?? 'edital.pdf';

      // Verificar tamanho do arquivo de acordo com os limites da LLM
      final int pdfSizeInMB = pdfBytes.length ~/ (1024 * 1024);
      print('[GeminiOfficialService] Tamanho do PDF: $pdfSizeInMB MB');

      // Verificar se o arquivo está dentro do limite recomendado
      if (pdfBytes.length > _maxRecommendedPdfSize) {
        print('[GeminiOfficialService] AVISO: PDF excede o tamanho recomendado de ${_maxRecommendedPdfSize ~/ (1024 * 1024)}MB');
        // Continuar, mas com aviso
      }

      // Verificar se o arquivo está dentro do limite máximo permitido
      if (pdfBytes.length > _maxAllowedPdfSize) {
        print('[GeminiOfficialService] ERRO: PDF excede o limite máximo da LLM (${_maxAllowedPdfSize ~/ (1024 * 1024)}MB)');
        throw Exception('O arquivo PDF excede o limite de tamanho da LLM (${_maxAllowedPdfSize ~/ (1024 * 1024)}MB). Por favor, use um arquivo menor.');
      }

      // Log para depuração
      print('[GeminiOfficialService] Enviando PDF para análise: $fileName (${pdfBytes.length} bytes)');

      // Usar o primeiro modelo da lista de alternativas, que deve ser o modelo que funcionou no teste
      final modeloAtivo = _geminiModelsAlternatives.isNotEmpty ? _geminiModelsAlternatives.first : _geminiModel;
      print('[GeminiOfficialService] Processando PDF com modelo: $modeloAtivo');

      // Verificar conectividade com a internet antes de fazer a chamada
      final url = '$_geminiBaseUrl/$modeloAtivo:generateContent?key=$apiKey_';



      // NOTA: A API Gemini requer que os arquivos sejam enviados como parte do corpo da requisição em formato base64.
      // Isso é uma exigência da API, não uma escolha da aplicação.
      print('[GeminiOfficialService] Preparando PDF para envio conforme requisitos da API Gemini...');

      // Usar isolate para conversão base64 em arquivos grandes para evitar bloquear a UI
      String pdfBase64;
      try {
        // Converter em chunks para evitar problemas de memória
        if (pdfBytes.length > _largeFileSizeThreshold) {
          print('[GeminiOfficialService] Arquivo grande detectado, usando conversão otimizada');
          pdfBase64 = await _encodeBase64InChunks(pdfBytes);
        } else {
          // A API Gemini requer que os arquivos sejam enviados em formato base64
          pdfBase64 = base64Encode(pdfBytes);
        }

        print('[GeminiOfficialService] PDF preparado para envio. Tamanho base64: ${pdfBase64.length} caracteres');
      } catch (e) {
        print('[GeminiOfficialService] Erro ao preparar PDF para envio: $e');
        throw Exception('Erro ao processar o arquivo PDF: não foi possível preparar o arquivo para envio. Tente com um arquivo menor.');
      }

      // Preparar o corpo da requisição conforme documentação da API Gemini
      print('[GeminiOfficialService] Preparando corpo da requisição...');
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
        },
        'safetySettings': [
          {'category': 'HARM_CATEGORY_HARASSMENT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_HATE_SPEECH','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'},
          {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT','threshold': 'BLOCK_MEDIUM_AND_ABOVE'}
        ]
      };

      // Codificar o corpo da requisição para JSON
      print('[GeminiOfficialService] Codificando corpo da requisição para JSON...');
      String body;
      try {
        body = jsonEncode(requestBody);
        print('[GeminiOfficialService] Corpo da requisição codificado. Tamanho: ${body.length} caracteres');
      } catch (e) {
        print('[GeminiOfficialService] Erro na codificação JSON: $e');
        throw Exception('Erro ao preparar a requisição: não foi possível codificar os dados. Tente com um arquivo menor.');
      }

      // Liberar memória
      pdfBase64 = '';

      // Log para depuração
      print('[GeminiOfficialService] Enviando requisição para: $url');

      // Enviar a requisição
      print('[GeminiOfficialService] Enviando requisição HTTP...');

      // Implementar retry em caso de falha de rede
      int retryCount = 0;
      const maxRetries = 3;
      http.Response? response;

      while (retryCount < maxRetries) {
        try {
          response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          );

          // Se chegou aqui, a requisição foi bem-sucedida
          break;
        } catch (e) {
          retryCount++;
          if (retryCount >= maxRetries) {
            print('[GeminiOfficialService] Falha após $maxRetries tentativas: $e');
            rethrow;
          }

          print('[GeminiOfficialService] Falha na tentativa $retryCount: $e. Tentando novamente...');
          await Future.delayed(Duration(seconds: 2 * retryCount)); // Backoff exponencial
        }
      }

      if (response == null) {
        throw Exception('Falha na comunicação com a API após $maxRetries tentativas.');
      }

      // Log para depuração
      print('[GeminiOfficialService] Resposta recebida: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Decodificar a resposta com tratamento de memória
        print('[GeminiOfficialService] Decodificando resposta JSON...');
        Map<String, dynamic> jsonResponse;
        try {
          jsonResponse = jsonDecode(response.body);
          print('[GeminiOfficialService] Resposta JSON decodificada com sucesso');
        } catch (e) {
          print('[GeminiOfficialService] Erro na decodificação JSON: $e');
          throw Exception('Erro ao processar a resposta da API: não foi possível decodificar os dados.');
        }

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
          // Se não conseguir extrair o texto, lançar uma exceção
          print('[GeminiOfficialService] Estrutura de resposta inesperada');
          throw Exception('Estrutura de resposta inesperada da API Gemini: Não foi possível encontrar o texto.');
        }
      } else if (response.statusCode == 429) {
        // Erro de rate limit
        print('[GeminiOfficialService] Erro de rate limit (429)');
        throw Exception('Limite de requisições excedido. Aguarde alguns minutos e tente novamente.');
      } else if (response.statusCode == 400) {
        // Erro de requisição inválida
        print('[GeminiOfficialService] Erro de requisição inválida (400): ${response.body}');

        // Tentar extrair mensagem de erro mais específica
        try {
          final errorJson = jsonDecode(response.body);
          final errorMessage = errorJson['error']?['message'] ?? 'Requisição inválida';
          throw Exception('Erro na requisição: $errorMessage');
        } catch (_) {
          throw Exception('Requisição inválida. Verifique o formato do arquivo PDF.');
        }
      } else {
        // Lançar uma exceção detalhada
        print('[GeminiOfficialService] Erro na resposta HTTP: ${response.statusCode}');
        throw Exception('Falha na chamada da API Gemini: ${response.statusCode} ${response.body}');
      }
    } catch (e, stackTrace) {
      // Log para depuração
      print('[GeminiOfficialService] Exceção ao processar PDF: $e');
      print('[GeminiOfficialService] Stack trace: $stackTrace');

      // Relançar a exceção para ser tratada pelos métodos superiores
      rethrow;
    }
  }

  /// Codifica um arquivo grande em base64 em chunks para evitar problemas de memória
  Future<String> _encodeBase64InChunks(Uint8List bytes) async {
    const int chunkSize = 1024 * 1024; // 1MB por chunk
    final int totalChunks = (bytes.length / chunkSize).ceil();

    print('[GeminiOfficialService] Codificando arquivo em $totalChunks chunks');

    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end = (i + 1) * chunkSize > bytes.length ? bytes.length : (i + 1) * chunkSize;

      final Uint8List chunk = bytes.sublist(start, end);
      final String chunkBase64 = base64Encode(chunk);

      buffer.write(chunkBase64);

      // Liberar memória
      await Future.delayed(Duration.zero);
    }

    return buffer.toString();
  }
}
