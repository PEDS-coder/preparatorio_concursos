import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Utilitário para limpar o cache de análise de editais
class CacheCleaner {
  static const String _tag = 'CacheCleaner';

  /// Limpa o cache de análise de editais
  static Future<bool> clearAnalysisCache() async {
    try {
      if (kIsWeb) {
        debugPrint('[$_tag] Ambiente web detectado, não é possível limpar o cache');
        return false;
      }

      // Obter diretório de documentos
      final appDir = await getApplicationDocumentsDirectory();
      
      // Limpar cache de análise
      final analysisCacheDir = Directory('${appDir.path}/analysis_cache');
      if (await analysisCacheDir.exists()) {
        await analysisCacheDir.delete(recursive: true);
        await analysisCacheDir.create(recursive: true);
        debugPrint('[$_tag] Cache de análise de editais limpo com sucesso!');
      }

      // Limpar cache do serviço de IA
      final iaCacheDir = Directory('${appDir.path}/cache');
      if (await iaCacheDir.exists()) {
        await iaCacheDir.delete(recursive: true);
        await iaCacheDir.create(recursive: true);
        debugPrint('[$_tag] Cache do serviço de IA limpo com sucesso!');
      }

      return true;
    } catch (e) {
      debugPrint('[$_tag] Erro ao limpar cache: $e');
      return false;
    }
  }

  /// Retorna informações sobre o cache
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      if (kIsWeb) {
        return {
          'web': true,
          'message': 'Ambiente web não suporta cache em disco'
        };
      }

      // Obter diretório de documentos
      final appDir = await getApplicationDocumentsDirectory();
      
      // Verificar cache de análise
      final analysisCacheDir = Directory('${appDir.path}/analysis_cache');
      int analysisFileCount = 0;
      int analysisCacheSize = 0;
      
      if (await analysisCacheDir.exists()) {
        final files = await analysisCacheDir.list().toList();
        analysisFileCount = files.length;
        
        for (var file in files) {
          if (file is File) {
            analysisCacheSize += await file.length();
          }
        }
      }
      
      // Verificar cache do serviço de IA
      final iaCacheDir = Directory('${appDir.path}/cache');
      int iaCacheFileCount = 0;
      int iaCacheSize = 0;
      
      if (await iaCacheDir.exists()) {
        final files = await iaCacheDir.list().toList();
        iaCacheFileCount = files.length;
        
        for (var file in files) {
          if (file is File) {
            iaCacheSize += await file.length();
          }
        }
      }
      
      return {
        'analysisCache': {
          'path': analysisCacheDir.path,
          'fileCount': analysisFileCount,
          'size': analysisCacheSize,
          'sizeKB': (analysisCacheSize / 1024).round(),
        },
        'iaCache': {
          'path': iaCacheDir.path,
          'fileCount': iaCacheFileCount,
          'size': iaCacheSize,
          'sizeKB': (iaCacheSize / 1024).round(),
        },
        'total': {
          'fileCount': analysisFileCount + iaCacheFileCount,
          'size': analysisCacheSize + iaCacheSize,
          'sizeKB': ((analysisCacheSize + iaCacheSize) / 1024).round(),
        }
      };
    } catch (e) {
      debugPrint('[$_tag] Erro ao obter informações do cache: $e');
      return {
        'error': e.toString()
      };
    }
  }
}
