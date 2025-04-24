import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Classe para gerenciar o cache de resultados de análises localmente
class CacheManagerLocal {
  static const String _cacheDir = 'local_cache';

  /// Gera um hash MD5 para o conteúdo do arquivo
  static String _generateHash(List<int> fileBytes) {
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }

  /// Retorna o diretório de cache local
  static Future<Directory> _getCacheDirectory() async {
    // Usar o diretório temporário que está dentro do projeto
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tempDir.path}/$_cacheDir');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Verifica se existe um cache para o arquivo
  static Future<bool> hasCache(List<int> fileBytes) async {
    // Cache desabilitado
    return false;
  }

  /// Salva o resultado da análise no cache
  static Future<bool> saveToCache(List<int> fileBytes, Map<String, dynamic> result) async {
    try {
      final hash = _generateHash(fileBytes);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$hash.json');

      // Adicionar timestamp ao resultado
      final resultWithTimestamp = {
        ...result,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Salvar no cache
      await cacheFile.writeAsString(jsonEncode(resultWithTimestamp));

      debugPrint('Resultado salvo no cache local: ${cacheFile.path}');
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar no cache local: $e');
      return false;
    }
  }

  /// Recupera o resultado da análise do cache
  static Future<Map<String, dynamic>?> getFromCache(List<int> fileBytes) async {
    // Cache desabilitado
    return null;
  }

  /// Limpa o cache local
  static Future<bool> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
        debugPrint('Cache local limpo com sucesso!');
      }
      return true;
    } catch (e) {
      debugPrint('Erro ao limpar cache local: $e');
      return false;
    }
  }
}
