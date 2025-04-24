import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Classe para gerenciar configurações locais e garantir que todos os arquivos
/// sejam armazenados apenas na pasta raiz do projeto
class LocalConfig {
  /// Diretório base para todos os arquivos da aplicação
  static Directory? _baseDir;
  
  /// Inicializa a configuração local
  static Future<void> init() async {
    if (_baseDir != null) return;
    
    try {
      // Usar o diretório temporário que está dentro do projeto
      final tempDir = await getTemporaryDirectory();
      _baseDir = Directory('${tempDir.path}/concursos_ia_data');
      
      // Criar o diretório base se não existir
      if (!await _baseDir!.exists()) {
        await _baseDir!.create(recursive: true);
      }
      
      debugPrint('LocalConfig inicializado: ${_baseDir!.path}');
    } catch (e) {
      debugPrint('Erro ao inicializar LocalConfig: $e');
    }
  }
  
  /// Retorna o diretório base para todos os arquivos da aplicação
  static Future<Directory> getBaseDir() async {
    if (_baseDir == null) {
      await init();
    }
    return _baseDir!;
  }
  
  /// Retorna o diretório para um tipo específico de dados
  static Future<Directory> getDirForType(String type) async {
    final baseDir = await getBaseDir();
    final dir = Directory('${baseDir.path}/$type');
    
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return dir;
  }
  
  /// Limpa todos os diretórios de cache
  static Future<void> clearAllCaches() async {
    try {
      final baseDir = await getBaseDir();
      
      if (await baseDir.exists()) {
        // Listar todos os arquivos e diretórios
        final entities = await baseDir.list().toList();
        
        // Excluir cada entidade
        for (var entity in entities) {
          try {
            if (entity is Directory) {
              await entity.delete(recursive: true);
              await entity.create(recursive: true);
              debugPrint('Diretório ${entity.path} limpo com sucesso');
            } else if (entity is File) {
              await entity.delete();
              debugPrint('Arquivo ${entity.path} excluído com sucesso');
            }
          } catch (e) {
            debugPrint('Erro ao limpar ${entity.path}: $e');
          }
        }
        
        debugPrint('Todos os caches foram limpos com sucesso');
      }
    } catch (e) {
      debugPrint('Erro ao limpar caches: $e');
    }
  }
}
