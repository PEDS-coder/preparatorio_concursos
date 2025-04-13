import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../data/services/interfaces/cache_service_interface.dart';
import '../utils/logger_adapter.dart';

class CacheService implements CacheServiceInterface {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Diretório de cache
  Directory? _cacheDir;
  bool _initialized = false;

  // Inicializar o serviço de cache
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // No ambiente web, não podemos usar o sistema de arquivos
        // Apenas marcamos como inicializado para evitar erros
        _initialized = true;
        AppLogger.i('CacheService', 'Inicializado em modo web (sem armazenamento persistente)');
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/analysis_cache');

      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      _initialized = true;
      AppLogger.i('CacheService', 'Inicializado: ${_cacheDir!.path}');
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao inicializar', e);
    }
  }

  // Gerar uma chave de cache baseada no conteúdo do PDF e no prompt
  String _generateCacheKey(String prompt, List<int> pdfBytes) {
    final contentHash = sha256.convert(pdfBytes).toString();
    final promptHash = sha256.convert(utf8.encode(prompt)).toString();
    return '$contentHash-$promptHash';
  }

  // Salvar resultado no cache
  Future<bool> saveToCache(String prompt, List<int> pdfBytes, String result) async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível salvar no cache');
      return false;
    }
    if (_cacheDir == null) return false;

    try {
      final cacheKey = _generateCacheKey(prompt, pdfBytes);
      final cacheFile = File('${_cacheDir!.path}/$cacheKey.json');

      // Criar um objeto com metadados e resultado
      final cacheData = {
        'timestamp': DateTime.now().toIso8601String(),
        'prompt': prompt,
        'result': result,
      };

      await cacheFile.writeAsString(jsonEncode(cacheData));
      AppLogger.i('CacheService', 'Resultado salvo no cache: ${cacheFile.path}');
      return true;
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao salvar no cache', e);
      return false;
    }
  }

  // Recuperar resultado do cache
  Future<String?> getFromCache(String prompt, List<int> pdfBytes) async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível recuperar do cache');
      return null;
    }
    if (_cacheDir == null) return null;

    try {
      final cacheKey = _generateCacheKey(prompt, pdfBytes);
      final cacheFile = File('${_cacheDir!.path}/$cacheKey.json');

      if (await cacheFile.exists()) {
        final cacheData = jsonDecode(await cacheFile.readAsString());
        AppLogger.i('CacheService', 'Resultado recuperado do cache: ${cacheFile.path}');
        AppLogger.d('CacheService', 'Data do cache: ${cacheData['timestamp']}');
        return cacheData['result'];
      }

      return null;
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao recuperar do cache', e);
      return null;
    }
  }

  // Verificar se existe cache para um determinado PDF e prompt
  Future<bool> hasCache(String prompt, List<int> pdfBytes) async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível verificar cache');
      return false;
    }
    if (_cacheDir == null) return false;

    try {
      final cacheKey = _generateCacheKey(prompt, pdfBytes);
      final cacheFile = File('${_cacheDir!.path}/$cacheKey.json');
      return await cacheFile.exists();
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao verificar cache', e);
      return false;
    }
  }

  // Limpar todo o cache
  Future<bool> clearCache() async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível limpar cache');
      return false;
    }
    if (_cacheDir == null) return false;

    try {
      if (await _cacheDir!.exists()) {
        // Em vez de excluir o diretório inteiro, vamos excluir cada arquivo individualmente
        final files = await _cacheDir!.list().toList();
        for (var file in files) {
          try {
            if (file is File) {
              await file.delete();
              AppLogger.d('CacheService', 'Arquivo ${file.path} excluído com sucesso');
            }
          } catch (e) {
            AppLogger.e('CacheService', 'Erro ao excluir arquivo ${file.path}', e);
          }
        }
        AppLogger.i('CacheService', 'Cache limpo com sucesso!');
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao limpar cache', e);
      return false;
    }
  }

  // Listar todos os arquivos no cache
  Future<List<String>> listCacheFiles() async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível listar arquivos do cache');
      return [];
    }
    if (_cacheDir == null) return [];

    try {
      final files = await _cacheDir!.list().toList();
      return files.map((file) => file.path).toList();
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao listar arquivos do cache', e);
      return [];
    }
  }

  // Obter todas as chaves de cache
  Future<List<String>> getAllCacheKeys() async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível obter chaves de cache');
      return [];
    }
    if (_cacheDir == null) return [];

    try {
      final files = await _cacheDir!.list().toList();
      return files
          .where((file) => file.path.endsWith('.json'))
          .map((file) => file.path.split('/').last.replaceAll('.json', ''))
          .toList();
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao obter chaves de cache', e);
      return [];
    }
  }

  // Obter conteúdo do cache a partir da chave
  Future<String?> getRawCache(String cacheKey) async {
    if (!_initialized) await init();
    if (kIsWeb) {
      AppLogger.w('CacheService', 'Ambiente web detectado, não é possível obter conteúdo do cache');
      return null;
    }
    if (_cacheDir == null) return null;

    try {
      final cacheFile = File('${_cacheDir!.path}/$cacheKey.json');

      if (await cacheFile.exists()) {
        final cacheData = jsonDecode(await cacheFile.readAsString());
        AppLogger.i('CacheService', 'Resultado recuperado do cache: ${cacheFile.path}');
        return cacheData['result'];
      }

      return null;
    } catch (e) {
      AppLogger.e('CacheService', 'Erro ao recuperar do cache', e);
      return null;
    }
  }
}
