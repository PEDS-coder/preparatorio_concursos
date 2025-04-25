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
  final String _geminiModel = 'gemini-2.5-pro-exp-03-25';
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
  Future<String> extrairConcursoConteudo({required Uint8List pdfBytes, required String cargoAlvo, String? pdfName}) async {
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
      final resposta = await callGeminiApiWithPdf(prompt, pdfBytes, pdfName: pdfName);

      // Log para depuração
      print('[GeminiOfficialService] Resposta recebida com tamanho: ${resposta.length} caracteres');
      print('[GeminiOfficialService] Início da resposta: ${resposta.substring(0, resposta.length > 100 ? 100 : resposta.length)}');

      // Verificar se a resposta é um JSON válido
      try {
        final json = jsonDecode(resposta);
        print('[GeminiOfficialService] Resposta é um JSON válido com ${json.keys.length} chaves: ${json.keys.join(', ')}');
      } catch (e) {
        print('[GeminiOfficialService] Resposta não é um JSON válido: $e');
      }

      return resposta;
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
      print('[GeminiOfficialService] Enviando PDF para análise: $fileName (${pdfBytes.length} bytes)');

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
          print('[GeminiOfficialService] Estrutura de resposta inesperada: $jsonResponse');

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
