/// Interface para serviços de cache
abstract class CacheServiceInterface {
  /// Inicializa o cache
  Future<void> init();
  
  /// Obtém um valor do cache
  Future<String?> getFromCache(String key, List<int> keyBytes);
  
  /// Obtém um valor do cache usando a chave diretamente
  Future<String?> getRawCache(String key);
  
  /// Salva um valor no cache
  Future<void> saveToCache(String key, List<int> keyBytes, String value);
  
  /// Limpa o cache
  Future<bool> clearCache();
  
  /// Obtém todas as chaves do cache
  Future<List<String>> getAllCacheKeys();
}
