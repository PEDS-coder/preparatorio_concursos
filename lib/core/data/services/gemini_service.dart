import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'base_ia_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/cache_service.dart';
import '../../utils/logger_adapter.dart';

/// Implementação do serviço de IA para o Gemini
class GeminiService extends BaseIAService {
  // URL base para a API Gemini
  final String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';

  // Serviço de cache
  final CacheService _cacheService = CacheService();

  // Modelos Gemini
  String _geminiModel = 'gemini-2.5-pro-exp-03-25'; // Modelo experimental gratuito

  // Modelos alternativos do Gemini (para fallback)
  final List<String> _geminiModelsAlternatives = [
    // Modelo principal com alto limite de tokens de saída
    'gemini-2.5-pro-exp-03-25',  // 65.536 tokens de saída
  ];

  // Construtor
  GeminiService() : super('gemini') {
    _carregarChaveAPI();
  }

  // Método para carregar a chave API
  Future<void> _carregarChaveAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key');
      if (apiKey != null && apiKey.isNotEmpty) {
        apiKey_ = apiKey;
        AppLogger.i('GeminiService', 'Chave API Gemini carregada com sucesso');
      } else {
        AppLogger.w('GeminiService', 'Nenhuma chave API Gemini encontrada');
      }
    } catch (e) {
      AppLogger.e('GeminiService', 'Erro ao carregar chave API Gemini', e);
    }
  }

  @override
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

      // Validar a chave API testando com diferentes modelos
      final List<String> modelosParaTeste = _geminiModelsAlternatives;
      bool chaveValida = false;
      String mensagemErro = '';

      for (String modelo in modelosParaTeste) {
        try {
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

          AppLogger.i('GeminiService', 'Testando API Gemini com modelo: $modelo');
          final response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: testBody,
          );

          if (response.statusCode == 200) {
            chaveValida = true;
            _geminiModel = modelo; // Usar o modelo que funcionou
            AppLogger.i('GeminiService', 'Chave API Gemini válida para modelo: $modelo');
            break;
          } else {
            mensagemErro = 'Erro ao validar chave API Gemini com modelo $modelo: ${response.statusCode} ${response.body}';
            AppLogger.w('GeminiService', mensagemErro);
          }
        } catch (e) {
          mensagemErro = 'Erro ao testar chave API Gemini com modelo $modelo: $e';
          AppLogger.e('GeminiService', mensagemErro, e);
        }
      }

      if (chaveValida) {
        // Salvar a chave API
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('gemini_api_key', apiKey);
        apiKey_ = apiKey;
        notifyListeners();

        return {
          'success': true,
          'message': 'Chave API Gemini configurada com sucesso para o modelo $_geminiModel'
        };
      } else {
        return {
          'success': false,
          'message': 'Chave API Gemini inválida. $mensagemErro'
        };
      }
    } catch (e) {
      AppLogger.e('GeminiService', 'Erro ao configurar chave API Gemini', e);
      return {
        'success': false,
        'message': 'Erro ao configurar chave API Gemini: $e'
      };
    }
  }

  @override
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
        AppLogger.e('GeminiService', 'Erro específico da API Gemini', e);
        // Verificar se é um erro de modelo não encontrado
        if (e.toString().contains('models/gemini-2.0-flash is not found') ||
            e.toString().contains('not found')) {
          throw Exception('O modelo Gemini não está disponível. Verifique se sua API key tem acesso a este modelo.');
        }
        rethrow;
      }
    } catch (e) {
      AppLogger.e('GeminiService', 'Erro ao chamar API', e);
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

  // Método para processar PDF
  Future<String> processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    return await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  // Implementação do método _processarPdf da classe base
  // ignore: unused_element
  Future<String> _processarPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    // Este método é chamado pelos métodos da classe base BaseIAService
    return await processarPdf(prompt, pdfBytes, pdfName: pdfName);
  }

  Future<String> callGeminiApiWithPdf(String prompt, Uint8List pdfBytes, {String? pdfName}) async {
    // Inicializar o cache se ainda não foi inicializado
    await initCache();

    // Verificar se existe cache para este PDF e prompt
    final cachedResult = await _cacheService.getFromCache(prompt, pdfBytes.toList());
    if (cachedResult != null) {
      AppLogger.i('GeminiService', 'Usando resultado do cache para análise do PDF');
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
      throw Exception('O modelo $_geminiModel não suporta processamento de PDF. Use um modelo compatível.');
    }

    try {
      // Codificar o PDF em base64
      final String pdfBase64 = base64Encode(pdfBytes);
      final String pdfMimeType = 'application/pdf';

      final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=${super.apiKey}';

      // Parâmetros de retry
      final int maxRetries = 5; // Aumentado para 5 tentativas
      final int initialDelayMs = 1000; // 1 segundo
      int currentRetry = 0;
      int delayMs = initialDelayMs;

      // Configurar parâmetros específicos para extração de dados de edital
      double temperature = 0.0; // Temperatura baixa para extração de dados
      int maxTokens = 64000; // Tokens máximos para o Gemini 2.5 Pro

      AppLogger.i('GeminiService', 'Configurando chamada para Gemini com PDF: temperature=$temperature, maxTokens=$maxTokens');

      // Construir o corpo da requisição
      final Map<String, dynamic> requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              },
              {
                'inlineData': {
                  'mimeType': pdfMimeType,
                  'data': pdfBase64
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': temperature,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': maxTokens,
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

      final body = jsonEncode(requestBody);

      // Loop de retry
      while (true) {
        try {
          AppLogger.i('GeminiService', 'Enviando PDF para a API Gemini (tentativa ${currentRetry + 1} de $maxRetries)...');
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
            },
            body: body,
          );

          if (response.statusCode == 200) {
            AppLogger.i('GeminiService', 'Resposta recebida com sucesso do Gemini. Analisando JSON...');
            final jsonResponse = jsonDecode(response.body);

            // Extrair o texto da resposta
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

            // Salvar no cache para uso futuro
            await _cacheService.saveToCache(prompt, pdfBytes.toList(), text);
            AppLogger.i('GeminiService', 'Resposta salva no cache para uso futuro');

            return text;
          } else {
            AppLogger.e('GeminiService', 'Erro na API Gemini: ${response.statusCode} ${response.body}');

            // Verificar se é um erro de sobrecarga (503) e se ainda podemos tentar novamente
            if (response.statusCode == 503 && currentRetry < maxRetries - 1) {
              currentRetry++;
              // Aumentar o tempo de espera exponencialmente (backoff exponencial)
              delayMs *= 2;
              AppLogger.w('GeminiService', 'Modelo sobrecarregado. Tentando novamente em ${delayMs}ms...');
              await Future.delayed(Duration(milliseconds: delayMs));
              continue; // Tentar novamente
            }

            // Se não for um erro de sobrecarga ou já tentamos o máximo de vezes, lançar exceção
            throw Exception('Falha na chamada da API Gemini: ${response.statusCode} ${response.body}');
          }
        } catch (e) {
          AppLogger.e('GeminiService', 'Exceção ao chamar API Gemini', e);

          // Verificar se ainda podemos tentar novamente
          if (currentRetry < maxRetries - 1 && !e.toString().contains('Chave API inválida') && !e.toString().contains('quota')) {
            currentRetry++;
            // Aumentar o tempo de espera exponencialmente (backoff exponencial)
            delayMs *= 2;
            AppLogger.w('GeminiService', 'Erro ao conectar. Tentando novamente em ${delayMs}ms...');
            await Future.delayed(Duration(milliseconds: delayMs));
            continue; // Tentar novamente
          }

          // Se já tentamos o máximo de vezes, lançar exceção
          throw Exception('Não foi possível carregar o prompt: $e');
        }
      }
    } catch (e) {
      AppLogger.e('GeminiService', 'Erro ao processar PDF ou chamar API', e);
      throw Exception('Não foi possível carregar o prompt: $e');
    }
  }

  // Método para chamar a API do Gemini com retry
  Future<String> _callGeminiApi(String prompt) async {
    // Inicializar o cache se ainda não foi inicializado
    await super.initCache();

    // Verificar se existe cache para este prompt
    if (super.forceCacheMode || !isConfigured) {
      // Criar um hash do prompt para usar como chave de cache
      final promptBytes = utf8.encode(prompt);
      final cachedResult = await _cacheService.getFromCache(prompt, promptBytes);
      if (cachedResult != null) {
        AppLogger.i('GeminiService', 'Usando resultado do cache para prompt');
        return cachedResult;
      }
    }

    if (!isConfigured) {
      throw Exception('API Key não configurada');
    }

    // Verificar se o modelo atual é válido
    bool modeloValido = false;
    String ultimoErro = '';

    // Tentar com o modelo atual primeiro
    try {
      final testUrl = '$_geminiBaseUrl/$_geminiModel:generateContent?key=${super.apiKey}';
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

      AppLogger.i('GeminiService', 'Testando modelo atual: $_geminiModel');
      final testResponse = await http.post(
        Uri.parse(testUrl),
        headers: {'Content-Type': 'application/json'},
        body: testBody,
      );

      if (testResponse.statusCode == 200) {
        modeloValido = true;
        AppLogger.i('GeminiService', 'Modelo atual $_geminiModel é válido');
      } else {
        ultimoErro = 'Erro com modelo $_geminiModel: ${testResponse.statusCode} ${testResponse.body}';
        AppLogger.w('GeminiService', ultimoErro);

        // Se o modelo atual não funcionar, tentar com os modelos alternativos
        for (String modelo in _geminiModelsAlternatives) {
          if (modelo == _geminiModel) continue; // Pular o modelo atual que já testamos

          try {
            final altUrl = '$_geminiBaseUrl/$modelo:generateContent?key=${super.apiKey}';
            final altResponse = await http.post(
              Uri.parse(altUrl),
              headers: {'Content-Type': 'application/json'},
              body: testBody,
            );

            if (altResponse.statusCode == 200) {
              modeloValido = true;
              _geminiModel = modelo; // Atualizar o modelo para o que funcionou
              AppLogger.i('GeminiService', 'Modelo alternativo $modelo é válido. Usando-o para esta chamada.');
              break;
            } else {
              ultimoErro = 'Erro com modelo $modelo: ${altResponse.statusCode} ${altResponse.body}';
              AppLogger.w('GeminiService', ultimoErro);
            }
          } catch (e) {
            ultimoErro = 'Erro ao testar modelo $modelo: $e';
            AppLogger.e('GeminiService', ultimoErro, e);
          }
        }
      }
    } catch (e) {
      ultimoErro = 'Erro ao testar modelo $_geminiModel: $e';
      AppLogger.e('GeminiService', ultimoErro, e);
    }

    if (!modeloValido) {
      throw Exception('Não foi possível encontrar um modelo Gemini válido. $ultimoErro');
    }

    final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=${super.apiKey}';

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

    // Detectar se é uma geração de mapa mental
    bool isMindmapGeneration = prompt.contains('mapa mental') ||
                             prompt.contains('markmap') ||
                             prompt.contains('esquema');

    // Detectar se é uma geração de flashcards
    bool isFlashcardGeneration = prompt.contains('flashcard') ||
                               prompt.contains('cartão de memória');

    // Detectar se é uma geração de questões
    bool isQuestionGeneration = prompt.contains('questões') ||
                              prompt.contains('perguntas') ||
                              prompt.contains('exercícios');

    // Configurar parâmetros com base no tipo de tarefa
    double temperature = 0.7; // Temperatura padrão
    int maxOutputTokens = 64000; // Tokens máximos para o Gemini 2.5 Pro
    String? responseMimeType;

    if (isEditalExtraction) {
      temperature = 0.0; // Temperatura baixa para extração de dados
      if (isJsonExtraction) {
        responseMimeType = 'application/json';
      } else if (isYamlExtraction) {
        responseMimeType = 'application/yaml';
      }
    } else if (isMindmapGeneration) {
      temperature = 0.3; // Temperatura média-baixa para mapas mentais
    } else if (isFlashcardGeneration || isQuestionGeneration) {
      temperature = 0.5; // Temperatura média para flashcards e questões
    }

    AppLogger.i('GeminiService', 'Parâmetros: temperature=$temperature, maxOutputTokens=$maxOutputTokens, responseMimeType=$responseMimeType');

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

    final body = jsonEncode(requestBody);

    // Loop de retry
    while (true) {
      try {
        AppLogger.i('GeminiService', 'Enviando requisição para a API Gemini (tentativa ${currentRetry + 1} de $maxRetries)...');
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);

          // Extrair o texto da resposta
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

          // Salvar no cache para uso futuro
          final promptBytes = utf8.encode(prompt);
          await _cacheService.saveToCache(prompt, promptBytes, text);
          AppLogger.i('GeminiService', 'Resposta salva no cache para uso futuro');

          return text;
        } else {
          AppLogger.e('GeminiService', 'Erro na API Gemini: ${response.statusCode} ${response.body}');

          // Verificar se é um erro de sobrecarga (503) e se ainda podemos tentar novamente
          if (response.statusCode == 503 && currentRetry < maxRetries - 1) {
            currentRetry++;
            // Aumentar o tempo de espera exponencialmente (backoff exponencial)
            delayMs *= 2;
            AppLogger.w('GeminiService', 'Modelo sobrecarregado. Tentando novamente em ${delayMs}ms...');
            await Future.delayed(Duration(milliseconds: delayMs));
            continue; // Tentar novamente
          }

          // Se não for um erro de sobrecarga ou já tentamos o máximo de vezes, lançar exceção
          throw Exception('Falha na chamada da API Gemini: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        AppLogger.e('GeminiService', 'Erro ao chamar API Gemini', e);

        // Verificar se ainda podemos tentar novamente
        if (currentRetry < maxRetries - 1) {
          currentRetry++;
          // Aumentar o tempo de espera exponencialmente (backoff exponencial)
          delayMs *= 2;
          AppLogger.w('GeminiService', 'Erro ao conectar. Tentando novamente em ${delayMs}ms...');
          await Future.delayed(Duration(milliseconds: delayMs));
          continue; // Tentar novamente
        }

        // Se já tentamos o máximo de vezes, lançar exceção
        throw Exception('Falha na chamada da API Gemini: $e');
      }
    }
  }

  @override
  bool isWithinTokenLimit(String texto) {
    // Estimativa aproximada: 1 token = 4 caracteres em média
    final int estimatedTokens = texto.length ~/ 4;

    // Limite de tokens para o modelo Gemini 2.5 Pro
    final int tokenLimit = 1000000; // 1 milhão de tokens

    return estimatedTokens < tokenLimit;
  }
}
