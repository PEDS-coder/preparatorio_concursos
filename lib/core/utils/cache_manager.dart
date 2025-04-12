import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Classe para gerenciar o cache de resultados de análises
class CacheManager {
  static const String _cacheDir = 'analysis_cache';

  /// Gera um hash MD5 para o conteúdo do arquivo
  static String _generateHash(List<int> fileBytes) {
    final digest = md5.convert(fileBytes);
    return digest.toString();
  }

  /// Retorna o diretório de cache
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDir');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Verifica se existe um cache para o arquivo
  static Future<bool> hasCache(List<int> fileBytes) async {
    try {
      final hash = _generateHash(fileBytes);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$hash.json');

      return await cacheFile.exists();
    } catch (e) {
      debugPrint('Erro ao verificar cache: $e');
      return false;
    }
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

      debugPrint('Resultado salvo no cache: ${cacheFile.path}');
      return true;
    } catch (e) {
      debugPrint('Erro ao salvar no cache: $e');
      return false;
    }
  }

  /// Recupera o resultado da análise do cache
  static Future<Map<String, dynamic>?> getFromCache(List<int> fileBytes) async {
    try {
      final hash = _generateHash(fileBytes);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$hash.json');

      if (await cacheFile.exists()) {
        final jsonString = await cacheFile.readAsString();
        final result = jsonDecode(jsonString) as Map<String, dynamic>;

        debugPrint('Resultado recuperado do cache: ${cacheFile.path}');
        return result;
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao recuperar do cache: $e');
      return null;
    }
  }

  /// Limpa todos os caches do aplicativo
  static Future<bool> clearCache() async {
    bool success = true;

    try {
      // 1. Limpar cache de análises
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create(recursive: true);
        debugPrint('Cache de análises de editais limpo com sucesso!');
      }

      // 2. Limpar cache temporário do aplicativo (apenas no mobile)
      if (!kIsWeb) {
        try {
          final tempDir = await getTemporaryDirectory();
          if (await tempDir.exists()) {
            // Excluir apenas arquivos, não diretórios
            final files = await tempDir.list().where((entity) => entity is File).toList();
            for (var file in files) {
              if (file is File) {
                await file.delete();
              }
            }
            debugPrint('Cache temporário limpo com sucesso');
          }
        } catch (e) {
          debugPrint('Erro ao limpar cache temporário: $e');
          // Não falhar se este cache não existir
        }

        // 3. Limpar cache de imagens (se houver)
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final imagesCacheDir = Directory('${appDir.path}/images_cache');
          if (await imagesCacheDir.exists()) {
            await imagesCacheDir.delete(recursive: true);
            debugPrint('Cache de imagens limpo com sucesso');
          }
        } catch (e) {
          debugPrint('Erro ao limpar cache de imagens: $e');
          // Não falhar se este cache não existir
        }
      }

      return success;
    } catch (e) {
      debugPrint('Erro ao limpar caches: $e');
      return false;
    }
  }

  /// Retorna o tamanho total do cache em bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      int totalSize = 0;

      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();

        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Erro ao calcular tamanho do cache: $e');
      return 0;
    }
  }

  /// Remove um arquivo específico do cache
  static Future<bool> removeFromCache(List<int> fileBytes) async {
    try {
      final hash = _generateHash(fileBytes);
      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/$hash.json');

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        debugPrint('Arquivo removido do cache: ${cacheFile.path}');
        return true;
      }

      debugPrint('Arquivo não encontrado no cache');
      return false;
    } catch (e) {
      debugPrint('Erro ao remover arquivo do cache: $e');
      return false;
    }
  }

  /// Retorna informações sobre o cache
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final cacheDir = await _getCacheDirectory();
      int totalSize = 0;
      int fileCount = 0;

      if (await cacheDir.exists()) {
        final files = await cacheDir.list().toList();
        fileCount = files.length;

        for (var file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      return {
        'size': totalSize,
        'fileCount': fileCount,
        'path': cacheDir.path,
      };
    } catch (e) {
      debugPrint('Erro ao obter informações do cache: $e');
      return {
        'size': 0,
        'fileCount': 0,
        'path': '',
        'error': e.toString(),
      };
    }
  }
}
