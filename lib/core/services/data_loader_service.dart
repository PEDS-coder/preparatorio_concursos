import 'dart:async';
import 'dart:collection';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Enum para o status do carregamento
enum LoadingStatus {
  idle,
  loading,
  success,
  error,
}

/// Classe para representar uma página de dados
class Page<T> {
  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final bool isLastPage;

  Page({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.isLastPage,
  });
}

/// Classe para representar o resultado de um carregamento
class LoadResult<T> {
  final List<T> items;
  final LoadingStatus status;
  final String? errorMessage;
  final bool hasMore;

  LoadResult({
    required this.items,
    required this.status,
    this.errorMessage,
    required this.hasMore,
  });

  /// Cria um resultado de sucesso
  factory LoadResult.success(List<T> items, bool hasMore) {
    return LoadResult(
      items: items,
      status: LoadingStatus.success,
      hasMore: hasMore,
    );
  }

  /// Cria um resultado de erro
  factory LoadResult.error(String errorMessage) {
    return LoadResult(
      items: [],
      status: LoadingStatus.error,
      errorMessage: errorMessage,
      hasMore: false,
    );
  }

  /// Cria um resultado de carregamento
  factory LoadResult.loading() {
    return LoadResult(
      items: [],
      status: LoadingStatus.loading,
      hasMore: true,
    );
  }
}

/// Serviço para otimizar o carregamento de dados com paginação e carregamento incremental
@singleton
class DataLoaderService {
  static const String _tag = 'DataLoaderService';
  final Logger _logger;

  /// Cache de páginas por chave
  final Map<String, Map<int, Page>> _pageCache = {};

  /// Cache de resultados por chave
  final Map<String, LoadResult> _resultCache = {};

  /// Controladores de stream por chave
  final Map<String, StreamController<LoadResult>> _controllers = {};

  /// Tamanho padrão da página
  static const int _defaultPageSize = 20;

  /// Número máximo de páginas em cache
  static const int _maxCachedPages = 10;

  /// Construtor
  DataLoaderService(this._logger);

  /// Carrega dados com paginação
  Stream<LoadResult<T>> loadPaginated<T>({
    required String key,
    required Future<Page<T>> Function(int pageNumber, int pageSize) loader,
    int pageSize = _defaultPageSize,
    bool resetCache = false,
  }) {
    try {
      // Limpar cache se solicitado
      if (resetCache) {
        _pageCache.remove(key);
        _resultCache.remove(key);
        _controllers.remove(key);
      }

      // Criar controlador de stream se não existir
      if (!_controllers.containsKey(key)) {
        _controllers[key] = StreamController<LoadResult<T>>.broadcast();
      }

      // Inicializar cache de páginas se não existir
      if (!_pageCache.containsKey(key)) {
        _pageCache[key] = {};
      }

      // Inicializar cache de resultados se não existir
      if (!_resultCache.containsKey(key)) {
        _resultCache[key] = LoadResult<T>.loading();
      }

      // Emitir resultado atual
      _controllers[key]!.add(_resultCache[key] as LoadResult<T>);

      // Carregar primeira página se não existir
      if (!_pageCache[key]!.containsKey(0)) {
        _loadPage<T>(key, 0, pageSize, loader);
      }

      return _controllers[key]!.stream as Stream<LoadResult<T>>;
    } catch (e) {
      _logger.error('Erro ao iniciar carregamento paginado', tag: _tag, error: e);
      final controller = StreamController<LoadResult<T>>.broadcast();
      controller.add(LoadResult<T>.error(e.toString()));
      return controller.stream;
    }
  }

  /// Carrega a próxima página
  Future<void> loadNextPage<T>({
    required String key,
    required Future<Page<T>> Function(int pageNumber, int pageSize) loader,
    int pageSize = _defaultPageSize,
  }) async {
    try {
      // Verificar se o controlador existe
      if (!_controllers.containsKey(key)) {
        _logger.warning('Controlador não encontrado: $key', tag: _tag);
        return;
      }

      // Verificar se o cache de páginas existe
      if (!_pageCache.containsKey(key)) {
        _pageCache[key] = {};
      }

      // Verificar se há mais páginas para carregar
      final currentResult = _resultCache[key];
      if (currentResult != null && !currentResult.hasMore) {
        _logger.debug('Não há mais páginas para carregar: $key', tag: _tag);
        return;
      }

      // Determinar a próxima página a ser carregada
      final nextPageNumber = _pageCache[key]!.length;

      // Carregar a próxima página
      await _loadPage<T>(key, nextPageNumber, pageSize, loader);
    } catch (e) {
      _logger.error('Erro ao carregar próxima página', tag: _tag, error: e);
      _controllers[key]?.add(LoadResult<T>.error(e.toString()));
    }
  }

