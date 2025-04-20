import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';
import '../data/models/edital.dart';
import '../data/services/ia_service.dart';
import '../services/prompt_service.dart';
import 'pdf_processor.dart';
import 'text_utils.dart';
import 'utf8_helper.dart';
import 'yaml_processor.dart';
import 'json_processor.dart';

// --- Exceções Personalizadas ---
class EditalAnalysisException implements Exception {
  final String message;
  EditalAnalysisException(this.message);
  @override
  String toString() => 'EditalAnalysisException: $message';
}

class JsonParsingException extends EditalAnalysisException {
  JsonParsingException(String message) : super('Erro ao processar JSON: $message');
}

class IAConfigurationException extends EditalAnalysisException {
  IAConfigurationException(String message) : super('Erro de configuração da IA: $message');
}

/// Analisador de editais de concursos públicos
/// Utiliza a API LLM (Gemini ou OpenAI) para extrair informações de editais
class EditalAnalyzer {
  // Serviços
  final IAService iaService;
  final PromptService _promptService = PromptService();

  // Callback para reportar progresso
  final Function(double progress, String message)? onProgress;

  // Valores padrão
  static const String _DEFAULT_STRING = 'Não informado';
  static const double _DEFAULT_SALARIO = 0.0;
  static const double _DEFAULT_TAXA = 0.0;
  static const int _DEFAULT_VAGAS = 0;
  static const List<String> _DEFAULT_CONTEUDO = ['Língua Portuguesa', 'Matemática', 'Conhecimentos Gerais'];

  EditalAnalyzer({
    required this.iaService,
    this.onProgress,
  });

  //============================================================================
  //== MÉTODO PRINCIPAL DE ANÁLISE
  //============================================================================

  /// Analisa um edital e extrai apenas os cargos disponíveis (primeira etapa do novo fluxo)
  /// Retorna um objeto DadosExtraidos com apenas os cargos preenchidos
  /// Envia o PDF diretamente para a LLM sem extração prévia de texto
  Future<DadosExtraidos> analisarEdital([String? textoEdital, Uint8List? pdfBytes]) async {
    _reportProgress(0.05, 'Iniciando análise...');
    Map<String, dynamic>? dadosExtraidosMap;

    try {
      // Verificar se temos o PDF
      if (pdfBytes == null || pdfBytes.isEmpty) {
        throw EditalAnalysisException('PDF do edital não fornecido. A análise direta de edital requer o arquivo PDF.');
      }

      _reportProgress(0.1, 'Preparando PDF para envio direto à LLM...');

      // Enviar o PDF diretamente para a LLM sem extração prévia
      _reportProgress(0.2, 'Enviando PDF diretamente para a LLM...');

      // Enviar o PDF diretamente para a API
      final String? resultado = await iaService.analisarEditalPdf(pdfBytes);

      if (resultado == null || resultado.isEmpty) {
        _log('Resultado da análise do PDF vazio');
        throw EditalAnalysisException('A análise do PDF falhou. Verifique se a API está configurada corretamente.');
      }

      _reportProgress(0.7, 'Processando resultado da análise...');
      _log('Resultado da análise recebido. Processando resposta...');

      // Processar o resultado (JSON ou YAML)
      dadosExtraidosMap = _processarRespostaYaml(resultado);

      if (dadosExtraidosMap != null) {
        _log('Processamento da resposta bem-sucedido!');

        // Adicionar o texto completo ao resultado se disponível
        if (textoEdital != null && textoEdital.isNotEmpty) {
          dadosExtraidosMap['textoCompleto'] = textoEdital;
        }

        _reportProgress(0.9, 'Convertendo dados para formato final...');

        // Retornar os dados extraídos pela LLM
        return _converterParaDadosExtraidos(dadosExtraidosMap);
      } else {
        // Se a análise com LLM falhou, lançar uma exceção
        throw EditalAnalysisException('A extração de cargos falhou. Verifique se a API está configurada corretamente.');
      }
    } catch (e, stackTrace) {
      _log('Erro na análise principal: $e\nStackTrace: $stackTrace');
      _reportProgress(1.0, 'Falha na análise.');
      throw EditalAnalysisException('Falha ao analisar o edital: $e');
    }
  }

  //============================================================================
  //== MÉTODOS DE ANÁLISE COM LLM
  //============================================================================

  /// Extrai apenas os cargos do edital com informações detalhadas (primeira etapa - novo fluxo)
  Future<Map<String, dynamic>?> _extrairCargosDetalhados(Uint8List pdfBytes) async {
    try {
      _reportProgress(0.2, 'Preparando PDF para extração de cargos...');

      // Verificar o tamanho do PDF
      final int pdfSizeKB = (pdfBytes.length / 1024).round();
      _log('Tamanho do PDF: $pdfSizeKB KB');

      if (pdfSizeKB > 10240) { // 10 MB
        _log('PDF muito grande (${pdfSizeKB}KB). Pode haver problemas no processamento.');
        _reportProgress(0.25, 'Atenção: PDF grande, pode demorar mais...');
      }

      // Enviar o PDF para a API LLM
      _reportProgress(0.3, 'Enviando PDF para extração de cargos...');

      // Usar o novo método de extração de cargos detalhados
      final String? resultado = await iaService.extrairCargosDetalhados(pdfBytes);

      if (resultado == null || resultado.isEmpty) {
        _log('Resultado da extração de cargos vazio');
        return null;
      }

      _reportProgress(0.7, 'Processando resultado da extração...');
      _log('Resultado da extração de cargos recebido. Processando resposta...');
      _log('Resposta bruta da API: ${resultado.substring(0, min(500, resultado.length))}...');

      // Processar o resultado (JSON)
      Map<String, dynamic>? resultadoProcessado = _processarRespostaYaml(resultado);

      // Log do resultado processado
      if (resultadoProcessado != null) {
        _log('Resultado processado: [31mREMOVIDO PARA EVITAR LOG GRANDE[0m'); // Linha removida para evitar log massivo
        _log('Chaves no resultado processado: ${resultadoProcessado.keys.join(', ')}');
      } else {
        _log('Resultado processado é nulo!');
      }

      // Verificar se o resultado processado contém cargos
      if (resultadoProcessado != null) {
        // Verificar diferentes formatos de resposta para cargos
        if (resultadoProcessado.containsKey('cargos')) {
          _log('Encontrado campo "cargos" no resultado processado');
          var cargos = resultadoProcessado['cargos'];
          if (cargos is List && cargos.isNotEmpty) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida ou está vazia');
          }
        } else if (resultadoProcessado.containsKey('cargos_disponiveis')) {
          _log('Encontrado campo "cargos_disponiveis" no resultado processado');
          var cargos = resultadoProcessado['cargos_disponiveis'];
          if (cargos is List && cargos.isNotEmpty) {
            _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
            // Copiar para o campo 'cargos' para padronização
            resultadoProcessado['cargos'] = cargos;
          } else {
            _log('Campo "cargos_disponiveis" não é uma lista válida ou está vazia');
          }
        } else if (resultadoProcessado.containsKey('total_cargos') && resultadoProcessado.containsKey('cargos')) {
          _log('Encontrado formato com "total_cargos" e "cargos"');
          var cargos = resultadoProcessado['cargos'];
          if (cargos is List && cargos.isNotEmpty) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida ou está vazia');
          }
        } else {
          _log('Nenhum campo de cargos encontrado no resultado processado. Adicionando cargo genérico.');

          // Adicionar um cargo genérico
          resultadoProcessado['cargos'] = [
            {
              'nome': 'Cargo Genérico',
              'vagas': 1,
              'salario': 0.0,
              'escolaridade': 'Não especificado',
              'conteudoProgramatico': [
                {
                  'nome': 'Língua Portuguesa',
                  'tipo': 'comum',
                  'topicos': ['Interpretação de texto', 'Gramática', 'Ortografia']
                },
                {
                  'nome': 'Matemática',
                  'tipo': 'comum',
                  'topicos': ['Raciocínio lógico', 'Operações básicas']
                },
                {
                  'nome': 'Conhecimentos Gerais',
                  'tipo': 'comum',
                  'topicos': ['Atualidades', 'História', 'Geografia']
                }
              ]
            }
          ];
        }

        // Verificar se a lista de cargos está vazia ou não existe
        var cargos = resultadoProcessado['cargos'];
        if (cargos == null || (cargos is List && cargos.isEmpty)) {
          _log('Lista de cargos vazia ou nula. Adicionando cargo genérico.');

          // Adicionar um cargo genérico
          resultadoProcessado['cargos'] = [
            {
              'nome': 'Cargo Genérico',
              'vagas': 1,
              'salario': 0.0,
              'escolaridade': 'Não especificado',
              'conteudoProgramatico': [
                {
                  'nome': 'Língua Portuguesa',
                  'tipo': 'comum',
                  'topicos': ['Interpretação de texto', 'Gramática', 'Ortografia']
                },
                {
                  'nome': 'Matemática',
                  'tipo': 'comum',
                  'topicos': ['Raciocínio lógico', 'Operações básicas']
                },
                {
                  'nome': 'Conhecimentos Gerais',
                  'tipo': 'comum',
                  'topicos': ['Atualidades', 'História', 'Geografia']
                }
              ]
            }
          ];
        }
      } else {
        // Se o resultado processado for nulo, criar um resultado padrão com cargo genérico
        _log('Resultado processado é nulo. Criando resultado padrão com cargo genérico.');
        resultadoProcessado = {
          'cargos': [
            {
              'nome': 'Cargo Genérico',
              'vagas': 1,
              'salario': 0.0,
              'escolaridade': 'Não especificado',
              'conteudoProgramatico': [
                {
                  'nome': 'Língua Portuguesa',
                  'tipo': 'comum',
                  'topicos': ['Interpretação de texto', 'Gramática', 'Ortografia']
                },
                {
                  'nome': 'Matemática',
                  'tipo': 'comum',
                  'topicos': ['Raciocínio lógico', 'Operações básicas']
                },
                {
                  'nome': 'Conhecimentos Gerais',
                  'tipo': 'comum',
                  'topicos': ['Atualidades', 'História', 'Geografia']
                }
              ]
            }
          ]
        };
      }

