import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:yaml/yaml.dart';

/// Classe para processar e corrigir YAML, especialmente para lidar com respostas de LLM
class YamlProcessor {
  /// Processa uma string YAML e retorna um Map<String, dynamic>
  static Map<String, dynamic>? processYaml(String yamlStr) {
    try {
      // Limpar e pré-processar o YAML
      String processedYaml = _preProcessYaml(yamlStr);

      // Tentar fazer o parsing do YAML
      try {
        final yamlDoc = loadYaml(processedYaml);
        final Map<String, dynamic> result = _convertYamlToMap(yamlDoc);
        return result;
      } catch (e) {
        debugPrint('YamlProcessor: Erro no parsing inicial: $e');

        // Tentar corrigir problemas comuns
        processedYaml = _fixCommonYamlIssues(processedYaml);

        try {
          final yamlDoc = loadYaml(processedYaml);
          final Map<String, dynamic> result = _convertYamlToMap(yamlDoc);
          debugPrint('YamlProcessor: YAML corrigido com sucesso!');
          return result;
        } catch (e) {
          debugPrint('YamlProcessor: Falha após correções: $e');

          // Tentar processar o YAML por partes
          return _processYamlInChunks(yamlStr);
        }
      }
    } catch (e) {
      debugPrint('YamlProcessor: Erro geral no processamento: $e');
      return null;
    }
  }

  /// Pré-processa o YAML para remover delimitadores e corrigir problemas básicos
  static String _preProcessYaml(String yamlStr) {
    // Remover delimitadores de código
    final yamlStartRegex = RegExp(r'```yaml\s*|```\s*|---\s*', multiLine: true);
    final yamlEndRegex = RegExp(r'\s*```', multiLine: true);

    String cleanYaml = yamlStr;

    // Remover delimitadores de início
    final startMatch = yamlStartRegex.firstMatch(cleanYaml);
    if (startMatch != null) {
      cleanYaml = cleanYaml.substring(startMatch.end);
    }

    // Remover delimitadores de fim
    final endMatches = yamlEndRegex.allMatches(cleanYaml).toList();
    if (endMatches.isNotEmpty) {
      final endMatch = endMatches.last;
      cleanYaml = cleanYaml.substring(0, endMatch.start);
    }

    // Remover linhas vazias no início e fim
    cleanYaml = cleanYaml.trim();

    return cleanYaml;
  }

  /// Corrige problemas comuns em YAML
  static String _fixCommonYamlIssues(String yamlStr) {
    // Dividir o YAML em linhas
    final List<String> lines = yamlStr.split('\n');
    final List<String> fixedLines = [];

    // Verificar cada linha
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];

      // Pular linhas vazias
      if (line.trim().isEmpty) {
        fixedLines.add('');
        continue;
      }

      // Pular linhas de comentário
      if (line.trim().startsWith('#')) {
        fixedLines.add(line);
        continue;
      }

      // Verificar se a linha tem aspas não fechadas
      if (_hasUnclosedQuotes(line)) {
        line = _fixUnclosedQuotes(line);
      }

      // Verificar se a linha tem dois pontos sem espaço
      if (line.contains(':') && !line.contains(': ') && !line.contains('://')) {
        line = line.replaceAll(':', ': ');
      }

      // Corrigir indentação
      line = _fixIndentation(line);

