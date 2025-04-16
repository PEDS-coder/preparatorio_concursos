import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Classe que representa um item no cache com metadados
///
/// Esta classe armazena os dados do item junto com metadados como data de criação,
/// data de expiração, prioridade, chave e tamanho. Esses metadados são usados pelo
/// [AdvancedCacheService] para gerenciar o cache de forma eficiente.
///
/// Exemplo:
/// ```dart
/// final cacheItem = CacheItem<String>(
///   data: 'Dados em cache',
///   createdAt: DateTime.now(),
///   expiresAt: DateTime.now().add(Duration(hours: 1)),
///   priority: 5,
///   key: 'minha_chave',
///   size: 100,
/// );
/// ```
class CacheItem<T> {
  final T data;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int priority;
  final String key;
  final int size;

  CacheItem({
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.priority,
    required this.key,
    required this.size,
  });

  /// Verifica se o item está expirado
  ///
  /// Retorna `true` se a data atual for posterior à data de expiração do item.
  /// Este método é usado pelo [AdvancedCacheService] para identificar itens que
  /// devem ser removidos do cache durante a limpeza periódica.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Converte o item para JSON
  Map<String, dynamic> toJson() {
    return {
      'data': data is String ? data : jsonEncode(data),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'priority': priority,
      'key': key,
      'size': size,
    };
  }

  /// Cria um item a partir de JSON
  factory CacheItem.fromJson(Map<String, dynamic> json) {
    return CacheItem(
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      priority: json['priority'],
      key: json['key'],
      size: json['size'],
    );
  }
}

/// Serviço de cache avançado com suporte a expiração, priorização e compactação
///
/// Este serviço fornece funcionalidades avançadas de cache, incluindo:
/// - Políticas de expiração baseadas em tempo
/// - Priorização de itens para gerenciamento de espaço
/// - Persistência em disco para itens de cache
/// - Limpeza automática de itens expirados
/// - Estatísticas de uso do cache
///
/// Exemplo de uso:
/// ```dart
/// final cacheService = getIt<AdvancedCacheService>();
///
/// // Salvar dados no cache com opções avançadas
/// await cacheService.saveWithOptions(
///   'minha_chave',
///   'dados_importantes',
///   expiration: Duration(hours: 2),
///   priority: 10,
/// );
///
/// // Recuperar dados do cache
/// final dados = await cacheService.getFromCache('minha_chave');
/// ```
@singleton
class AdvancedCacheService {
  static const String _tag = 'AdvancedCacheService';

  /// Tamanho máximo do cache em bytes (50MB)
  static const int _maxCacheSize = 50 * 1024 * 1024;

  /// Tempo padrão de expiração (1 dia)
  static const Duration _defaultExpiration = Duration(days: 1);

  /// Prioridade padrão (média)
  static const int _defaultPriority = 5;

  /// Cache em memória
  final Map<String, CacheItem> _memoryCache = {};

  /// Tamanho atual do cache em bytes
  int _currentCacheSize = 0;

  /// Logger
  final Logger _logger;

  /// Construtor
  AdvancedCacheService(this._logger) {
    _initCache();
  }