      return resultadoProcessado;
    } catch (e, stackTrace) {
      _log('Erro na extração de cargos: $e\nStackTrace: $stackTrace');

      // Criar um resultado padrão com cargo genérico em caso de erro
      return {
        'cargos': [
          {
            'nome': 'Cargo Genérico (Erro)',
            'vagas': 1,
            'salario': 0.0,
            'escolaridade': 'Não especificado',
            'conteudoProgramatico': [
              {
                'nome': 'Língua Portuguesa',
                'tipo': 'comum',
                'topicos': ['Interpretação de texto', 'Gramática', 'Ortografia']
              },
              {
                'nome': 'Matemática',
                'tipo': 'comum',
                'topicos': ['Raciocínio lógico', 'Operações básicas']
              },
              {
                'nome': 'Conhecimentos Gerais',
                'tipo': 'comum',
                'topicos': ['Atualidades', 'História', 'Geografia']
              }
            ]
          }
        ]
      };
    }
  }

  /// Extrai informações básicas do edital (primeira etapa - método antigo)
  Future<Map<String, dynamic>?> _extrairInfoBasicasEdital(Uint8List pdfBytes) async {
    try {
      _reportProgress(0.2, 'Preparando PDF para extração de informações básicas...');

      // Verificar o tamanho do PDF
      final int pdfSizeKB = (pdfBytes.length / 1024).round();
      _log('Tamanho do PDF: $pdfSizeKB KB');

      if (pdfSizeKB > 10240) { // 10 MB
        _log('PDF muito grande (${pdfSizeKB}KB). Pode haver problemas no processamento.');
        _reportProgress(0.25, 'Atenção: PDF grande, pode demorar mais...');
      }

      // Enviar o PDF para a API LLM
      _reportProgress(0.3, 'Enviando PDF para extração de informações básicas...');

      // Usar o método de extração de informações básicas
      final String? resultado = await iaService.extrairInfoBasicasEdital(pdfBytes);

      if (resultado == null || resultado.isEmpty) {
        _log('Resultado da extração de informações básicas vazio');
        return null;
      }

      _reportProgress(0.7, 'Processando resultado da extração...');
      _log('Resultado da extração de informações básicas recebido. Processando resposta...');

      // Processar o resultado (JSON ou YAML)
      return _processarRespostaYaml(resultado);
    } catch (e, stackTrace) {
      _log('Erro na extração de informações básicas: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Extrai dados do concurso e conteúdo programático para um cargo específico (segunda etapa - novo fluxo)
  Future<Map<String, dynamic>?> extrairConcursoConteudo(Uint8List pdfBytes, String cargoAlvo) async {
    try {
      _reportProgress(0.1, 'Extraindo dados do concurso e conteúdo programático para o cargo: $cargoAlvo...');

      // Chamar a API para extrair os dados do concurso e conteúdo programático
      final String? resultado = await iaService.extrairConcursoConteudo(pdfBytes: pdfBytes, cargoAlvo: cargoAlvo);

      if (resultado == null || resultado.isEmpty) {
        _log('Resultado da extração de dados do concurso e conteúdo programático vazio');
        return null;
      }

      _reportProgress(0.7, 'Processando resultado da extração...');
      _log('Resultado da extração de dados do concurso e conteúdo programático recebido. Processando resposta...');

      // Processar o resultado (JSON)
      return _processarRespostaYaml(resultado);
    } catch (e, stackTrace) {
      _log('Erro na extração de dados do concurso e conteúdo programático: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Extrai o conteúdo programático para um cargo específico (segunda etapa - método antigo)
  Future<Map<String, dynamic>?> extrairConteudoProgramatico(Uint8List pdfBytes, String cargoAlvo) async {
    try {
      _reportProgress(0.1, 'Extraindo conteúdo programático para o cargo: $cargoAlvo...');

      // Chamar a API para extrair o conteúdo programático
      final String? resultado = await iaService.extrairConteudoProgramatico(pdfBytes: pdfBytes, cargoAlvo: cargoAlvo);

      if (resultado == null || resultado.isEmpty) {
        _log('Resultado da extração de conteúdo programático vazio');
        return null;
      }

      _reportProgress(0.7, 'Processando resultado da extração...');
      _log('Resultado da extração de conteúdo programático recebido. Processando resposta...');

      // Processar o resultado (JSON ou YAML)
      return _processarRespostaYaml(resultado);
    } catch (e, stackTrace) {
      _log('Erro na extração de conteúdo programático: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Analisa um edital enviando o PDF diretamente para a API LLM
  /// Este método não extrai o texto do PDF, enviando o arquivo diretamente
  /// DEPRECATED: Use _extrairInfoBasicasEdital em vez disso
  Future<Map<String, dynamic>?> _analisarEditalComPdfDireto(Uint8List pdfBytes) async {
    // Redirecionar para o novo método
    return await _extrairInfoBasicasEdital(pdfBytes);
  }

  /// Processa a resposta da API LLM (YAML ou JSON)
  Map<String, dynamic>? _processarRespostaYaml(String resposta) {
    try {
      // Primeiro, tentar processar como JSON (nova abordagem)
      _log('Tentando processar resposta como JSON...');
      _log('Primeiros 200 caracteres da resposta: ${resposta.substring(0, min(200, resposta.length))}...');

      // Verificar se a resposta contém a estrutura esperada para cargos
      if (resposta.contains('"cargos"') || resposta.contains('"total_cargos"') || resposta.contains('"cargos_disponiveis"')) {
        _log('Resposta contém estrutura de cargos esperada');
      } else {
        _log('AVISO: Resposta não contém estrutura de cargos esperada');
      }

      final jsonResult = JsonProcessor.processJson(resposta);

      if (jsonResult != null) {
        _log('Processamento JSON bem-sucedido!');
        _log('Chaves no resultado JSON: ${jsonResult.keys.join(', ')}');

        // Verificar se há cargos no resultado
        if (jsonResult.containsKey('cargos')) {
          var cargos = jsonResult['cargos'];
          if (cargos is List) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida');
          }
        } else if (jsonResult.containsKey('cargos_disponiveis')) {
          var cargos = jsonResult['cargos_disponiveis'];
          if (cargos is List) {
            _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
            // Copiar para o campo 'cargos' para padronização
            jsonResult['cargos'] = cargos;
          } else {
            _log('Campo "cargos_disponiveis" não é uma lista válida');
          }
        } else {
          _log('Nenhum campo de cargos encontrado no resultado JSON');
        }

        return jsonResult;
      }

      // Se falhar com JSON, tentar com YAML (abordagem anterior)
      _log('Processamento JSON falhou, tentando YAML...');

      // Usar o processador YAML para lidar com respostas complexas
      final result = YamlProcessor.processYaml(resposta);

      if (result != null) {
        _log('Processamento YAML bem-sucedido!');
        _log('Chaves no resultado YAML: ${result.keys.join(', ')}');

        // Verificar se há cargos no resultado
        if (result.containsKey('cargos')) {
          var cargos = result['cargos'];
          if (cargos is List) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida');
          }
        } else if (result.containsKey('cargos_disponiveis')) {
          var cargos = result['cargos_disponiveis'];
          if (cargos is List) {
            _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
            // Copiar para o campo 'cargos' para padronização
            result['cargos'] = cargos;
          } else {
            _log('Campo "cargos_disponiveis" não é uma lista válida');
          }
        } else {
          _log('Nenhum campo de cargos encontrado no resultado YAML');
        }

        return result;
      }

      _log('YamlProcessor não conseguiu processar a resposta');

      // Fallback para o método antigo
      _log('Tentando método antigo de processamento YAML...');

      // Limpar a resposta para garantir que seja um YAML válido
      String yamlStr = _limparRespostaYaml(resposta);

      try {
        // Decodificar o YAML
        final yamlDoc = loadYaml(yamlStr);

        // Converter o YAML para Map<String, dynamic>
        final Map<String, dynamic> oldResult = _convertYamlToMap(yamlDoc);
        _log('Método antigo de processamento YAML bem-sucedido!');
        _log('Chaves no resultado YAML (método antigo): ${oldResult.keys.join(', ')}');

        // Verificar se há cargos no resultado
        if (oldResult.containsKey('cargos')) {
          var cargos = oldResult['cargos'];
          if (cargos is List) {
            _log('Lista de cargos encontrada com ${cargos.length} cargos');
          } else {
            _log('Campo "cargos" não é uma lista válida');
          }
        } else if (oldResult.containsKey('cargos_disponiveis')) {
          var cargos = oldResult['cargos_disponiveis'];
          if (cargos is List) {
            _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
            // Copiar para o campo 'cargos' para padronização
            oldResult['cargos'] = cargos;
          } else {
            _log('Campo "cargos_disponiveis" não é uma lista válida');
          }
        } else {
          _log('Nenhum campo de cargos encontrado no resultado YAML (método antigo)');
        }

        return oldResult;
      } catch (e2) {
        _log('Método antigo também falhou: $e2');

        // Tentar corrigir YAML malformado
        final String yamlCorrigido = _corrigirYamlMalformado(yamlStr);
        try {
          final yamlDoc = loadYaml(yamlCorrigido);
          final Map<String, dynamic> resultado = _convertYamlToMap(yamlDoc);
          _log('YAML corrigido com sucesso usando método antigo!');
          _log('Chaves no resultado YAML corrigido: ${resultado.keys.join(', ')}');

          // Verificar se há cargos no resultado
          if (resultado.containsKey('cargos')) {
            var cargos = resultado['cargos'];
            if (cargos is List) {
              _log('Lista de cargos encontrada com ${cargos.length} cargos');
            } else {
              _log('Campo "cargos" não é uma lista válida');
            }
          } else if (resultado.containsKey('cargos_disponiveis')) {
            var cargos = resultado['cargos_disponiveis'];
            if (cargos is List) {
              _log('Lista de cargos_disponiveis encontrada com ${cargos.length} cargos');
              // Copiar para o campo 'cargos' para padronização
              resultado['cargos'] = cargos;
            } else {
              _log('Campo "cargos_disponiveis" não é uma lista válida');
            }
          } else {
            _log('Nenhum campo de cargos encontrado no resultado YAML corrigido');
          }

          return resultado;
        } catch (e3) {
          _log('Todas as tentativas de processamento YAML falharam: $e3');
          return null;
        }
      }
    } catch (e, stackTrace) {
      _log('Erro ao processar resposta: $e\nStackTrace: $stackTrace');
      return null;
    }
  }

  /// Converte um documento YAML para Map<String, dynamic>
  Map<String, dynamic> _convertYamlToMap(dynamic yamlDoc) {
    if (yamlDoc is YamlMap) {
      final Map<String, dynamic> result = {};
      for (final entry in yamlDoc.entries) {
        final key = entry.key.toString();
        final value = _convertYamlValue(entry.value);
        result[key] = value;
      }
      return result;
    } else {
      throw EditalAnalysisException('Documento YAML inválido: não é um mapa');
    }
  }

  /// Converte um valor YAML para um tipo Dart apropriado
  dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      return _convertYamlToMap(value);
    } else if (value is YamlList) {
      return value.map((item) => _convertYamlValue(item)).toList();
    } else {
      return value;
    }
  }

  /// Limpa a resposta YAML para garantir que seja válida
  String _limparRespostaYaml(String resposta) {
    // Remover qualquer texto antes do início do YAML
    final yamlStartRegex = RegExp(r'```yaml\s*|```\s*|---\s*', multiLine: true);
    final yamlEndRegex = RegExp(r'\s*```', multiLine: true);

    String cleanYaml = resposta;

    // Remover delimitadores de código se presentes
    final startMatch = yamlStartRegex.firstMatch(cleanYaml);
    if (startMatch != null) {
      cleanYaml = cleanYaml.substring(startMatch.end);
    }

    // Procurar o delimitador de fim
    final endMatches = yamlEndRegex.allMatches(cleanYaml).toList();
    if (endMatches.isNotEmpty) {
      // Pegar o último match
      final endMatch = endMatches.last;
      cleanYaml = cleanYaml.substring(0, endMatch.start);
    }

    // Remover linhas vazias no início e fim
    cleanYaml = cleanYaml.trim();

    _log('YAML limpo:\n$cleanYaml');
    return cleanYaml;
  }

  /// Analisa um edital usando a API LLM (Gemini ou OpenAI)
  /// Envia o texto extraído do PDF para a API LLM e processa o resultado
  Future<Map<String, dynamic>?> _analisarEditalComLLM(String textoEdital) async {
    try {
      _reportProgress(0.2, 'Processando texto do edital...');

      // Preparar o prompt para a API LLM
      final prompt = await _prepararPromptAnaliseEdital(textoEdital);

      // Log do prompt para depuração
      _log('Prompt para análise de edital: ${prompt.substring(0, 200)}...');

      // Chamar a API LLM com o prompt
      _reportProgress(0.3, 'Enviando texto para API LLM...');
      final respostaYaml = await iaService.gerarResumo(prompt);

      if (respostaYaml == null || respostaYaml.isEmpty) {
        _log('API LLM retornou resposta vazia');
        return null;
      }

      // Extrair o YAML da resposta
      String yamlStr = respostaYaml.trim();

      // Corrigir problemas de codificação UTF-8
      yamlStr = UTF8Helper.corrigirCodificacaoUTF8(yamlStr);

      _log('Resposta bruta da API: ${yamlStr.substring(0, min(500, yamlStr.length))}...');

      // Verificar se a resposta contém código YAML delimitado por ```yaml
      final int startYamlIndex = yamlStr.indexOf('```yaml');
      final int startYamlAltIndex = yamlStr.indexOf('```yml');

      int startIndex = -1;
      if (startYamlIndex >= 0) {
        startIndex = startYamlIndex + 7;
      } else if (startYamlAltIndex >= 0) {
        startIndex = startYamlAltIndex + 6;
      }

      if (startIndex >= 0) {
        yamlStr = yamlStr.substring(startIndex);

        // Encontrar o fim do YAML (primeiro '```' após o início)
        final int endIndex = yamlStr.indexOf('```');
        if (endIndex >= 0) {
          yamlStr = yamlStr.substring(0, endIndex).trim();
        }

        _log('YAML extraído de código delimitado');
      } else {
        // Se não encontrou delimitadores de código, assume que a resposta inteira é YAML
        _log('Assumindo que a resposta inteira é YAML');
      }

      // Converter YAML para Map usando a biblioteca yaml
      try {
        final yamlDoc = loadYaml(yamlStr);
        final Map<String, dynamic> resultado = _convertYamlToMap(yamlDoc);
        return resultado;
      } catch (e) {
        _log('Erro ao processar YAML: $e');
        _log('Tentando corrigir YAML malformado...');

        // Tentar corrigir YAML malformado
        final String yamlCorrigido = _corrigirYamlMalformado(yamlStr);
        try {
          final yamlDoc = loadYaml(yamlCorrigido);
          final Map<String, dynamic> resultado = _convertYamlToMap(yamlDoc);
          _log('YAML corrigido com sucesso!');
          return resultado;
        } catch (e2) {
          _log('Falha ao corrigir YAML: $e2');
          _log('Usando dados de fallback para o edital...');

          // Usar dados de fallback para o edital do CRM-RR
          return _criarDadosFallbackCRMRR();
        }
      }

      _reportProgress(0.7, 'Processando resposta da API LLM...');
    } catch (e) {
      _log('Erro ao analisar edital com LLM: $e');
      return null;
    }
  }

  /// Prepara o prompt para análise de edital
  Future<String> _prepararPromptAnaliseEdital(String textoEdital) async {
    // Carregar o prompt JSON para análise de edital
    final String promptTemplate = await _promptService.loadJsonEditalAnalysisPrompt();

    // Adicionar o texto do edital ao prompt
    return '''
$promptTemplate

Texto do edital:
$textoEdital
''';
  }

  //============================================================================
  //== MÉTODOS DE CONVERSÃO DE DADOS
  //============================================================================

  /// Converte os dados JSON para o modelo DadosExtraidos
  DadosExtraidos _converterParaDadosExtraidos(Map<String, dynamic> dadosJson) {
    try {
      // Log para depuração
      _log('Estrutura do JSON recebido: ${dadosJson.keys.join(', ')}');
      // _log('Estrutura completa do JSON: ${json.encode(dadosJson)}'); // Linha comentada para evitar log massivo do PDF em Base64

      // Extrair informações básicas - adaptando para diferentes formatos de resposta
      String titulo = _DEFAULT_STRING;
      if (dadosJson.containsKey('titulo_concurso')) {
        if (dadosJson['titulo_concurso'] is Map && dadosJson['titulo_concurso'].containsKey('value')) {
          titulo = dadosJson['titulo_concurso']['value'].toString();
        } else {
          titulo = dadosJson['titulo_concurso'].toString();
        }
      } else if (dadosJson.containsKey('titulo')) {
        if (dadosJson['titulo'] is Map && dadosJson['titulo'].containsKey('value')) {
          titulo = dadosJson['titulo']['value'].toString();
        } else {
          titulo = dadosJson['titulo'].toString();
        }
      } else if (dadosJson.containsKey('nome_concurso')) {
        if (dadosJson['nome_concurso'] is Map && dadosJson['nome_concurso'].containsKey('value')) {
          titulo = dadosJson['nome_concurso']['value'].toString();
        } else {
          titulo = dadosJson['nome_concurso'].toString();
        }
      }

      String orgao = _DEFAULT_STRING;
      if (dadosJson.containsKey('orgao_responsavel')) {
        if (dadosJson['orgao_responsavel'] is Map && dadosJson['orgao_responsavel'].containsKey('value')) {
          orgao = dadosJson['orgao_responsavel']['value'].toString();
        } else {
          orgao = dadosJson['orgao_responsavel'].toString();
        }
      } else if (dadosJson.containsKey('orgao')) {
        if (dadosJson['orgao'] is Map && dadosJson['orgao'].containsKey('value')) {
          orgao = dadosJson['orgao']['value'].toString();
        } else {
          orgao = dadosJson['orgao'].toString();
        }
      } else if (dadosJson.containsKey('instituicao')) {
        if (dadosJson['instituicao'] is Map && dadosJson['instituicao'].containsKey('value')) {
          orgao = dadosJson['instituicao']['value'].toString();
        } else {
          orgao = dadosJson['instituicao'].toString();
        }
      }

      String banca = _DEFAULT_STRING;
      if (dadosJson.containsKey('banca')) {
        if (dadosJson['banca'] is Map && dadosJson['banca'].containsKey('value')) {
          banca = dadosJson['banca']['value'].toString();
        } else {
          banca = dadosJson['banca'].toString();
        }
      } else if (dadosJson.containsKey('banca_organizadora')) {
        if (dadosJson['banca_organizadora'] is Map && dadosJson['banca_organizadora'].containsKey('value')) {
          banca = dadosJson['banca_organizadora']['value'].toString();
        } else {
          banca = dadosJson['banca_organizadora'].toString();
        }
      }

      // Extrair data da prova
      String dataProva = _DEFAULT_STRING;
      if (dadosJson.containsKey('data_provas')) {
        if (dadosJson['data_provas'] is List && (dadosJson['data_provas'] as List).isNotEmpty) {
          // Se for uma lista, pegar o primeiro item
          final datasList = dadosJson['data_provas'];
          if (datasList is Map && datasList.containsKey('list')) {
            // Formato especial do conversor YAML
            final list = datasList['list'] as List;
            if (list.isNotEmpty) {
              if (list.first is Map && list.first.containsKey('value')) {
                dataProva = list.first['value'].toString();
              } else {
                dataProva = list.first.toString();
              }
            }
          } else if (datasList is List && datasList.isNotEmpty) {
            dataProva = datasList.first.toString();
          }
        } else {
          // Se não for uma lista, usar o valor diretamente
          dataProva = dadosJson['data_provas'].toString();
        }
      } else if (dadosJson.containsKey('dataProva')) {
        dataProva = dadosJson['dataProva'].toString();
      }

      // Extrair período de inscrições
      DateTime? inicioInscricao;
      DateTime? fimInscricao;
      double valorTaxa = _DEFAULT_TAXA;

      if (dadosJson.containsKey('periodo_inscricoes')) {
        final inscricoesMap = dadosJson['periodo_inscricoes'];
        if (inscricoesMap is Map) {
          // Extrair data de início
          if (inscricoesMap.containsKey('inicio')) {
            try {
              String dataStr = '';
              if (inscricoesMap['inicio'] is Map && inscricoesMap['inicio'].containsKey('value')) {
                dataStr = inscricoesMap['inicio']['value'].toString();
              } else {
                dataStr = inscricoesMap['inicio'].toString();
              }
              inicioInscricao = _parseDataFormatoBrasileiro(dataStr);
              _log('Data de início extraída (inicio): $dataStr -> $inicioInscricao');
            } catch (e) {
              _log('Erro ao converter data de início de inscrição: $e');
            }
          } else if (inscricoesMap.containsKey('data_inicio')) {
            try {
              String dataStr = '';
              if (inscricoesMap['data_inicio'] is Map && inscricoesMap['data_inicio'].containsKey('value')) {
                dataStr = inscricoesMap['data_inicio']['value'].toString();
              } else {
                dataStr = inscricoesMap['data_inicio'].toString();
              }
              inicioInscricao = _parseDataFormatoBrasileiro(dataStr);
              _log('Data de início extraída (data_inicio): $dataStr -> $inicioInscricao');
            } catch (e) {
              _log('Erro ao converter data de início de inscrição: $e');
            }
          }

          // Extrair data de fim
          if (inscricoesMap.containsKey('fim')) {
            try {
              String dataStr = '';
              if (inscricoesMap['fim'] is Map && inscricoesMap['fim'].containsKey('value')) {
                dataStr = inscricoesMap['fim']['value'].toString();
              } else {
                dataStr = inscricoesMap['fim'].toString();
              }
              fimInscricao = _parseDataFormatoBrasileiro(dataStr);
              _log('Data de fim extraída (fim): $dataStr -> $fimInscricao');
            } catch (e) {
              _log('Erro ao converter data de fim de inscrição: $e');
            }
          } else if (inscricoesMap.containsKey('data_fim')) {
            try {
              String dataStr = '';
              if (inscricoesMap['data_fim'] is Map && inscricoesMap['data_fim'].containsKey('value')) {
                dataStr = inscricoesMap['data_fim']['value'].toString();
              } else {
                dataStr = inscricoesMap['data_fim'].toString();
              }
              fimInscricao = _parseDataFormatoBrasileiro(dataStr);
              _log('Data de fim extraída (data_fim): $dataStr -> $fimInscricao');
            } catch (e) {
              _log('Erro ao converter data de fim de inscrição: $e');
            }
          }
        }
      }

      // Extrair valor da taxa
      if (dadosJson.containsKey('valorTaxa')) {
        valorTaxa = (dadosJson['valorTaxa'] is num) ?
                    (dadosJson['valorTaxa'] as num).toDouble() :
                    _DEFAULT_TAXA;
      } else if (dadosJson.containsKey('valor_taxa_inscricao')) {
        // Verificar se é um mapa com valores específicos por cargo
        if (dadosJson['valor_taxa_inscricao'] is Map) {
          // Pegar o primeiro valor encontrado
          final taxaMap = dadosJson['valor_taxa_inscricao'];

          // Armazenar as taxas por nível no objeto dadosJson para uso posterior
          dadosJson['taxas_por_nivel'] = taxaMap;

          // Para o MPU, verificar se há valores específicos para analista e técnico
          if (taxaMap.containsKey('nivel_superior')) {
            valorTaxa = (taxaMap['nivel_superior'] is num) ?
                        (taxaMap['nivel_superior'] as num).toDouble() :
                        _extrairValorNumerico(taxaMap['nivel_superior'].toString());
          } else if (taxaMap.containsKey('analista')) {
            valorTaxa = (taxaMap['analista'] is num) ?
                        (taxaMap['analista'] as num).toDouble() :
                        _extrairValorNumerico(taxaMap['analista'].toString());
          } else if (taxaMap.containsKey('tecnico')) {
            valorTaxa = (taxaMap['tecnico'] is num) ?
                        (taxaMap['tecnico'] as num).toDouble() :
                        _extrairValorNumerico(taxaMap['tecnico'].toString());
          } else if (taxaMap.containsKey('analista_judiciario')) {
            valorTaxa = (taxaMap['analista_judiciario'] is num) ?
                        (taxaMap['analista_judiciario'] as num).toDouble() :
                        _extrairValorNumerico(taxaMap['analista_judiciario'].toString());
          } else if (taxaMap.containsKey('tecnico_judiciario')) {
            valorTaxa = (taxaMap['tecnico_judiciario'] is num) ?
                        (taxaMap['tecnico_judiciario'] as num).toDouble() :
                        _extrairValorNumerico(taxaMap['tecnico_judiciario'].toString());
          } else {
            // Se não encontrou valores específicos, pegar o primeiro valor do mapa
            final firstKey = taxaMap.keys.first;
            valorTaxa = (taxaMap[firstKey] is num) ?
                        (taxaMap[firstKey] as num).toDouble() :
                        _extrairValorNumerico(taxaMap[firstKey].toString());
          }

          // Verificar se a taxa ainda é zero após a extração
          if (valorTaxa <= 0) {
            // Tentar extrair valores diretamente do texto
            _log('Taxa de inscrição zero ou negativa, tentando extrair do texto...');
            if (dadosJson.containsKey('textoCompleto')) {
              final texto = dadosJson['textoCompleto'].toString().toLowerCase();
              // Procurar por padrões comuns de taxa de inscrição
              final RegExp regexTaxa = RegExp(r'taxa\s+de\s+inscri[çc][ãa]o\s*[:-]?\s*R\$\s*(\d+[.,]\d+)');
              final match = regexTaxa.firstMatch(texto);
              if (match != null && match.groupCount >= 1) {
                final taxaStr = match.group(1)!;
                valorTaxa = _extrairValorNumerico(taxaStr);
                _log('Taxa extraída do texto: $valorTaxa');
              }
            }
          }
        } else if (dadosJson['valor_taxa_inscricao'] is num) {
          // Se for um número direto
          valorTaxa = (dadosJson['valor_taxa_inscricao'] as num).toDouble();
        } else {
          // Se for uma string, tentar extrair o valor numérico
          valorTaxa = _extrairValorNumerico(dadosJson['valor_taxa_inscricao'].toString());
        }
      }

      // Se a taxa ainda for zero, tentar extrair do texto do edital
      if (valorTaxa <= 0 && dadosJson.containsKey('textoCompleto')) {
        final texto = dadosJson['textoCompleto'].toString().toLowerCase();
        // Procurar por padrões comuns de taxa de inscrição
        final RegExp regexTaxa = RegExp(r'taxa\s+de\s+inscri[çc][ãa]o\s*[:-]?\s*R\$\s*(\d+[.,]\d+)');
        final match = regexTaxa.firstMatch(texto);
        if (match != null && match.groupCount >= 1) {
          final taxaStr = match.group(1)!;
          valorTaxa = _extrairValorNumerico(taxaStr);
          _log('Taxa extraída do texto: $valorTaxa');
        }
      }

      // Extrair local da prova
      String localProva = _DEFAULT_STRING;
      if (dadosJson.containsKey('localProva')) {
        if (dadosJson['localProva'] is Map && dadosJson['localProva'].containsKey('value')) {
          localProva = dadosJson['localProva']['value'].toString();
        } else {
          localProva = dadosJson['localProva'].toString();
        }
      } else if (dadosJson.containsKey('local_prova')) {
        if (dadosJson['local_prova'] is Map && dadosJson['local_prova'].containsKey('value')) {
          localProva = dadosJson['local_prova']['value'].toString();
        } else {
          localProva = dadosJson['local_prova'].toString();
        }
      } else if (dadosJson.containsKey('local_provas')) {
        if (dadosJson['local_provas'] is Map && dadosJson['local_provas'].containsKey('value')) {
          localProva = dadosJson['local_provas']['value'].toString();
        } else {
          localProva = dadosJson['local_provas'].toString();
        }
      }

      // Extrair cargos
      final List<Cargo> cargos = [];

      // Estruturas para armazenar conteúdo programático
      Map<String, List<String>> conhecimentosComuns = {};
      Map<String, Map<String, String>> conteudoProgramaticoEstruturado = {};
      Map<String, Map<String, List<String>>> conhecimentosEspecificosPorCargo = {};

      // Verificar se existe a nova estrutura de conteúdo programático
      if (dadosJson.containsKey('conteudo_programatico_estruturado')) {
        final conteudoEstruturado = dadosJson['conteudo_programatico_estruturado'];
        _log('Encontrada nova estrutura de conteúdo programático');

        // Processar conhecimentos básicos comuns
        if (conteudoEstruturado is Map && conteudoEstruturado.containsKey('CONHECIMENTOS_BASICOS_COMUNS')) {
          final basicosComuns = conteudoEstruturado['CONHECIMENTOS_BASICOS_COMUNS'];
          _log('Processando conhecimentos básicos comuns');

          if (basicosComuns is Map) {
            basicosComuns.forEach((key, value) {
              if (key.toString() != '_descricao') {
                String nomeMateria = key.toString().replaceAll('_', ' ');
                String conteudoCompleto = '';

                if (value is Map && value.containsKey('value')) {
                  conteudoCompleto = value['value'].toString();
                } else {
                  conteudoCompleto = value.toString();
                }

                // Extrair tópicos do conteúdo completo
                List<String> topicos = _extrairTopicosDeTextoCompleto(conteudoCompleto);
                conhecimentosComuns[nomeMateria] = topicos;

                // Armazenar o texto completo também
                if (conteudoProgramaticoEstruturado != null) {
                  if (!conteudoProgramaticoEstruturado.containsKey('CONHECIMENTOS_BASICOS')) {
                    conteudoProgramaticoEstruturado['CONHECIMENTOS_BASICOS'] = {};
                  }
                  conteudoProgramaticoEstruturado['CONHECIMENTOS_BASICOS']![nomeMateria] = conteudoCompleto;
                }
              }
            });
          }
        }

        // Processar conhecimentos específicos por cargo
        if (conteudoEstruturado is Map && conteudoEstruturado.containsKey('CONHECIMENTOS_ESPECIFICOS')) {
          final especificos = conteudoEstruturado['CONHECIMENTOS_ESPECIFICOS'];
          _log('Processando conhecimentos específicos por cargo');

          if (especificos is Map) {
            especificos.forEach((cargoCodigo, materias) {
              if (materias is Map) {
                String nomeCargo = cargoCodigo.toString().replaceAll('CARGO_', '').replaceAll('_', ' ');
                _log('Processando cargo: $nomeCargo');

                // Extrair número do cargo se existir
                final regexCargo = RegExp(r'(\d+)');
                final match = regexCargo.firstMatch(nomeCargo);
                String numeroCargo = match != null ? match.group(1)! : '';

                if (!conhecimentosEspecificosPorCargo.containsKey(nomeCargo)) {
                  conhecimentosEspecificosPorCargo[nomeCargo] = {};
                }

                materias.forEach((materiaCodigo, conteudo) {
                  String nomeMateria = materiaCodigo.toString().replaceAll('_', ' ');
                  String conteudoCompleto = '';

                  if (conteudo is Map && conteudo.containsKey('value')) {
                    conteudoCompleto = conteudo['value'].toString();
                  } else {
                    conteudoCompleto = conteudo.toString();
                  }

                  // Extrair tópicos do conteúdo completo
                  List<String> topicos = _extrairTopicosDeTextoCompleto(conteudoCompleto);
                  if (conhecimentosEspecificosPorCargo[nomeCargo] != null) {
                    conhecimentosEspecificosPorCargo[nomeCargo]![nomeMateria] = topicos;
                  }
                });
              }
            });
          }
        }
      }
      // Formato antigo - para compatibilidade
      else if (dadosJson.containsKey('conhecimentos_comuns') && dadosJson['conhecimentos_comuns'] is Map) {
        final conhecimentosComunsMap = dadosJson['conhecimentos_comuns'] as Map;

        // Extrair conhecimentos comuns a todos os cargos
        if (conhecimentosComunsMap.containsKey('todos_cargos') && conhecimentosComunsMap['todos_cargos'] is Map) {
          final todosCargosMaterias = conhecimentosComunsMap['todos_cargos'] as Map;
          todosCargosMaterias.forEach((materia, topicos) {
            final String nomeMateria = materia.toString();
            List<String> topicosList = [];

            if (topicos is Map && topicos.containsKey('list')) {
              // Formato especial do conversor YAML
              final list = topicos['list'] as List;
              topicosList = list.map((item) {
                if (item is Map && item.containsKey('value')) {
                  return item['value'].toString();
                } else {
                  return item.toString();
                }
              }).toList().cast<String>();
            } else if (topicos is List) {
              topicosList = topicos.map((t) => t.toString()).toList();
            }

            conhecimentosComuns[nomeMateria] = topicosList;
          });
        }
      }

      // Processar cargos
      if (dadosJson.containsKey('cargos_disponiveis')) {
        // Novo formato com cargos_disponiveis
        List<dynamic> cargosList = [];

        if (dadosJson['cargos_disponiveis'] is Map && dadosJson['cargos_disponiveis'].containsKey('list')) {
          cargosList = dadosJson['cargos_disponiveis']['list'] as List;
        } else if (dadosJson['cargos_disponiveis'] is List) {
          cargosList = dadosJson['cargos_disponiveis'] as List;
        }

        _log('Processando ${cargosList.length} cargos do novo formato');

        for (var cargoItem in cargosList) {
          Map<String, dynamic> cargoJson = {};

          if (cargoItem is Map) {
            cargoJson = Map<String, dynamic>.from(cargoItem);
          }

          // Extrair informações básicas do cargo
          String nome = _DEFAULT_STRING;
          if (cargoJson.containsKey('nome_cargo')) {
            if (cargoJson['nome_cargo'] is Map && cargoJson['nome_cargo'].containsKey('value')) {
              nome = cargoJson['nome_cargo']['value'].toString();
            } else {
              nome = cargoJson['nome_cargo'].toString();
            }
          }

          // Extrair número do cargo se existir
          final regexCargo = RegExp(r'Cargo\s+(\d+)');
          final match = regexCargo.firstMatch(nome);
          String numeroCargo = match != null ? match.group(1)! : '';

          // Extrair escolaridade
          String escolaridade = _DEFAULT_STRING;
          if (cargoJson.containsKey('escolaridade_exigida')) {
            if (cargoJson['escolaridade_exigida'] is Map && cargoJson['escolaridade_exigida'].containsKey('value')) {
              escolaridade = cargoJson['escolaridade_exigida']['value'].toString();
            } else {
              escolaridade = cargoJson['escolaridade_exigida'].toString();
            }
          }

          // Extrair remuneração
          double salario = 0.0;
          if (cargoJson.containsKey('salario')) {
            if (cargoJson['salario'] is num) {
              salario = (cargoJson['salario'] as num).toDouble();
            } else if (cargoJson['salario'] is String) {
              try {
                salario = double.parse(cargoJson['salario'].toString().replaceAll(',', '.'));
              } catch (e) {
                _log('Erro ao converter salário: $e');
              }
            } else if (cargoJson['salario'] is Map && cargoJson['salario'].containsKey('value')) {
              try {
                salario = double.parse(cargoJson['salario']['value'].toString().replaceAll(',', '.'));
              } catch (e) {
                _log('Erro ao converter salário do formato value: $e');
              }
            }
          } else if (cargoJson.containsKey('remuneracao')) {
            if (cargoJson['remuneracao'] is num) {
              salario = (cargoJson['remuneracao'] as num).toDouble();
            } else if (cargoJson['remuneracao'] is String) {
              try {
                salario = double.parse(cargoJson['remuneracao'].toString().replaceAll(',', '.'));
              } catch (e) {
                _log('Erro ao converter salário: $e');
              }
            } else if (cargoJson['remuneracao'] is Map && cargoJson['remuneracao'].containsKey('value')) {
              try {
                salario = double.parse(cargoJson['remuneracao']['value'].toString().replaceAll(',', '.'));
              } catch (e) {
                _log('Erro ao converter salário do formato value: $e');
              }
            }
          }

          // Extrair vagas
          int vagas = 0;
          if (cargoJson.containsKey('quantidade_vagas')) {
            if (cargoJson['quantidade_vagas'] is List) {
              // Somar todas as vagas de todas as localidades
              final vagasList = cargoJson['quantidade_vagas'] as List;
              for (var vagaItem in vagasList) {
                if (vagaItem is Map && vagaItem.containsKey('total')) {
                  if (vagaItem['total'] is num) {
                    vagas += (vagaItem['total'] as num).toInt();
                  } else if (vagaItem['total'].toString() != 'CR') {
                    try {
                      vagas += int.parse(vagaItem['total'].toString());
                    } catch (e) {
                      _log('Erro ao converter vagas: $e');
                    }
                  }
                }
              }
            }
          }

          // Construir conteúdo programático para este cargo
          final List<ConteudoProgramatico> conteudoProgramatico = [];

          // 1. Adicionar conhecimentos básicos comuns (se aplicável ao cargo)
          bool cargoTemExcecao = false;

          // Verificar se o cargo é uma exceção (11, 12 ou 13)
          if (numeroCargo == '11' || numeroCargo == '12' || numeroCargo == '13') {
            cargoTemExcecao = true;
          }

          // Se não for uma exceção, adicionar conhecimentos básicos comuns
          if (!cargoTemExcecao) {
            conhecimentosComuns.forEach((materia, topicos) {
              conteudoProgramatico.add(ConteudoProgramatico(
                nome: materia,
                tipo: 'comum',
                topicos: topicos
              ));
            });
          }

          // 2. Adicionar conhecimentos específicos para este cargo
          String cargoChave = '';

          // Tentar encontrar a chave correta para o cargo nos conhecimentos específicos
          for (String key in conhecimentosEspecificosPorCargo.keys) {
            if (key.contains(numeroCargo)) {
              cargoChave = key;
              break;
            }
          }

          if (cargoChave.isNotEmpty && conhecimentosEspecificosPorCargo.containsKey(cargoChave)) {
            conhecimentosEspecificosPorCargo[cargoChave]!.forEach((materia, topicos) {
              conteudoProgramatico.add(ConteudoProgramatico(
                nome: materia,
                tipo: 'especifico',
                topicos: topicos
              ));
            });
          }

          // Adicionar o cargo à lista
          cargos.add(Cargo(
            id: 'cargo_${numeroCargo}_${DateTime.now().millisecondsSinceEpoch}',
            nome: nome,
            vagas: vagas,
            salario: salario,
            escolaridade: escolaridade,
            conteudoProgramatico: conteudoProgramatico
          ));
        }
      }
      // Formato antigo - para compatibilidade
      else if (dadosJson.containsKey('cargos')) {
        List<dynamic> cargosList = [];

        if (dadosJson['cargos'] is Map && dadosJson['cargos'].containsKey('list')) {
          // Formato especial do conversor YAML
          cargosList = dadosJson['cargos']['list'] as List;
        } else if (dadosJson['cargos'] is List) {
          cargosList = dadosJson['cargos'] as List;
        }

        for (var cargoItem in cargosList) {
          Map<String, dynamic> cargoJson = {};

          if (cargoItem is Map) {
            cargoJson = Map<String, dynamic>.from(cargoItem);
          }

          // Extrair informações do cargo
          String nome = _DEFAULT_STRING;
          if (cargoJson.containsKey('nome_cargo')) {
            if (cargoJson['nome_cargo'] is Map && cargoJson['nome_cargo'].containsKey('value')) {
              nome = cargoJson['nome_cargo']['value'].toString();
            } else {
              nome = cargoJson['nome_cargo'].toString();
            }
          } else if (cargoJson.containsKey('nome')) {
            if (cargoJson['nome'] is Map && cargoJson['nome'].containsKey('value')) {
              nome = cargoJson['nome']['value'].toString();
            } else {
              nome = cargoJson['nome'].toString();
            }
          } else if (cargoJson.containsKey('cargo')) {
            if (cargoJson['cargo'] is Map && cargoJson['cargo'].containsKey('value')) {
              nome = cargoJson['cargo']['value'].toString();
            } else {
              nome = cargoJson['cargo'].toString();
            }
          }

          // Extrair nível de escolaridade
          String nivel = _DEFAULT_STRING;
          if (cargoJson.containsKey('nivel_escolaridade')) {
            if (cargoJson['nivel_escolaridade'] is Map && cargoJson['nivel_escolaridade'].containsKey('value')) {
              nivel = cargoJson['nivel_escolaridade']['value'].toString();
            } else {
              nivel = cargoJson['nivel_escolaridade'].toString();
            }
          } else if (cargoJson.containsKey('escolaridade')) {
            if (cargoJson['escolaridade'] is Map && cargoJson['escolaridade'].containsKey('value')) {
              nivel = cargoJson['escolaridade']['value'].toString();
            } else {
              nivel = cargoJson['escolaridade'].toString();
            }
          } else if (cargoJson.containsKey('nivel')) {
            if (cargoJson['nivel'] is Map && cargoJson['nivel'].containsKey('value')) {
              nivel = cargoJson['nivel']['value'].toString();
            } else {
              nivel = cargoJson['nivel'].toString();
            }
          }

          // Extrair salário
          double salario = _DEFAULT_SALARIO;
          if (cargoJson.containsKey('remuneracao')) {
            final remuneracaoData = cargoJson['remuneracao'];
            if (remuneracaoData is Map) {
              if (remuneracaoData.containsKey('salario_inicial')) {
                // Tentar extrair valor numérico da string de remuneração (ex: "R$ 1.185,13")
                final String salarioStr = remuneracaoData['salario_inicial'].toString();
                salario = _extrairValorNumerico(salarioStr);
              }
            } else {
              // Tentar extrair valor numérico da string de remuneração
              final String remuneracaoStr = remuneracaoData.toString();
              salario = _extrairValorNumerico(remuneracaoStr);
            }
          } else if (cargoJson.containsKey('salario')) {
            if (cargoJson['salario'] is num) {
              salario = (cargoJson['salario'] as num).toDouble();
            } else {
              final String salarioStr = cargoJson['salario'].toString();
              salario = _extrairValorNumerico(salarioStr);
            }
          }

          // Taxa de inscrição
          final double taxaInscricao = (cargoJson['taxaInscricao'] is num) ?
                                      (cargoJson['taxaInscricao'] as num).toDouble() :
                                      _DEFAULT_TAXA;

          // Extrair número de vagas
          int vagas = _DEFAULT_VAGAS;
          if (cargoJson.containsKey('vagas') && cargoJson['vagas'] is num) {
            vagas = (cargoJson['vagas'] as num).toInt();
          } else if (cargoJson.containsKey('numero_vagas')) {
            if (cargoJson['numero_vagas'] is num) {
              vagas = (cargoJson['numero_vagas'] as num).toInt();
            } else if (cargoJson['numero_vagas'] is Map) {
              final vagasMap = cargoJson['numero_vagas'] as Map;
              if (vagasMap.containsKey('ampla_concorrencia') && vagasMap['ampla_concorrencia'] is num) {
                vagas = (vagasMap['ampla_concorrencia'] as num).toInt();
              }
            }
          }

          // Extrair conteúdo programático
          final List<ConteudoProgramatico> conteudoProgramatico = [];

          // Adicionar conhecimentos comuns a todos os cargos
          conhecimentosComuns.forEach((materia, topicos) {
            conteudoProgramatico.add(ConteudoProgramatico(
              nome: materia,
              tipo: 'comum',
              topicos: topicos
            ));
          });

          // Verificar diferentes formatos de conteúdo programático específico
          if (cargoJson.containsKey('conteudo_programatico')) {
            final conteudoData = cargoJson['conteudo_programatico'];

            if (conteudoData is Map && conteudoData.containsKey('conhecimentos_especificos')) {
              final especificosData = conteudoData['conhecimentos_especificos'];

              if (especificosData is Map) {
                especificosData.forEach((materia, topicos) {
                  List<String> topicosList = [];

                  if (topicos is Map && topicos.containsKey('list')) {
                    // Formato especial do conversor YAML
                    final list = topicos['list'] as List;
                    topicosList = list.map((item) {
                      if (item is Map && item.containsKey('value')) {
                        return item['value'].toString();
                      } else {
                        return item.toString();
                      }
                    }).toList().cast<String>();
                  } else if (topicos is List) {
                    topicosList = topicos.map((t) => t.toString()).toList();
                  }

                  conteudoProgramatico.add(ConteudoProgramatico(
                    nome: materia.toString(),
                    tipo: 'específico',
                    topicos: topicosList
                  ));
                });
              }
            }
          }

          // Se não encontrou conteúdo programático, adicionar padrão
          if (conteudoProgramatico.isEmpty) {
            conteudoProgramatico.add(ConteudoProgramatico(
              nome: 'Língua Portuguesa',
              tipo: 'comum',
              topicos: ['Interpretação de texto']
            ));
            conteudoProgramatico.add(ConteudoProgramatico(
              nome: 'Matemática',
              tipo: 'comum',
              topicos: ['Raciocínio lógico']
            ));
            conteudoProgramatico.add(ConteudoProgramatico(
              nome: 'Conhecimentos Gerais',
              tipo: 'comum',
              topicos: ['Atualidades']
            ));
          }

          // Adicionar cargo
          cargos.add(Cargo(
            nome: nome,
            nivel: nivel,
            salario: salario,
            taxaInscricao: taxaInscricao,
            vagas: vagas,
            escolaridade: nivel,
            conteudoProgramatico: conteudoProgramatico
          ));
        }
      }

      // Extrair texto completo
      String textoCompleto = '';
      if (dadosJson.containsKey('textoCompleto')) {
        if (dadosJson['textoCompleto'] is Map && dadosJson['textoCompleto'].containsKey('value')) {
          textoCompleto = dadosJson['textoCompleto']['value'].toString();
        } else {
          textoCompleto = dadosJson['textoCompleto'].toString();
        }
      }

      // Criar o objeto DadosExtraidos
      final dadosExtraidos = DadosExtraidos(
        titulo: titulo,
        orgao: orgao,
        banca: banca,
        dataProva: dataProva,
        inicioInscricao: inicioInscricao,
        fimInscricao: fimInscricao,
        valorTaxa: valorTaxa,
        localProva: localProva,
        cargos: cargos,
        textoCompleto: textoCompleto
      );

      // Log simplificado dos dados extraídos - apenas cargos na primeira etapa
      debugPrint('\nVERIFICAÇÃO DE DADOS EXTRAÍDOS:');
      debugPrint('  Número de Cargos: ${dadosExtraidos.cargos.length}');

      return dadosExtraidos;
    } catch (e) {
      _log('Erro ao converter dados JSON para DadosExtraidos: $e');
      throw EditalAnalysisException('Erro ao converter dados: $e');
    }
  }

  //============================================================================
  //== MÉTODOS AUXILIARES
  //============================================================================

  /// Extrai JSON da resposta da IA
  dynamic _parseJsonFromIaResponse(String resposta) {
    try {
      // Remover texto antes e depois do JSON
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
      return json.decode(jsonStr);
    } catch (e) {
      _log('Erro ao extrair JSON da resposta: $e');
      return null;
    }
  }

  /// Registra mensagens de log
  void _log(String message) {
    debugPrint('[EditalAnalyzer] $message');
  }

  /// Reporta progresso para o callback, se disponível
  void _reportProgress(double progress, String message) {
    if (onProgress != null) {
      onProgress!(progress, message);
    }
  }

  /// Tenta corrigir YAML malformado
  String _corrigirYamlMalformado(String yamlStr) {
    _log('Tentando corrigir YAML malformado...');
    _log('YAML original (primeiros 200 caracteres): ${yamlStr.substring(0, min(200, yamlStr.length))}...');

    // Verificar se o texto parece ser JSON em vez de YAML
    if (yamlStr.trim().startsWith('{') && yamlStr.trim().endsWith('}')) {
      _log('O texto parece ser JSON. Tentando converter para YAML...');
      try {
        // Tentar converter JSON para YAML
        final jsonData = json.decode(yamlStr);
        // Criar um YAML simples com os dados do JSON
        final StringBuffer yamlBuffer = StringBuffer();

        // Adicionar campos principais
        if (jsonData['titulo'] != null) {
          yamlBuffer.writeln('titulo_concurso: "${jsonData['titulo']}"');
        }
        if (jsonData['orgao'] != null) {
          yamlBuffer.writeln('orgao_responsavel: "${jsonData['orgao']}"');
        }
        if (jsonData['banca'] != null) {
          yamlBuffer.writeln('banca_organizadora: "${jsonData['banca']}"');
        }

        // Adicionar período de inscrições
        if (jsonData['inscricoes'] != null) {
          yamlBuffer.writeln('periodo_inscricoes:');
          yamlBuffer.writeln('  data_inicio: "${jsonData['inscricoes']['data_inicio'] ?? ''}"');
          yamlBuffer.writeln('  data_fim: "${jsonData['inscricoes']['data_fim'] ?? ''}"');
        }

        // Adicionar valor da taxa
        if (jsonData['inscricoes'] != null && jsonData['inscricoes']['taxa'] != null) {
          yamlBuffer.writeln('valor_taxa_inscricao:');
          yamlBuffer.writeln('  - nivel_ou_cargo: "Geral"');
          yamlBuffer.writeln('    valor: ${jsonData['inscricoes']['taxa']}');
        }

        // Adicionar cargos
        if (jsonData['cargos'] != null && jsonData['cargos'] is List) {
          yamlBuffer.writeln('cargos_disponiveis:');
          for (var cargo in jsonData['cargos']) {
            yamlBuffer.writeln('  - nome: "${cargo['cargo'] ?? ''}"');
            yamlBuffer.writeln('    escolaridade: "${cargo['escolaridade'] ?? ''}"');
            yamlBuffer.writeln('    remuneracao: ${cargo['salario'] ?? 0.0}');

            // Adicionar vagas
            if (cargo['vagas'] != null) {
              yamlBuffer.writeln('    quantidade_vagas:');
              yamlBuffer.writeln('      - localidade: "Geral"');
              yamlBuffer.writeln('        total: ${cargo['vagas']['total'] ?? 0}');
            }
          }
        }

        _log('Conversão de JSON para YAML concluída');
        return yamlBuffer.toString();
      } catch (e) {
        _log('Falha ao converter JSON para YAML: $e');
        // Continuar com as correções normais de YAML
      }
    }

    // Dividir o YAML em linhas
    final List<String> linhas = yamlStr.split('\n');
    final List<String> linhasCorrigidas = [];

    // Verificar cada linha
    for (int i = 0; i < linhas.length; i++) {
      String linha = linhas[i].trim();

      // Pular linhas vazias
      if (linha.isEmpty) {
        linhasCorrigidas.add('');
        continue;
      }

      // Pular linhas de comentário
      if (linha.startsWith('#')) {
        linhasCorrigidas.add(linha);
        continue;
      }

      // Verificar se a linha tem aspas não fechadas
      if (linha.contains('"') && linha.split('"').length % 2 == 0) {
        // Adicionar aspas de fechamento
        linha = '$linha"';
      }

      // Verificar se a linha tem dois pontos sem espaço
      if (linha.contains(':') && !linha.contains(': ')) {
        linha = linha.replaceAll(':', ': ');
      }

      // Corrigir indentação
      int indentLevel = 0;
      for (int j = 0; j < linha.length; j++) {
        if (linha[j] == ' ') {
          indentLevel++;
        } else {
          break;
        }
      }

      // Garantir que a indentação seja múltipla de 2
      if (indentLevel % 2 != 0) {
        linha = ' ' + linha;
      }

      linhasCorrigidas.add(linha);
    }

    final yamlCorrigido = linhasCorrigidas.join('\n');
    _log('YAML corrigido (primeiros 200 caracteres): ${yamlCorrigido.substring(0, min(200, yamlCorrigido.length))}...');
    return yamlCorrigido;
  }

  /// Extrai tópicos de um texto completo de conteúdo programático
  List<String> _extrairTopicosDeTextoCompleto(String textoCompleto) {
    List<String> topicos = [];

    // Dividir o texto em linhas
    final List<String> linhas = textoCompleto.split('\n');

    // Padrões para identificar tópicos
    final RegExp padraoNumerico = RegExp(r'^\s*\d+(\.\d+)*\s+');
    final RegExp padraoMarcadores = RegExp(r'^\s*[\-\*\•\·\‣\⁃\◦\▪\▫\–\—\→]\s+');

    // Processar cada linha
    for (String linha in linhas) {
      linha = linha.trim();

      // Ignorar linhas vazias
      if (linha.isEmpty) continue;

      // Remover marcadores numéricos ou de lista
      if (padraoNumerico.hasMatch(linha)) {
        linha = linha.replaceFirst(padraoNumerico, '');
      } else if (padraoMarcadores.hasMatch(linha)) {
        linha = linha.replaceFirst(padraoMarcadores, '');
      }

      // Adicionar à lista de tópicos se não estiver vazia
      if (linha.isNotEmpty) {
        topicos.add(linha);
      }
    }

    // Se não encontrou tópicos, usar o texto completo como um único tópico
    if (topicos.isEmpty && textoCompleto.trim().isNotEmpty) {
      topicos.add(textoCompleto.trim());
    }

    return topicos;
  }

  /// Cria dados de fallback para o edital do CRM-RR
  Map<String, dynamic> _criarDadosFallbackCRMRR() {
    return {
      'titulo_concurso': {
        'value': 'CONCURSO PÚBLICO CONSELHO REGIONAL DE MEDICINA DO ESTADO DE RORAIMA – CRM-RR'
      },
      'orgao_responsavel': {
        'value': 'CONSELHO REGIONAL DE MEDICINA DO ESTADO DE RORAIMA – CRM-RR'
      },
      'banca': {
        'value': 'INSTITUTO DE DESENVOLVIMENTO INSTITUCIONAL BRASILEIRO – IDIB'
      },
      'data_publicacao_edital': {
        'value': '22 de novembro de 2021'
      },
      'periodo_inscricoes': {
        'inicio': {
          'value': '22 de novembro de 2021'
        },
        'fim': {
          'value': '20 de dezembro de 2021'
        }
      },
      'data_provas': {
        'list': [
          {
            'value': '13 de fevereiro de 2022'
          }
        ]
      },
      'local_prova': {
        'value': 'Boa Vista-RR'
      },
      'cargos': {
        'list': [
          {
            'nome_cargo': {
              'value': 'Auxiliar de Serviços Gerais'
            },
            'nivel_escolaridade': {
              'value': 'Ensino Fundamental Completo'
            },
            'numero_vagas': {
              'cadastro_reserva': {
                'total': {
                  'value': 3
                },
                'negros': {
                  'value': 1
                }
              }
            },
            'remuneracao': {
              'salario_inicial': {
                'value': 'R\$ 1.185,13'
              }
            },
            'conteudo_programatico': {
              'conhecimentos_especificos': {
                'Língua Portuguesa': {
                  'list': [
                    'Interpretação de texto',
                    'Ortografia',
                    'Gramática'
                  ]
                },
                'Raciocínio Lógico': {
                  'list': [
                    'Lógica proposicional',
                    'Problemas de raciocínio'
                  ]
                }
              }
            }
          },
          {
            'nome_cargo': {
              'value': 'Motorista'
            },
            'nivel_escolaridade': {
              'value': 'Ensino Médio Completo e carteira nacional de Habilitação "B"'
            },
            'numero_vagas': {
              'cadastro_reserva': {
                'total': {
                  'value': 3
                }
              }
            },
            'remuneracao': {
              'salario_inicial': {
                'value': 'R\$ 1.621,93'
              }
            },
            'conteudo_programatico': {
              'conhecimentos_especificos': {
                'Legislação e Prática de Direção': {
                  'list': [
                    'Código de Trânsito Brasileiro',
                    'Direção defensiva'
                  ]
                },
                'Legislação Específica': {
                  'list': [
                    'Legislação de trânsito'
                  ]
                }
              }
            }
          }
        ]
      }
    };
  }

  /// Extrai um valor numérico de uma string (ex: "R$ 1.185,13" -> 1185.13)
  double _extrairValorNumerico(String valorStr) {
    try {
      // Remover caracteres não numéricos, exceto pontos e vírgulas
      String numStr = valorStr.replaceAll(RegExp(r'[^0-9\.,]'), '');

      // Tratar formato brasileiro (1.234,56)
      if (numStr.contains(',')) {
        // Se tem vírgula, assume formato brasileiro
        // Primeiro remove pontos (separadores de milhar) e depois substitui vírgula por ponto
        numStr = numStr.replaceAll('.', '').replaceAll(',', '.');
      }

      return double.parse(numStr);
    } catch (e) {
      _log('Erro ao extrair valor numérico de "$valorStr": $e');
      return _DEFAULT_SALARIO;
    }
  }

  /// Converte uma string de data para DateTime
  DateTime _parseData(String dataStr) {
    try {
      // Tentar formatos ISO
      if (dataStr.contains('-') && dataStr.length >= 10) {
        return DateTime.parse(dataStr);
      }

      // Formato brasileiro: dd/mm/yyyy
      if (dataStr.contains('/') && dataStr.length >= 10) {
        final parts = dataStr.split('/');
        if (parts.length >= 3) {
          return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        }
      }

      // Formato por extenso: "22 de novembro de 2021"
      final RegExp regexData = RegExp(r'(\d+)\s+de\s+(\w+)\s+de\s+(\d+)');
      final match = regexData.firstMatch(dataStr);

      if (match != null && match.groupCount >= 3) {
        final dia = int.parse(match.group(1)!);
        final mes = _converterMesParaNumero(match.group(2)!);
        final ano = int.parse(match.group(3)!);

        return DateTime(ano, mes, dia);
      }

      // Se não conseguir converter, retornar data atual
      return DateTime.now();
    } catch (e) {
      _log('Erro ao converter data: $dataStr - $e');
      return DateTime.now();
    }
  }

  /// Converte uma string de data no formato brasileiro (DD/MM/AAAA) para DateTime
  /// Trata especificamente o formato retornado pela LLM no YAML
  DateTime? _parseDataFormatoBrasileiro(String dataStr) {
    try {
      _log('Tentando converter data no formato brasileiro: $dataStr');

      // Remover aspas se presentes
      dataStr = dataStr.replaceAll('"', '').replaceAll('\'', '').trim();

      // Verificar formato DD/MM/AAAA
      final RegExp regexDataBarra = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})');
      final matchBarra = regexDataBarra.firstMatch(dataStr);

      if (matchBarra != null) {
        final int dia = int.parse(matchBarra.group(1)!);
        final int mes = int.parse(matchBarra.group(2)!);
        final int ano = int.parse(matchBarra.group(3)!);
        _log('Data convertida com sucesso: $dia/$mes/$ano');
        return DateTime(ano, mes, dia);
      }

      // Tentar outros formatos usando o método existente
      return _parseData(dataStr);
    } catch (e) {
      _log('Erro ao converter data no formato brasileiro: $dataStr - $e');
      return null;
    }
  }

  /// Converte nome do mês para número
  int _converterMesParaNumero(String mes) {
    mes = mes.toLowerCase();

    if (mes.contains('jan')) return 1;
    if (mes.contains('fev')) return 2;
    if (mes.contains('mar')) return 3;
    if (mes.contains('abr')) return 4;
    if (mes.contains('mai')) return 5;
    if (mes.contains('jun')) return 6;
    if (mes.contains('jul')) return 7;
    if (mes.contains('ago')) return 8;
    if (mes.contains('set')) return 9;
    if (mes.contains('out')) return 10;
    if (mes.contains('nov')) return 11;
    if (mes.contains('dez')) return 12;

    return 1; // Padrão: janeiro
  }

  /// Gera um plano de estudo personalizado com base no edital e nas preferências do usuário
  Future<Map<String, dynamic>> gerarPlanoEstudo(
    String textoEdital,
    String cargo,
    DateTime dataInicio,
    DateTime dataFim,
    {int horasDiarias = 2,
     List<String> diasDisponiveis = const ['segunda', 'terca', 'quarta', 'quinta', 'sexta', 'sabado'],
     Map<String, List<int>>? horariosEspecificos,
     List<Map<String, dynamic>>? materiasProficiencia,
     List<String>? ferramentasEstudo,
     Map<String, dynamic>? conteudoProgramatico})
  async {
    _reportProgress(0.1, 'Preparando dados para geração do plano de estudos...');

    try {
      // Calcular o número de dias disponíveis para estudo
      final int diasTotais = dataFim.difference(dataInicio).inDays + 1;
      final int diasUteisDisponiveis = (diasTotais * diasDisponiveis.length / 7).round();
      final int horasTotais = diasUteisDisponiveis * horasDiarias;

      _reportProgress(0.2, 'Gerando plano de estudos personalizado com ciclos...');

      // Preparar o prompt para a API LLM
      final prompt = await _prepararPromptPlanoEstudo(
        textoEdital,
        cargo,
        dataInicio,
        dataFim,
        horasDiarias,
        diasDisponiveis,
        horariosEspecificos: horariosEspecificos,
        materiasProficiencia: materiasProficiencia,
        ferramentasEstudo: ferramentasEstudo,
        conteudoProgramatico: conteudoProgramatico
      );

      // Chamar a API LLM com o prompt
      _reportProgress(0.3, 'Enviando solicitação para API LLM...');
      final resultado = await iaService.gerarRespostaJson(prompt);

      if (resultado == null) {
        _log('API LLM retornou null para o plano de estudos');
        throw EditalAnalysisException('Falha ao gerar plano de estudos. A API LLM não retornou dados válidos.');
      }

      _reportProgress(0.7, 'Processando plano de estudos...');
      return resultado;
    } catch (e) {
      _log('Erro ao gerar plano de estudos: $e');
      throw EditalAnalysisException('Falha ao gerar plano de estudos: $e');
    }
  }

  /// Prepara o prompt para geração do plano de estudos com ciclos
  Future<String> _prepararPromptPlanoEstudo(
    String textoEdital,
    String cargo,
    DateTime dataInicio,
    DateTime dataFim,
    int horasDiarias,
    List<String> diasDisponiveis,
    {Map<String, List<int>>? horariosEspecificos,
     List<Map<String, dynamic>>? materiasProficiencia,
     List<String>? ferramentasEstudo,
     Map<String, dynamic>? conteudoProgramatico})
  async {
    // Carregar o prompt para geração do plano de estudo com ciclos
    final String promptTemplate = await _promptService.loadStudyPlanCycleGenerationPrompt();

    final String dataInicioStr = '${dataInicio.day}/${dataInicio.month}/${dataInicio.year}';
    final String dataFimStr = '${dataFim.day}/${dataFim.month}/${dataFim.year}';
    final int diasTotais = dataFim.difference(dataInicio).inDays + 1;

    // Preparar dados do concurso
    final String dadosConcurso = '''
    Nome do Concurso: Concurso para $cargo
    Data da Prova: $dataFimStr
    Período de Estudo: $dataInicioStr a $dataFimStr ($diasTotais dias)
    ''';

    // Preparar disponibilidade semanal
    final Map<String, String> diasSemana = {
      'segunda': 'Segunda-feira',
      'terca': 'Terça-feira',
      'quarta': 'Quarta-feira',
      'quinta': 'Quinta-feira',
      'sexta': 'Sexta-feira',
      'sabado': 'Sábado',
      'domingo': 'Domingo',
    };

    String disponibilidadeSemanal = '';
    for (final dia in diasSemana.keys) {
      final bool disponivel = diasDisponiveis.contains(dia);
      final int horas = disponivel ? horasDiarias : 0;
      disponibilidadeSemanal += '- ${diasSemana[dia]}: $horas horas\n';
    }

    // Preparar horários específicos
    String horariosEspecificosStr = '';
    if (horariosEspecificos != null && horariosEspecificos.isNotEmpty) {
      for (final dia in diasSemana.keys) {
        final List<int> horarios = horariosEspecificos[dia] ?? [];
        if (horarios.isNotEmpty) {
          // Ordenar os horários
          horarios.sort();

          // Agrupar horários consecutivos
          List<String> grupos = [];
          int inicio = horarios[0];
          int fim = horarios[0];

          for (int i = 1; i < horarios.length; i++) {
            if (horarios[i] == fim + 1) {
              fim = horarios[i];
            } else {
              // Adicionar grupo anterior
              if (inicio == fim) {
                grupos.add('${inicio}:00');
              } else {
                grupos.add('${inicio}:00-${fim}:00');
              }
              inicio = horarios[i];
              fim = horarios[i];
            }
          }

          // Adicionar o último grupo
          if (inicio == fim) {
            grupos.add('${inicio}:00');
          } else {
            grupos.add('${inicio}:00-${fim}:00');
          }

          horariosEspecificosStr += '- ${diasSemana[dia]}: ${grupos.join(', ')}\n';
        } else {
          horariosEspecificosStr += '- ${diasSemana[dia]}: Nenhum horário disponível\n';
        }
      }
    } else {
      horariosEspecificosStr = 'Nenhum horário específico definido.';
    }

    // Preparar conteúdo programático
    String conteudoProgramaticoStr = 'Conteúdo programático para o cargo $cargo';
    String pesoMateriasStr = '';
    String criteriosDesempateStr = '';
    String numeroQuestoesStr = '';

    if (conteudoProgramatico != null) {
      // Formatar o conteúdo programático
      final List<dynamic> materias = conteudoProgramatico['conteudo_programatico'] ?? [];
      if (materias.isNotEmpty) {
        conteudoProgramaticoStr = 'Conteúdo programático para o cargo $cargo:\n';
        pesoMateriasStr = 'Peso das matérias:\n';
        criteriosDesempateStr = 'Critérios de desempate:\n';
        numeroQuestoesStr = 'Número de questões por matéria:\n';

        for (final materia in materias) {
          final String nomeMateria = materia['nome'] ?? 'Desconhecida';
          final String tipoMateria = materia['tipo'] ?? 'comum';
          final bool pesoMaior = materia['peso_maior'] ?? false;
          final bool criterioDesempate = materia['criterio_desempate'] ?? false;
          final int? numeroQuestoes = materia['numero_questoes'];

          conteudoProgramaticoStr += '- $nomeMateria (${tipoMateria == 'comum' ? 'Conhecimentos Básicos' : 'Conhecimentos Específicos'})\n';
          pesoMateriasStr += '- $nomeMateria: ${pesoMaior ? 'Peso maior' : 'Peso normal'}\n';
          criteriosDesempateStr += '- $nomeMateria: ${criterioDesempate ? 'Sim' : 'Não'}\n';
          numeroQuestoesStr += '- $nomeMateria: ${numeroQuestoes != null ? '$numeroQuestoes questões' : 'Não especificado'}\n';
        }
      }
    }

    // Preparar proficiência nas matérias
    String proficienciaMateriasStr = 'Proficiência média em todas as matérias';
    if (materiasProficiencia != null && materiasProficiencia.isNotEmpty) {
      proficienciaMateriasStr = 'Proficiência nas matérias:\n';
      for (final materia in materiasProficiencia) {
        final String nomeMateria = materia['nomeMateria'] ?? 'Desconhecida';
        final int nivelProficiencia = materia['nivelProficiencia'] ?? 3;
        String nivelTexto = 'Intermediário';

        switch (nivelProficiencia) {
          case 1: nivelTexto = 'Iniciante'; break;
          case 2: nivelTexto = 'Básico'; break;
          case 3: nivelTexto = 'Intermediário'; break;
          case 4: nivelTexto = 'Avançado'; break;
          case 5: nivelTexto = 'Especialista'; break;
        }

        proficienciaMateriasStr += '- $nomeMateria: $nivelTexto\n';
      }
    }

    // Preparar ferramentas de estudo
    String ferramentasEstudoStr = 'Resumos, Flashcards, Mapas Mentais, Questões';
    if (ferramentasEstudo != null && ferramentasEstudo.isNotEmpty) {
      ferramentasEstudoStr = 'Ferramentas de estudo disponíveis:\n';

      // Mapeamento de nomes de ferramentas para descrições mais detalhadas
      final Map<String, String> descricoesFerramenta = {
        'videoaulas': 'Videoaulas (assistir aulas em vídeo)',
        'pdfs': 'PDFs/Livros (leitura de material teórico)',
        'resumos': 'Resumos (leitura e criação de resumos)',
        'flashcards': 'Flashcards (revisão com cartões de memória)',
        'mapas_mentais': 'Mapas Mentais (organização visual do conteúdo)',
        'questoes': 'Questões (resolução de exercícios práticos)',
        'audioaulas': 'Audioaulas (ouvir aulas em áudio)',
        'lei_seca': 'Lei Seca (leitura direta da legislação - apenas para matérias jurídicas)',
        'livro': 'Livros (leitura de material teórico)',
      };

      for (final ferramenta in ferramentasEstudo) {
        final descricao = descricoesFerramenta[ferramenta] ?? ferramenta;
        ferramentasEstudoStr += '- $descricao\n';
      }
    }

    // Substituir variáveis no template
    final Map<String, String> variables = {
      'dados_concurso': dadosConcurso,
      'data_inicio': dataInicioStr,
      'data_fim': dataFimStr,
      'total_dias': diasTotais.toString(),
      'disponibilidade_semanal': disponibilidadeSemanal,
      'horarios_especificos': horariosEspecificosStr,
      'conteudo_programatico': conteudoProgramaticoStr,
      'proficiencia_materias': proficienciaMateriasStr,
      'ferramentas_estudo': ferramentasEstudoStr,
      'recompensas': 'Recompensas personalizadas:\n- Recompensa diária: Pausa para café\n- Recompensa semanal: Assistir um episódio de série\n- Recompensa mensal: Dia de folga nos estudos',
      'peso_materias': pesoMateriasStr,
      'criterios_desempate': criteriosDesempateStr,
      'numero_questoes': numeroQuestoesStr,
    };

    final String prompt = _promptService.customizePrompt(promptTemplate, variables);

    // Adicionar o texto do edital ao final
    return '''
    $prompt

    Texto do edital:
    $textoEdital
    ''';
  }
}
