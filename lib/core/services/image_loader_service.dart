import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Classe para representar uma imagem em cache
class CachedImage {
  final Uint8List bytes;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String key;
  final int size;

  CachedImage({
    required this.bytes,
    required this.createdAt,
    required this.expiresAt,
    required this.key,
    required this.size,
  });

  /// Verifica se a imagem está expirada
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Converte a imagem para JSON
  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'key': key,
      'size': size,
    };
  }

  /// Cria uma imagem a partir de JSON e bytes
  factory CachedImage.fromJson(Map<String, dynamic> json, Uint8List bytes) {
    return CachedImage(
      bytes: bytes,
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      key: json['key'],
      size: json['size'],
    );
  }
}

/// Serviço para otimizar o carregamento de imagens com lazy loading
@singleton
class ImageLoaderService {
  static const String _tag = 'ImageLoaderService';
  
  /// Tamanho máximo do cache em bytes (20MB)
  static const int _maxCacheSize = 20 * 1024 * 1024;
  
  /// Tempo padrão de expiração (7 dias)
  static const Duration _defaultExpiration = Duration(days: 7);
  
  /// Cache em memória
  final Map<String, CachedImage> _memoryCache = {};
  
  /// Tamanho atual do cache em bytes
  int _currentCacheSize = 0;
  
  /// Logger
  final Logger _logger;
  
  /// Cliente HTTP
  final http.Client _httpClient = http.Client();
  
  /// Construtor
  ImageLoaderService(this._logger) {
    _initCache();
  }
  
