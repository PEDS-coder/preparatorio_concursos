import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preparatorio_concursos/core/utils/cache_manager.dart';
import 'package:preparatorio_concursos/core/utils/cache_manager_local.dart';
import 'package:preparatorio_concursos/core/utils/cache_cleaner.dart';
import 'package:preparatorio_concursos/core/utils/selective_cache_cleaner.dart';

/// Script para limpar todos os caches da aplicação
void main() async {
  print('Iniciando limpeza de todos os caches...');
  
  try {
    // 1. Limpar cache de análises de editais
    print('Limpando cache de análises de editais...');
    final cacheResult = await CacheManager.clearCache();
    print('Resultado: ${cacheResult ? 'Sucesso' : 'Falha'}');
    
    // 2. Limpar cache local
    print('Limpando cache local...');
    final localCacheResult = await CacheManagerLocal.clearCache();
    print('Resultado: ${localCacheResult ? 'Sucesso' : 'Falha'}');
    
    // 3. Limpar cache de análise específico
    print('Limpando cache de análise específico...');
    final analysisCacheResult = await CacheCleaner.clearAnalysisCache();
    print('Resultado: ${analysisCacheResult ? 'Sucesso' : 'Falha'}');
    
    // 4. Limpar diretório temporário
    if (!kIsWeb) {
      print('Limpando diretório temporário...');
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
          print('Cache temporário limpo com sucesso');
        }
      } catch (e) {
        print('Erro ao limpar cache temporário: $e');
      }
    }
    
    print('Todos os caches foram limpos com sucesso!');
    print('Agora você pode reiniciar a aplicação.');
  } catch (e) {
    print('Erro durante a limpeza de caches: $e');
  }
}
