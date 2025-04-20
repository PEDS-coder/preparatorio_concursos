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

  /// Analisa um edital enviando o PDF diretamente para a LLM
  /// Retorna um objeto DadosExtraidos com os dados extraídos
  ///
  /// IMPORTANTE: Esta implementação envia o PDF diretamente para a LLM sem extração prévia de texto,
  /// conforme requisito de não extrair dados do PDF antes do envio à LLM.
  /// A resposta é processada como JSON, com fallback para YAML se necessário.
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

      // Processar o resultado (preferencialmente JSON)
      dadosExtraidosMap = _processarRespostaLLM(resultado);

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

      // Processar o resultado (preferencialmente JSON)
      return _processarRespostaLLM(resultado);
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

      // Processar o resultado (preferencialmente JSON)
      return _processarRespostaLLM(resultado);
    } catch (e, stackTrace) {
      _log('Erro na extração de conteúdo programático: $e\nStackTrace: $stackTrace');
      rethrow;
    }
  }

  // Método gerarPlanoEstudo removido para evitar erros

  /// Processa a resposta da API LLM (preferencialmente JSON, com fallback para YAML)
  ///
  /// IMPORTANTE: Este método prioriza o processamento como JSON, que é o formato padrão
  /// solicitado nos prompts. Apenas como fallback, tenta processar como YAML se o JSON falhar.
  /// Esta abordagem garante compatibilidade com respostas antigas enquanto padroniza para JSON.
  Map<String, dynamic>? _processarRespostaLLM(String resposta) {
    try {
      // Processar como JSON (abordagem principal)
      _log('Processando resposta como JSON...');
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

      // Se falhar com JSON, tentar com YAML como fallback
      _log('Processamento JSON falhou, tentando YAML como fallback...');

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

      _log('Todas as tentativas de processamento falharam');
      return null;
    } catch (e, stackTrace) {
      _log('Erro ao processar resposta: $e\nStackTrace: $stackTrace');
      return null;
    }
  }

  /// Converte um documento YAML para Map<String, dynamic>
  /// @deprecated Este método é mantido apenas para compatibilidade com o fallback YAML
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
  /// @deprecated Este método é mantido apenas para compatibilidade com o fallback YAML
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
  /// @deprecated Este método é mantido apenas para compatibilidade com o fallback YAML
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

  /// Corrige YAML malformado
  /// @deprecated Este método é mantido apenas para compatibilidade com o fallback YAML
  String _corrigirYamlMalformado(String yamlStr) {
    // Implementação simplificada para corrigir problemas comuns em YAML
    // Apenas retorna o YAML original, pois o processamento foi simplificado para priorizar JSON
    return yamlStr;
  }

  //============================================================================
  //== MÉTODOS DE CONVERSÃO DE DADOS
  //============================================================================

  /// Converte os dados JSON para o modelo DadosExtraidos
  DadosExtraidos _converterParaDadosExtraidos(Map<String, dynamic> dadosJson) {
    try {
      // Log para depuração
      _log('Estrutura do JSON recebido: ${dadosJson.keys.join(', ')}');

      // Criar e retornar o objeto DadosExtraidos
      return DadosExtraidos.fromMap(dadosJson);
    } catch (e, stackTrace) {
      _log('Erro ao converter para DadosExtraidos: $e\nStackTrace: $stackTrace');
      throw EditalAnalysisException('Erro ao converter dados extraídos: $e');
    }
  }

  /// Extrai um valor numérico de uma string
  double _extrairValorNumerico(String valor) {
    try {
      // Remover caracteres não numéricos, exceto ponto e vírgula
      final numericStr = valor.replaceAll(RegExp(r'[^\d.,]'), '');

      // Substituir vírgula por ponto
      final normalizedStr = numericStr.replaceAll(',', '.');

      // Converter para double
      return double.parse(normalizedStr);
    } catch (e) {
      _log('Erro ao extrair valor numérico de "$valor": $e');
      return 0.0;
    }
  }

  /// Converte uma data no formato brasileiro (DD/MM/AAAA) para DateTime
  DateTime? _parseDataFormatoBrasileiro(String dataStr) {
    try {
      // Remover caracteres não numéricos e separadores
      final cleanStr = dataStr.trim();

      // Verificar se é uma data no formato DD/MM/AAAA
      final regexBr = RegExp(r'^(\d{1,2})[/\-\.](\d{1,2})[/\-\.](\d{2,4})$');
      final matchBr = regexBr.firstMatch(cleanStr);

      if (matchBr != null) {
        final day = int.parse(matchBr.group(1)!);
        final month = int.parse(matchBr.group(2)!);
        var year = int.parse(matchBr.group(3)!);

        // Ajustar ano se necessário
        if (year < 100) {
          year += 2000;
        }

        return DateTime(year, month, day);
      }

      // Verificar se é uma data no formato AAAA-MM-DD
      final regexIso = RegExp(r'^(\d{4})[/\-\.](\d{1,2})[/\-\.](\d{1,2})$');
      final matchIso = regexIso.firstMatch(cleanStr);

      if (matchIso != null) {
        final year = int.parse(matchIso.group(1)!);
        final month = int.parse(matchIso.group(2)!);
        final day = int.parse(matchIso.group(3)!);

        return DateTime(year, month, day);
      }

      return null;
    } catch (e) {
      _log('Erro ao converter data "$dataStr": $e');
      return null;
    }
  }

  /// Função para reportar progresso
  void _reportProgress(double progress, String message) {
    if (onProgress != null) {
      onProgress!(progress, message);
    }
  }

  /// Função para log (apenas em modo debug)
  void _log(String message) {
    if (kDebugMode) {
      print('[EditalAnalyzer] $message');
    }
  }
}
