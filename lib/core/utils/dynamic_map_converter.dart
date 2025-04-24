import 'package:flutter/foundation.dart';

/// Classe utilitária para converter mapas dinâmicos para Map<String, dynamic>
class DynamicMapConverter {
  /// Converte qualquer tipo de mapa para Map<String, dynamic> de forma recursiva e segura
  static Map<String, dynamic> toStringDynamicMap(dynamic input) {
    if (input == null) {
      debugPrint('DynamicMapConverter: O objeto é nulo');
      return {};
    }

    // Se já é um Map<String, dynamic>, retornar diretamente
    if (input is Map<String, dynamic>) {
      return input;
    }

    // Se não é um mapa, retornar um mapa vazio
    if (input is! Map) {
      debugPrint('DynamicMapConverter: O objeto não é um mapa: ${input.runtimeType}');
      return {};
    }

    final Map<String, dynamic> result = {};

    input.forEach((key, value) {
      if (key == null) {
        debugPrint('DynamicMapConverter: Chave nula encontrada, ignorando');
        return;
      }

      // Converter a chave para string
      final String stringKey = key.toString();

      // Converter o valor recursivamente se for um mapa
      if (value is Map) {
        result[stringKey] = toStringDynamicMap(value);
      }
      // Converter o valor recursivamente se for uma lista
      else if (value is List) {
        result[stringKey] = _convertList(value);
      }
      // Usar o valor diretamente para outros tipos
      else {
        result[stringKey] = value;
      }
    });

    return result;
  }

  /// Método auxiliar para converter listas recursivamente
  static List<dynamic> _convertList(List<dynamic> list) {
    return list.map((item) {
      if (item == null) {
        return null;
      } else if (item is Map) {
        return toStringDynamicMap(item);
      } else if (item is List) {
        return _convertList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Método para garantir que um mapa seja do tipo Map<String, dynamic>
  /// Retorna um mapa vazio se o input for nulo
  static Map<String, dynamic> ensureStringDynamicMap(dynamic input) {
    if (input == null) {
      return {};
    }

    try {
      if (input is Map) {
        return toStringDynamicMap(input);
      }
    } catch (e) {
      debugPrint('DynamicMapConverter: Erro ao converter mapa: $e');
    }

    return {};
  }

  /// Método para garantir que uma lista de mapas seja do tipo List<Map<String, dynamic>>
  /// Retorna uma lista vazia se o input for nulo
  static List<Map<String, dynamic>> ensureListOfMaps(dynamic input) {
    if (input == null) {
      return [];
    }

    try {
      if (input is List) {
        return input.map((item) {
          if (item is Map) {
            return toStringDynamicMap(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
    } catch (e) {
      debugPrint('DynamicMapConverter: Erro ao converter lista de mapas: $e');
    }

    return [];
  }

  /// Método para garantir que um valor seja do tipo esperado
  /// Retorna o valor padrão se o input não for do tipo esperado
  static T ensureType<T>(dynamic input, T defaultValue) {
    if (input is T) {
      return input;
    }
    return defaultValue;
  }
}