  /// Inicializa o cache
  Future<void> _initCache() async {
    try {
      if (kIsWeb) {
        _logger.debug('Inicializando cache de imagens em memória (Web)', tag: _tag);
        return;
      }
      
      _logger.debug('Inicializando cache de imagens', tag: _tag);
      
      // Carregar cache do disco
      await _loadCacheFromDisk();
      
      // Agendar limpeza periódica do cache
      Timer.periodic(const Duration(hours: 12), (_) => _cleanExpiredImages());
      
      _logger.debug('Cache de imagens inicializado com sucesso', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao inicializar cache de imagens', tag: _tag, error: e);
    }
  }
  
  /// Carrega o cache do disco
  Future<void> _loadCacheFromDisk() async {
    try {
      if (kIsWeb) return;
      
      final cacheDir = await _getCacheDirectory();
      final metadataFile = File('${cacheDir.path}/image_cache_metadata.json');
      
      if (!await metadataFile.exists()) {
        _logger.debug('Arquivo de metadados do cache de imagens não encontrado', tag: _tag);
        return;
      }
      
      final String jsonData = await metadataFile.readAsString();
      final Map<String, dynamic> metadata = jsonDecode(jsonData);
      
      for (var entry in metadata.entries) {
        final key = entry.key;
        final imageData = entry.value;
        
        // Verificar se o arquivo de imagem existe
        final imageFile = File('${cacheDir.path}/images/$key');
        if (!await imageFile.exists()) {
          _logger.debug('Arquivo de imagem não encontrado: $key', tag: _tag);
          continue;
        }
        
        // Carregar bytes da imagem
        final bytes = await imageFile.readAsBytes();
        
        // Criar objeto de imagem em cache
        final cachedImage = CachedImage.fromJson(imageData, bytes);
        
        // Verificar se a imagem está expirada
        if (cachedImage.isExpired) {
          _logger.debug('Imagem expirada: $key', tag: _tag);
          await imageFile.delete();
          continue;
        }
        
        // Adicionar ao cache em memória
        _memoryCache[key] = cachedImage;
        _currentCacheSize += cachedImage.size;
      }
      
      _logger.debug('Cache de imagens carregado do disco: ${_memoryCache.length} imagens, ${_currentCacheSize ~/ 1024} KB', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao carregar cache de imagens do disco', tag: _tag, error: e);
    }
  }
  
  /// Salva o cache no disco
  Future<void> _saveCacheToDisk() async {
    try {
      if (kIsWeb) return;
      
      final cacheDir = await _getCacheDirectory();
      final metadataFile = File('${cacheDir.path}/image_cache_metadata.json');
      
      // Criar diretório de imagens se não existir
      final imagesDir = Directory('${cacheDir.path}/images');
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Converter cache para JSON
      final Map<String, dynamic> metadata = {};
      for (var entry in _memoryCache.entries) {
        metadata[entry.key] = entry.value.toJson();
        
        // Salvar imagem no disco
        final imageFile = File('${imagesDir.path}/${entry.key}');
        await imageFile.writeAsBytes(entry.value.bytes);
      }
      
      // Salvar metadados
      await metadataFile.writeAsString(jsonEncode(metadata));
      
      _logger.debug('Cache de imagens salvo no disco: ${_memoryCache.length} imagens', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao salvar cache de imagens no disco', tag: _tag, error: e);
    }
  }
  
  /// Obtém o diretório de cache
  Future<Directory> _getCacheDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError('Web não suporta armazenamento em disco');
    }
    
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/image_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  /// Limpa imagens expiradas do cache
  Future<void> _cleanExpiredImages() async {
    try {
      _logger.debug('Iniciando limpeza de imagens expiradas', tag: _tag);
      
      final expiredKeys = <String>[];
      
      // Identificar imagens expiradas
      for (var entry in _memoryCache.entries) {
        if (entry.value.isExpired) {
          expiredKeys.add(entry.key);
          _currentCacheSize -= entry.value.size;
        }
      }
      
      // Remover imagens expiradas
      for (var key in expiredKeys) {
        _memoryCache.remove(key);
        
        // Remover arquivo de imagem
        if (!kIsWeb) {
          final cacheDir = await _getCacheDirectory();
          final imageFile = File('${cacheDir.path}/images/$key');
          
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
      }
      
      _logger.debug('Limpeza concluída: ${expiredKeys.length} imagens removidas', tag: _tag);
      
      // Salvar metadados atualizados
      await _saveCacheToDisk();
    } catch (e) {
      _logger.error('Erro ao limpar imagens expiradas', tag: _tag, error: e);
    }
  }
  
  /// Libera espaço no cache quando necessário
  Future<void> _ensureCacheSpace(int requiredSize) async {
    try {
      if (_currentCacheSize + requiredSize <= _maxCacheSize) {
        return;
      }
      
      _logger.debug('Liberando espaço no cache de imagens', tag: _tag);
      
      // Ordenar imagens por data de criação (mais antigas primeiro)
      final sortedImages = _memoryCache.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      int freedSpace = 0;
      final imagesToRemove = <String>[];
      
      // Remover imagens até liberar espaço suficiente
      for (var image in sortedImages) {
        if (_currentCacheSize + requiredSize - freedSpace <= _maxCacheSize) {
          break;
        }
        
        imagesToRemove.add(image.key);
        freedSpace += image.size;
      }
      
      // Remover imagens do cache
      for (var key in imagesToRemove) {
        final image = _memoryCache.remove(key);
        _currentCacheSize -= image?.size ?? 0;
        
        // Remover arquivo de imagem
        if (!kIsWeb) {
          final cacheDir = await _getCacheDirectory();
          final imageFile = File('${cacheDir.path}/images/$key');
          
          if (await imageFile.exists()) {
            await imageFile.delete();
          }
        }
      }
      
      _logger.debug('Espaço liberado: ${freedSpace ~/ 1024} KB, ${imagesToRemove.length} imagens removidas', tag: _tag);
      
      // Salvar metadados atualizados
      await _saveCacheToDisk();
    } catch (e) {
      _logger.error('Erro ao liberar espaço no cache de imagens', tag: _tag, error: e);
    }
  }
  
  /// Gera uma chave para a URL da imagem
  String _generateKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
  
  /// Carrega uma imagem da rede ou do cache
  Future<Uint8List?> loadImage(String url, {Duration? expiration}) async {
    try {
      final key = _generateKey(url);
      
      // Verificar se a imagem está no cache em memória
      if (_memoryCache.containsKey(key)) {
        final cachedImage = _memoryCache[key]!;
        
        // Verificar se a imagem está expirada
        if (cachedImage.isExpired) {
          _logger.debug('Imagem expirada: $key', tag: _tag);
          _memoryCache.remove(key);
          _currentCacheSize -= cachedImage.size;
        } else {
          _logger.debug('Imagem carregada do cache: $key', tag: _tag);
          return cachedImage.bytes;
        }
      }
      
      // Carregar imagem da rede
      _logger.debug('Carregando imagem da rede: $url', tag: _tag);
      final response = await _httpClient.get(Uri.parse(url));
      
      if (response.statusCode != 200) {
        _logger.warning('Erro ao carregar imagem: ${response.statusCode}', tag: _tag);
        return null;
      }
      
      final bytes = response.bodyBytes;
      final size = bytes.length;
      
      // Verificar se há espaço suficiente
      await _ensureCacheSpace(size);
      
      // Criar objeto de imagem em cache
      final cachedImage = CachedImage(
        bytes: bytes,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(expiration ?? _defaultExpiration),
        key: key,
        size: size,
      );
      
      // Adicionar ao cache em memória
      _memoryCache[key] = cachedImage;
      _currentCacheSize += size;
      
      _logger.debug('Imagem carregada da rede e salva no cache: $key (${size ~/ 1024} KB)', tag: _tag);
      
      // Salvar no disco
      if (!kIsWeb) {
        await _saveCacheToDisk();
      }
      
      return bytes;
    } catch (e) {
      _logger.error('Erro ao carregar imagem', tag: _tag, error: e);
      return null;
    }
  }
  
  /// Widget para exibir uma imagem com lazy loading
  Widget getImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    Duration? expiration,
  }) {
    return FutureBuilder<Uint8List?>(
      future: loadImage(url, expiration: expiration),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return placeholder ?? const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || snapshot.data == null) {
          return errorWidget ?? const Icon(Icons.error);
        } else {
          return Image.memory(
            snapshot.data!,
            width: width,
            height: height,
            fit: fit,
          );
        }
      },
    );
  }
  
  /// Remove uma imagem do cache
  Future<void> removeImage(String url) async {
    try {
      final key = _generateKey(url);
      
      // Verificar se a imagem está no cache em memória
      if (!_memoryCache.containsKey(key)) {
        _logger.debug('Imagem não encontrada no cache: $key', tag: _tag);
        return;
      }
      
      final cachedImage = _memoryCache[key]!;
      
      // Remover imagem do cache em memória
      _memoryCache.remove(key);
      _currentCacheSize -= cachedImage.size;
      
      _logger.debug('Imagem removida do cache: $key', tag: _tag);
      
      // Remover arquivo de imagem
      if (!kIsWeb) {
        final cacheDir = await _getCacheDirectory();
        final imageFile = File('${cacheDir.path}/images/$key');
        
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        
        await _saveCacheToDisk();
      }
    } catch (e) {
      _logger.error('Erro ao remover imagem do cache', tag: _tag, error: e);
    }
  }
  
  /// Limpa o cache de imagens
  Future<void> clearCache() async {
    try {
      // Limpar cache em memória
      _memoryCache.clear();
      _currentCacheSize = 0;
      
      _logger.debug('Cache de imagens em memória limpo', tag: _tag);
      
      // Limpar cache em disco
      if (!kIsWeb) {
        final cacheDir = await _getCacheDirectory();
        
        if (await cacheDir.exists()) {
          await cacheDir.delete(recursive: true);
          await cacheDir.create(recursive: true);
        }
        
        _logger.debug('Cache de imagens em disco limpo', tag: _tag);
      }
    } catch (e) {
      _logger.error('Erro ao limpar cache de imagens', tag: _tag, error: e);
    }
  }
  
  /// Pré-carrega uma imagem
  Future<void> preloadImage(String url, {Duration? expiration}) async {
    try {
      await loadImage(url, expiration: expiration);
    } catch (e) {
      _logger.error('Erro ao pré-carregar imagem', tag: _tag, error: e);
    }
  }
  
  /// Pré-carrega várias imagens
  Future<void> preloadImages(List<String> urls, {Duration? expiration}) async {
    try {
      final futures = urls.map((url) => loadImage(url, expiration: expiration));
      await Future.wait(futures);
    } catch (e) {
      _logger.error('Erro ao pré-carregar imagens', tag: _tag, error: e);
    }
  }
  
  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    try {
      final stats = {
        'imageCount': _memoryCache.length,
        'currentSize': _currentCacheSize,
        'maxSize': _maxCacheSize,
        'usagePercentage': (_currentCacheSize / _maxCacheSize * 100).toStringAsFixed(2),
        'expiredImages': _memoryCache.values.where((item) => item.isExpired).length,
      };
      
      _logger.debug('Estatísticas do cache de imagens: $stats', tag: _tag);
      return stats;
    } catch (e) {
      _logger.error('Erro ao obter estatísticas do cache de imagens', tag: _tag, error: e);
      return {
        'error': e.toString(),
      };
    }
  }
  
  /// Fecha o cliente HTTP
  void dispose() {
    _httpClient.close();
  }
}