      // Corrigir linhas muito longas (especialmente em tópicos de conteúdo programático)
      if (line.length > 1000 && line.contains('-')) {
        // Dividir linhas muito longas em múltiplas linhas
        List<String> splitLines = _splitLongLine(line);
        fixedLines.addAll(splitLines);
      } else {
        fixedLines.add(line);
      }
    }

    return fixedLines.join('\n');
  }

  /// Verifica se uma linha tem aspas não fechadas
  static bool _hasUnclosedQuotes(String line) {
    int count = 0;
    bool inEscape = false;

    for (int i = 0; i < line.length; i++) {
      if (line[i] == '\\' && !inEscape) {
        inEscape = true;
      } else if (line[i] == '"' && !inEscape) {
        count++;
        inEscape = false;
      } else {
        inEscape = false;
      }
    }

    return count % 2 != 0;
  }

  /// Corrige aspas não fechadas
  static String _fixUnclosedQuotes(String line) {
    if (_hasUnclosedQuotes(line)) {
      return '$line"';
    }
    return line;
  }

  /// Corrige a indentação de uma linha
  static String _fixIndentation(String line) {
    // Contar espaços no início da linha
    int indentLevel = 0;
    for (int j = 0; j < line.length; j++) {
      if (line[j] == ' ') {
        indentLevel++;
      } else {
        break;
      }
    }

    // Garantir que a indentação seja múltipla de 2
    if (indentLevel % 2 != 0) {
      return ' ' + line;
    }

    return line;
  }

  /// Divide uma linha muito longa em múltiplas linhas
  static List<String> _splitLongLine(String line) {
    // Identificar a indentação
    int indentLevel = 0;
    for (int j = 0; j < line.length; j++) {
      if (line[j] == ' ') {
        indentLevel++;
      } else {
        break;
      }
    }

    String indent = ' ' * indentLevel;

    // Se for um item de lista (começa com -), dividir em múltiplas linhas
    if (line.trim().startsWith('-')) {
      // Extrair o conteúdo após o marcador de lista
      int dashIndex = line.indexOf('-');
      String beforeDash = line.substring(0, dashIndex + 1);
      String afterDash = line.substring(dashIndex + 1);

      // Se o conteúdo for muito longo, dividir em múltiplas linhas
      if (afterDash.length > 500) {
        List<String> parts = [];

        // Adicionar a primeira linha com o marcador
        parts.add('$beforeDash');

        // Adicionar o conteúdo com indentação adicional
        String additionalIndent = indent + '  ';
        parts.add('$additionalIndent$afterDash');

        return parts;
      }
    }

    // Se não for possível dividir de forma estruturada, retornar a linha original
    return [line];
  }

  /// Processa o YAML em partes para lidar com documentos muito grandes
  static Map<String, dynamic>? _processYamlInChunks(String yamlStr) {
    debugPrint('YamlProcessor: Tentando processar YAML em partes...');

    try {
      // Dividir o YAML em seções principais
      Map<String, dynamic> result = {};

      // Identificar seções de primeiro nível
      List<String> lines = yamlStr.split('\n');
      int currentIndex = 0;

      while (currentIndex < lines.length) {
        // Encontrar a próxima linha de primeiro nível (sem indentação)
        int nextSectionStart = _findNextSectionStart(lines, currentIndex + 1);

        if (nextSectionStart == -1) {
          nextSectionStart = lines.length;
        }

        // Extrair a seção atual
        List<String> sectionLines = lines.sublist(currentIndex, nextSectionStart);
        String sectionYaml = sectionLines.join('\n');

        // Processar a seção
        _processSectionYaml(sectionYaml, result);

        // Avançar para a próxima seção
        currentIndex = nextSectionStart;
      }

      return result;
    } catch (e) {
      debugPrint('YamlProcessor: Erro ao processar YAML em partes: $e');

      // Último recurso: tentar extrair apenas as informações básicas
      return _extractBasicInfo(yamlStr);
    }
  }

  /// Encontra o início da próxima seção de primeiro nível
  static int _findNextSectionStart(List<String> lines, int startIndex) {
    for (int i = startIndex; i < lines.length; i++) {
      String line = lines[i].trim();

      // Pular linhas vazias e comentários
      if (line.isEmpty || line.startsWith('#')) {
        continue;
      }

      // Se a linha não tem indentação e contém ':', é o início de uma nova seção
      if (!lines[i].startsWith(' ') && line.contains(':')) {
        return i;
      }
    }

    return -1; // Não encontrou mais seções
  }

  /// Processa uma seção do YAML e adiciona ao resultado
  static void _processSectionYaml(String sectionYaml, Map<String, dynamic> result) {
    try {
      // Extrair a chave da seção
      String key = '';
      String value = '';

      int colonIndex = sectionYaml.indexOf(':');
      if (colonIndex > 0) {
        key = sectionYaml.substring(0, colonIndex).trim();
        value = sectionYaml.substring(colonIndex + 1).trim();
      }

      if (key.isEmpty) {
        return;
      }

      // Tentar processar o valor como YAML
      try {
        if (value.isNotEmpty) {
          final yamlDoc = loadYaml(value);
          result[key] = _convertYamlValue(yamlDoc);
        } else {
          // Se o valor estiver vazio, tentar processar o restante como um objeto
          String remainingYaml = sectionYaml.substring(colonIndex + 1);
          if (remainingYaml.trim().isNotEmpty) {
            try {
              final yamlDoc = loadYaml(remainingYaml);
              result[key] = _convertYamlValue(yamlDoc);
            } catch (e) {
              // Se falhar, armazenar como string
              result[key] = remainingYaml.trim();
            }
          } else {
            result[key] = null;
          }
        }
      } catch (e) {
        // Se falhar o parsing, armazenar como string
        result[key] = value;
      }
    } catch (e) {
      debugPrint('YamlProcessor: Erro ao processar seção: $e');
    }
  }

  /// Extrai informações básicas do YAML quando tudo mais falha
  static Map<String, dynamic> _extractBasicInfo(String yamlStr) {
    debugPrint('YamlProcessor: Extraindo informações básicas do YAML...');

    Map<String, dynamic> result = {};

    // Padrões para extrair informações básicas
    final RegExp tituloRegex = RegExp(r'titulo_concurso:\s*(.*)', multiLine: true);
    final RegExp orgaoRegex = RegExp(r'orgao_responsavel:\s*(.*)', multiLine: true);
    final RegExp bancaRegex = RegExp(r'banca_organizadora:\s*(.*)', multiLine: true);

    // Extrair título
    final tituloMatch = tituloRegex.firstMatch(yamlStr);
    if (tituloMatch != null && tituloMatch.groupCount >= 1) {
      result['titulo_concurso'] = tituloMatch.group(1)!.trim();
    }

    // Extrair órgão
    final orgaoMatch = orgaoRegex.firstMatch(yamlStr);
    if (orgaoMatch != null && orgaoMatch.groupCount >= 1) {
      result['orgao_responsavel'] = orgaoMatch.group(1)!.trim();
    }

    // Extrair banca
    final bancaMatch = bancaRegex.firstMatch(yamlStr);
    if (bancaMatch != null && bancaMatch.groupCount >= 1) {
      result['banca_organizadora'] = bancaMatch.group(1)!.trim();
    }

    // Extrair cargos (simplificado)
    final RegExp cargoRegex = RegExp(r'nome:\s*(.*)', multiLine: true);
    final cargoMatches = cargoRegex.allMatches(yamlStr);

    List<Map<String, dynamic>> cargos = [];
    for (final match in cargoMatches) {
      if (match.groupCount >= 1) {
        cargos.add({'nome': match.group(1)!.trim()});
      }
    }

    if (cargos.isNotEmpty) {
      result['cargos'] = cargos;
    }

    return result;
  }

  /// Converte um documento YAML para Map<String, dynamic>
  static Map<String, dynamic> _convertYamlToMap(dynamic yamlDoc) {
    if (yamlDoc is YamlMap) {
      final Map<String, dynamic> result = {};
      for (final entry in yamlDoc.entries) {
        final key = entry.key.toString();
        final value = _convertYamlValue(entry.value);
        result[key] = value;
      }
      return result;
    } else {
      throw Exception('Documento YAML inválido: não é um mapa');
    }
  }

  /// Converte um valor YAML para um tipo Dart apropriado
  static dynamic _convertYamlValue(dynamic value) {
    if (value is YamlMap) {
      return _convertYamlToMap(value);
    } else if (value is YamlList) {
      return value.map((item) => _convertYamlValue(item)).toList();
    } else {
      return value;
    }
  }
}
