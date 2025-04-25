import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Classe para processar e corrigir JSON, especialmente para lidar com respostas de LLM
class JsonProcessor {
  /// Processa uma string JSON e retorna um Map<String, dynamic>
  static Map<String, dynamic>? processJson(String jsonStr) {
    try {
      // Limpar e pré-processar o JSON
      String processedJson = _preProcessJson(jsonStr);

      // Tentar fazer o parsing do JSON
      try {
        final Map<String, dynamic> result = json.decode(processedJson);
        return result;
      } catch (e) {
        debugPrint('JsonProcessor: Erro no parsing inicial: $e');

        // Tentar corrigir problemas comuns
        processedJson = _fixCommonJsonIssues(processedJson);

        try {
          final Map<String, dynamic> result = json.decode(processedJson);
          debugPrint('JsonProcessor: JSON corrigido com sucesso!');
          return result;
        } catch (e) {
          debugPrint('JsonProcessor: Falha após correções: $e');

          // Tentar processar o JSON por partes
          return _processJsonInChunks(jsonStr);
        }
      }
    } catch (e) {
      debugPrint('JsonProcessor: Erro geral no processamento: $e');
      return null;
    }
  }

  /// Pré-processa o JSON para remover delimitadores e corrigir problemas básicos
  static String _preProcessJson(String jsonStr) {
    // Remover delimitadores de código
    final jsonStartRegex = RegExp(r'```(?:json)?\s*', multiLine: true);
    final jsonEndRegex = RegExp(r'\s*```', multiLine: true);

    String cleanJson = jsonStr;

    // Remover delimitadores de início
    final startMatch = jsonStartRegex.firstMatch(cleanJson);
    if (startMatch != null) {
      cleanJson = cleanJson.substring(startMatch.end);
    }

    // Remover delimitadores de fim
    final endMatches = jsonEndRegex.allMatches(cleanJson).toList();
    if (endMatches.isNotEmpty) {
      final endMatch = endMatches.last;
      cleanJson = cleanJson.substring(0, endMatch.start);
    }

    // Encontrar o início do JSON (primeiro '{' ou '[')
    final int jsonStart = cleanJson.contains('{') ? cleanJson.indexOf('{') : cleanJson.indexOf('[');
    if (jsonStart > 0) {
      cleanJson = cleanJson.substring(jsonStart);
    }

    // Encontrar o fim do JSON (último '}' ou ']')
    final int jsonEnd = cleanJson.lastIndexOf('}') != -1 ? cleanJson.lastIndexOf('}') + 1 : cleanJson.lastIndexOf(']') + 1;
    if (jsonEnd > 0 && jsonEnd < cleanJson.length) {
      cleanJson = cleanJson.substring(0, jsonEnd);
    }

    // Remover linhas vazias no início e fim
    cleanJson = cleanJson.trim();

    return cleanJson;
  }

  /// Corrige problemas comuns em JSON
  static String _fixCommonJsonIssues(String jsonStr) {
    String fixedJson = jsonStr;

    // Corrigir aspas simples para aspas duplas
    fixedJson = fixedJson.replaceAll("'", '"');

    // Corrigir chaves sem aspas
    final RegExp chavesSemAspas = RegExp(r'([{,]\s*)([a-zA-Z0-9_]+)\s*:');
    fixedJson = fixedJson.replaceAllMapped(chavesSemAspas, (match) {
      return '${match.group(1)}"${match.group(2)}":';
    });

    // Corrigir valores sem aspas (exceto números, true, false, null)
    final RegExp valoresSemAspas = RegExp(r':\s*([a-zA-Z][a-zA-Z0-9_]*)\s*([,}])');
    fixedJson = fixedJson.replaceAllMapped(valoresSemAspas, (match) {
      final value = match.group(1);
      if (value == 'true' || value == 'false' || value == 'null') {
        return ': $value${match.group(2)}';
      }
      return ': "$value"${match.group(2)}';
    });

    // Corrigir vírgulas extras no final de objetos ou arrays
    fixedJson = fixedJson.replaceAll(RegExp(r',\s*}'), '}');
    fixedJson = fixedJson.replaceAll(RegExp(r',\s*\]'), ']');

    // Corrigir vírgulas ausentes entre elementos
    fixedJson = fixedJson.replaceAll(RegExp(r'}\s*{'), '},{');
    fixedJson = fixedJson.replaceAll(RegExp(r']\s*\['), '],[');
    fixedJson = fixedJson.replaceAll(RegExp(r'"\s*"'), '","');

    // Corrigir aspas não escapadas dentro de strings
    fixedJson = _fixUnescapedQuotes(fixedJson);

    return fixedJson;
  }