  /// Inicializa o cache
  Future<void> _initCache() async {
    try {
      if (kIsWeb) {
        _logger.debug('Inicializando cache em memória (Web)', tag: _tag);
        return;
      }

      _logger.debug('Inicializando cache', tag: _tag);

      // Carregar cache do disco
      await _loadCacheFromDisk();

      // Agendar limpeza periódica do cache
      Timer.periodic(Duration(hours: 6), (_) => _cleanExpiredItems());

      _logger.debug('Cache inicializado com sucesso', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao inicializar cache', tag: _tag, error: e);
    }
  }

  /// Carrega o cache do disco
  Future<void> _loadCacheFromDisk() async {
    try {
      if (kIsWeb) return;

      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/cache_metadata.json');

      if (!await cacheFile.exists()) {
        _logger.debug('Arquivo de metadados do cache não encontrado', tag: _tag);
        return;
      }

      final String jsonData = await cacheFile.readAsString();
      final List<dynamic> cacheData = jsonDecode(jsonData);

      for (var item in cacheData) {
        final cacheItem = CacheItem<String>.fromJson(item);

        // Verificar se o item está expirado
        if (cacheItem.isExpired) {
          _logger.debug('Item expirado: ${cacheItem.key}', tag: _tag);
          continue;
        }

        // Verificar se o arquivo de dados existe
        final dataFile = File('${cacheDir.path}/${cacheItem.key}');
        if (!await dataFile.exists()) {
          _logger.debug('Arquivo de dados não encontrado: ${cacheItem.key}', tag: _tag);
          continue;
        }

        // Carregar dados do arquivo
        final data = await dataFile.readAsString();

        // Adicionar ao cache em memória
        _memoryCache[cacheItem.key] = CacheItem(
          data: data,
          createdAt: cacheItem.createdAt,
          expiresAt: cacheItem.expiresAt,
          priority: cacheItem.priority,
          key: cacheItem.key,
          size: cacheItem.size,
        );

        _currentCacheSize += cacheItem.size;
      }

      _logger.debug('Cache carregado do disco: ${_memoryCache.length} itens, ${_currentCacheSize ~/ 1024} KB', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao carregar cache do disco', tag: _tag, error: e);
    }
  }

  /// Salva o cache no disco
  Future<void> _saveCacheToDisk() async {
    try {
      if (kIsWeb) return;

      final cacheDir = await _getCacheDirectory();
      final cacheFile = File('${cacheDir.path}/cache_metadata.json');

      // Converter cache para JSON
      final List<Map<String, dynamic>> cacheData = _memoryCache.values
          .map((item) => item.toJson())
          .toList();

      // Salvar metadados
      await cacheFile.writeAsString(jsonEncode(cacheData));

      _logger.debug('Cache salvo no disco: ${_memoryCache.length} itens', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao salvar cache no disco', tag: _tag, error: e);
    }
  }

  /// Obtém o diretório de cache
  Future<Directory> _getCacheDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web não suporta armazenamento em disco');
    }

    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/cache');

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Limpa itens expirados do cache
  Future<void> _cleanExpiredItems() async {
    try {
      _logger.debug('Iniciando limpeza de itens expirados', tag: _tag);

      final expiredKeys = <String>[];

      // Identificar itens expirados
      for (var entry in _memoryCache.entries) {
        if (entry.value.isExpired) {
          expiredKeys.add(entry.key);
          _currentCacheSize -= entry.value.size;
        }
      }

      // Remover itens expirados
      for (var key in expiredKeys) {
        _memoryCache.remove(key);

        // Remover arquivo de dados
        if (!kIsWeb) {
          final cacheDir = await _getCacheDirectory();
          final dataFile = File('${cacheDir.path}/$key');

          if (await dataFile.exists()) {
            await dataFile.delete();
          }
        }
      }

      _logger.debug('Limpeza concluída: ${expiredKeys.length} itens removidos', tag: _tag);

      // Salvar metadados atualizados
      await _saveCacheToDisk();
    } catch (e) {
      _logger.error('Erro ao limpar itens expirados', tag: _tag, error: e);
    }
  }

  /// Libera espaço no cache quando necessário
  Future<void> _ensureCacheSpace(int requiredSize) async {
    try {
      if (_currentCacheSize + requiredSize <= _maxCacheSize) {
        return;
      }

      _logger.debug('Liberando espaço no cache', tag: _tag);

      // Ordenar itens por prioridade (menor primeiro) e data de criação (mais antigos primeiro)
      final sortedItems = _memoryCache.values.toList()
        ..sort((a, b) {
          if (a.priority != b.priority) {
            return a.priority.compareTo(b.priority);
          }
          return a.createdAt.compareTo(b.createdAt);
        });

      int freedSpace = 0;
      final itemsToRemove = <String>[];

      // Remover itens até liberar espaço suficiente
      for (var item in sortedItems) {
        if (_currentCacheSize + requiredSize - freedSpace <= _maxCacheSize) {
          break;
        }

        itemsToRemove.add(item.key);
        freedSpace += item.size;
      }

      // Remover itens do cache
      for (var key in itemsToRemove) {
        final item = _memoryCache.remove(key);
        _currentCacheSize -= item?.size ?? 0;

        // Remover arquivo de dados
        if (!kIsWeb) {
          final cacheDir = await _getCacheDirectory();
          final dataFile = File('${cacheDir.path}/$key');

          if (await dataFile.exists()) {
            await dataFile.delete();
          }
        }
      }

      _logger.debug('Espaço liberado: ${freedSpace ~/ 1024} KB, ${itemsToRemove.length} itens removidos', tag: _tag);

      // Salvar metadados atualizados
      await _saveCacheToDisk();
    } catch (e) {
      _logger.error('Erro ao liberar espaço no cache', tag: _tag, error: e);
    }
  }

  /// Calcula o tamanho de um item
  int _calculateItemSize(String data) {
    return utf8.encode(data).length;
  }

  Future<void> saveToCache(String key, String data) async {
    return saveWithOptions(
      key,
      data,
      expiration: _defaultExpiration,
      priority: _defaultPriority
    );
  }

  /// Salva um item no cache com opções avançadas
  Future<void> saveWithOptions(
    String key,
    String data, {
    Duration? expiration,
    int? priority,
  }) async {
    try {
      // Calcular tamanho do item
      final size = _calculateItemSize(data);

      // Verificar se há espaço suficiente
      await _ensureCacheSpace(size);

      // Criar item de cache
      final cacheItem = CacheItem<String>(
        data: data,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(expiration ?? _defaultExpiration),
        priority: priority ?? _defaultPriority,
        key: key,
        size: size,
      );

      // Remover item existente se houver
      if (_memoryCache.containsKey(key)) {
        _currentCacheSize -= _memoryCache[key]!.size;
      }

      // Adicionar ao cache em memória
      _memoryCache[key] = cacheItem;
      _currentCacheSize += size;

      _logger.debug('Item salvo no cache: $key (${size ~/ 1024} KB)', tag: _tag);

      // Salvar no disco
      if (!kIsWeb) {
        final cacheDir = await _getCacheDirectory();
        final dataFile = File('${cacheDir.path}/$key');

        await dataFile.writeAsString(data);
        await _saveCacheToDisk();
      }
    } catch (e) {
      _logger.error('Erro ao salvar item no cache', tag: _tag, error: e);
    }
  }

  Future<String?> getFromCache(String key) async {
    try {
      // Verificar se o item existe no cache em memória
      if (!_memoryCache.containsKey(key)) {
        _logger.debug('Item não encontrado no cache: $key', tag: _tag);
        return null;
      }

      final cacheItem = _memoryCache[key]!;

      // Verificar se o item está expirado
      if (cacheItem.isExpired) {
        _logger.debug('Item expirado: $key', tag: _tag);

        // Remover item expirado
        _memoryCache.remove(key);
        _currentCacheSize -= cacheItem.size;

        // Remover arquivo de dados
        if (!kIsWeb) {
          final cacheDir = await _getCacheDirectory();
          final dataFile = File('${cacheDir.path}/$key');

          if (await dataFile.exists()) {
            await dataFile.delete();
          }

          await _saveCacheToDisk();
        }

        return null;
      }

      _logger.debug('Item recuperado do cache: $key', tag: _tag);
      return cacheItem.data as String;
    } catch (e) {
      _logger.error('Erro ao recuperar item do cache', tag: _tag, error: e);
      return null;
    }
  }

  Future<void> removeFromCache(String key) async {
    try {
      // Verificar se o item existe no cache em memória
      if (!_memoryCache.containsKey(key)) {
        _logger.debug('Item não encontrado no cache: $key', tag: _tag);
        return;
      }

      final cacheItem = _memoryCache[key]!;

      // Remover item do cache em memória
      _memoryCache.remove(key);
      _currentCacheSize -= cacheItem.size;

      _logger.debug('Item removido do cache: $key', tag: _tag);

      // Remover arquivo de dados
      if (!kIsWeb) {
        final cacheDir = await _getCacheDirectory();
        final dataFile = File('${cacheDir.path}/$key');

        if (await dataFile.exists()) {
          await dataFile.delete();
        }

        await _saveCacheToDisk();
      }
    } catch (e) {
      _logger.error('Erro ao remover item do cache', tag: _tag, error: e);
    }
  }

  Future<void> clearCache() async {
    try {
      // Limpar cache em memória
      _memoryCache.clear();
      _currentCacheSize = 0;

      _logger.debug('Cache em memória limpo', tag: _tag);

      // Limpar cache em disco
      if (!kIsWeb) {
        final cacheDir = await _getCacheDirectory();

        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create(recursive: true);
        }

        _logger.debug('Cache em disco limpo', tag: _tag);
      }
    } catch (e) {
      _logger.error('Erro ao limpar cache', tag: _tag, error: e);
    }
  }

  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final stats = {
        'itemCount': _memoryCache.length,
        'currentSize': _currentCacheSize,
        'maxSize': _maxCacheSize,
        'usagePercentage': (_currentCacheSize / _maxCacheSize * 100).toStringAsFixed(2),
        'expiredItems': _memoryCache.values.where((item) => item.isExpired).length,
      };

      _logger.debug('Estatísticas do cache: $stats', tag: _tag);
      return stats;
    } catch (e) {
      _logger.error('Erro ao obter estatísticas do cache', tag: _tag, error: e);
      return {
        'error': e.toString(),
      };
    }
  }

  /// Atualiza a expiração de um item
  Future<void> updateExpiration(String key, Duration newExpiration) async {
    try {
      // Verificar se o item existe no cache em memória
      if (!_memoryCache.containsKey(key)) {
        _logger.debug('Item não encontrado no cache: $key', tag: _tag);
        return;
      }

      final cacheItem = _memoryCache[key]!;

      // Atualizar expiração
      final updatedItem = CacheItem(
        data: cacheItem.data,
        createdAt: cacheItem.createdAt,
        expiresAt: DateTime.now().add(newExpiration),
        priority: cacheItem.priority,
        key: cacheItem.key,
        size: cacheItem.size,
      );

      // Atualizar item no cache em memória
      _memoryCache[key] = updatedItem;

      _logger.debug('Expiração atualizada: $key', tag: _tag);

      // Salvar metadados atualizados
      await _saveCacheToDisk();
    } catch (e) {
      _logger.error('Erro ao atualizar expiração', tag: _tag, error: e);
    }
  }

  /// Atualiza a prioridade de um item
  Future<void> updatePriority(String key, int newPriority) async {
    try {
      // Verificar se o item existe no cache em memória
      if (!_memoryCache.containsKey(key)) {
        _logger.debug('Item não encontrado no cache: $key', tag: _tag);
        return;
      }

      final cacheItem = _memoryCache[key]!;

      // Atualizar prioridade
      final updatedItem = CacheItem(
        data: cacheItem.data,
        createdAt: cacheItem.createdAt,
        expiresAt: cacheItem.expiresAt,
        priority: newPriority,
        key: cacheItem.key,
        size: cacheItem.size,
      );

      // Atualizar item no cache em memória
      _memoryCache[key] = updatedItem;

      _logger.debug('Prioridade atualizada: $key', tag: _tag);

      // Salvar metadados atualizados
      await _saveCacheToDisk();
    } catch (e) {
      _logger.error('Erro ao atualizar prioridade', tag: _tag, error: e);
    }
  }

  /// Verifica se um item existe no cache
  Future<bool> containsKey(String key) async {
    try {
      // Verificar se o item existe no cache em memória
      if (!_memoryCache.containsKey(key)) {
        return false;
      }

      final cacheItem = _memoryCache[key]!;

      // Verificar se o item está expirado
      if (cacheItem.isExpired) {
        return false;
      }

      return true;
    } catch (e) {
      _logger.error('Erro ao verificar existência de item no cache', tag: _tag, error: e);
      return false;
    }
  }

  /// Obtém o tempo de expiração de um item
  Future<Duration?> getTimeToExpiration(String key) async {
    try {
      // Verificar se o item existe no cache em memória
      if (!_memoryCache.containsKey(key)) {
        return null;
      }

      final cacheItem = _memoryCache[key]!;

      // Verificar se o item está expirado
      if (cacheItem.isExpired) {
        return Duration.zero;
      }

      return cacheItem.expiresAt.difference(DateTime.now());
    } catch (e) {
      _logger.error('Erro ao obter tempo de expiração', tag: _tag, error: e);
      return null;
    }
  }
}