  // O método de compatibilidade para chamadas antigas foi removido
  // para evitar conflitos de assinatura. Use a versão com parâmetros nomeados.

  /// Carrega uma página específica
  Future<void> _loadPage<T>(
    String key,
    int pageNumber,
    int pageSize,
    Future<Page<T>> Function(int pageNumber, int pageSize) loader,
  ) async {
    try {
      // Emitir status de carregamento
      _controllers[key]?.add(LoadResult<T>.loading());

      // Carregar página
      final page = await loader(pageNumber, pageSize);

      // Armazenar página no cache
      _pageCache[key]![pageNumber] = page;

      // Limitar o número de páginas em cache
      _limitCacheSize(key);

      // Construir lista completa de itens
      final allItems = _buildItemList<T>(key);

      // Atualizar resultado
      final result = LoadResult<T>.success(
        allItems,
        !page.isLastPage,
      );

      // Armazenar resultado no cache
      _resultCache[key] = result;

      // Emitir resultado
      _controllers[key]?.add(result);

      _logger.debug('Página $pageNumber carregada: $key (${page.items.length} itens)', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao carregar página $pageNumber', tag: _tag, error: e);
      _controllers[key]?.add(LoadResult<T>.error(e.toString()));
    }
  }

  /// Constrói a lista completa de itens a partir das páginas em cache
  List<T> _buildItemList<T>(String key) {
    try {
      // Verificar se o cache de páginas existe
      if (!_pageCache.containsKey(key)) {
        return [];
      }

      // Ordenar páginas por número
      final sortedPages = SplayTreeMap<int, Page>.from(_pageCache[key]!);

      // Construir lista completa de itens
      final allItems = <T>[];
      for (var page in sortedPages.values) {
        allItems.addAll(page.items as List<T>);
      }

      return allItems;
    } catch (e) {
      _logger.error('Erro ao construir lista de itens', tag: _tag, error: e);
      return [];
    }
  }

  /// Limita o tamanho do cache de páginas
  void _limitCacheSize(String key) {
    try {
      // Verificar se o cache de páginas existe
      if (!_pageCache.containsKey(key)) {
        return;
      }

      // Verificar se o cache excede o limite
      if (_pageCache[key]!.length <= _maxCachedPages) {
        return;
      }

      // Ordenar páginas por número (decrescente)
      final sortedPages = SplayTreeMap<int, Page>.from(
        _pageCache[key]!,
        (a, b) => b.compareTo(a),
      );

      // Manter apenas as páginas mais recentes
      final pagesToKeep = sortedPages.keys.take(_maxCachedPages).toList();
      final newCache = <int, Page>{};

      for (var pageNumber in pagesToKeep) {
        newCache[pageNumber] = _pageCache[key]![pageNumber]!;
      }

      // Atualizar cache
      _pageCache[key] = newCache;

      _logger.debug('Cache de páginas limitado: $key (${newCache.length} páginas)', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao limitar tamanho do cache', tag: _tag, error: e);
    }
  }

  /// Limpa o cache para uma chave específica
  void clearCache(String key) {
    try {
      _pageCache.remove(key);
      _resultCache.remove(key);
      _logger.debug('Cache limpo: $key', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao limpar cache', tag: _tag, error: e);
    }
  }

  /// Limpa todo o cache
  void clearAllCache() {
    try {
      _pageCache.clear();
      _resultCache.clear();
      _logger.debug('Todo o cache foi limpo', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao limpar todo o cache', tag: _tag, error: e);
    }
  }

  /// Fecha os controladores de stream
  void dispose() {
    try {
      for (var controller in _controllers.values) {
        controller.close();
      }
      _controllers.clear();
      _logger.debug('Controladores fechados', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao fechar controladores', tag: _tag, error: e);
    }
  }

  /// Obtém estatísticas do cache
  Map<String, dynamic> getCacheStats() {
    try {
      final stats = <String, dynamic>{
        'keys': _pageCache.keys.toList(),
        'totalPages': _pageCache.values.fold<int>(
          0,
          (sum, pages) => sum + pages.length,
        ),
        'totalItems': _pageCache.entries.fold<int>(
          0,
          (sum, entry) => sum + _buildItemList(entry.key).length,
        ),
        'keysWithControllers': _controllers.keys.toList(),
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
}