  /// Corrige aspas não escapadas dentro de strings
  static String _fixUnescapedQuotes(String jsonStr) {
    List<String> chars = jsonStr.split('');
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < chars.length; i++) {
      if (chars[i] == '\\' && !escaped) {
        escaped = true;
      } else if (chars[i] == '"' && !escaped) {
        inString = !inString;
      } else if (chars[i] == '"' && escaped && inString) {
        chars[i - 1] = '\\\\'; // Duplicar a barra para escapar corretamente
      } else {
        escaped = false;
      }
    }

    return chars.join('');
  }

  /// Processa o JSON em partes para lidar com documentos muito grandes ou malformados
  static Map<String, dynamic>? _processJsonInChunks(String jsonStr) {
    debugPrint('JsonProcessor: Tentando processar JSON em partes...');

    try {
      // Tentar extrair o objeto JSON principal
      final int startBrace = jsonStr.indexOf('{');
      final int endBrace = jsonStr.lastIndexOf('}');

      if (startBrace >= 0 && endBrace > startBrace) {
        String mainObject = jsonStr.substring(startBrace, endBrace + 1);

        // Tentar processar o objeto principal
        try {
          return json.decode(mainObject);
        } catch (e) {
          debugPrint('JsonProcessor: Erro ao processar objeto principal: $e');
        }

        // Se falhar, tentar extrair pares chave-valor individualmente
        Map<String, dynamic> result = {};
        _extractKeyValuePairs(mainObject, result);

        if (result.isNotEmpty) {
          debugPrint('JsonProcessor: Extração de pares chave-valor bem-sucedida!');
          return result;
        }
      }

      // Se tudo falhar, tentar extrair qualquer JSON válido
      return _extractAnyValidJson(jsonStr);
    } catch (e) {
      debugPrint('JsonProcessor: Erro ao processar JSON em partes: $e');
      return null;
    }
  }

  /// Extrai pares chave-valor de um objeto JSON malformado
  static void _extractKeyValuePairs(String jsonStr, Map<String, dynamic> result) {
    // Regex para encontrar pares chave-valor
    final RegExp keyValueRegex = RegExp(r'"([^"]+)"\s*:\s*("(?:\\.|[^"\\])*"|[^,}\]]+)');
    final matches = keyValueRegex.allMatches(jsonStr);

    for (final match in matches) {
      if (match.groupCount >= 2) {
        String key = match.group(1)!;
        String valueStr = match.group(2)!;

        // Tentar processar o valor
        try {
          // Se o valor começa com aspas, é uma string
          if (valueStr.startsWith('"') && valueStr.endsWith('"')) {
            result[key] = valueStr.substring(1, valueStr.length - 1);
          }
          // Se o valor é um número
          else if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(valueStr)) {
            if (valueStr.contains('.')) {
              result[key] = double.parse(valueStr);
            } else {
              result[key] = int.parse(valueStr);
            }
          }
          // Se o valor é um booleano ou null
          else if (valueStr == 'true') {
            result[key] = true;
          } else if (valueStr == 'false') {
            result[key] = false;
          } else if (valueStr == 'null') {
            result[key] = null;
          }
          // Se o valor é um objeto ou array
          else if (valueStr.startsWith('{') && valueStr.endsWith('}')) {
            try {
              result[key] = json.decode(valueStr);
            } catch (e) {
              // Se falhar, armazenar como string
              result[key] = valueStr;
            }
          } else if (valueStr.startsWith('[') && valueStr.endsWith(']')) {
            try {
              result[key] = json.decode(valueStr);
            } catch (e) {
              // Se falhar, armazenar como string
              result[key] = valueStr;
            }
          }
          // Caso contrário, armazenar como string
          else {
            result[key] = valueStr;
          }
        } catch (e) {
          // Em caso de erro, armazenar como string
          result[key] = valueStr;
        }
      }
    }
  }

  /// Extrai qualquer JSON válido da string
  static Map<String, dynamic>? _extractAnyValidJson(String jsonStr) {
    // Tentar encontrar qualquer objeto JSON válido na string
    final RegExp jsonObjectRegex = RegExp(r'{[^{}]*(?:{[^{}]*}[^{}]*)*}');
    final matches = jsonObjectRegex.allMatches(jsonStr);

    for (final match in matches) {
      String potentialJson = match.group(0)!;
      try {
        return json.decode(potentialJson);
      } catch (e) {
        // Continuar tentando com o próximo match
      }
    }

    return null;
  }
}
