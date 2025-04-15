/// Interface para serviços de cache avançado
///
/// Esta interface define os métodos para um serviço de cache com funcionalidades avançadas,
/// como expiração, prioridade e estatísticas. Ela foi criada para substituir a interface
/// ICacheService e evitar conflitos com implementações existentes.
///
/// A interface fornece métodos para operações básicas de cache (salvar, obter, remover),
/// bem como operações avançadas (expiração, prioridade, estatísticas).
abstract class IAdvancedCacheService {
  /// Salva um item no cache
  Future<void> saveToCache(String key, String data);

  /// Obtém um item do cache
  Future<String?> getFromCache(String key);

  /// Remove um item do cache
  Future<void> removeFromCache(String key);

  /// Limpa todo o cache
  Future<void> clearCache();

  /// Salva um item no cache com opções avançadas
  ///
  /// Este método permite salvar um item no cache com opções adicionais,
  /// como tempo de expiração e prioridade.
  ///
  /// @param key A chave para identificar o item no cache
  /// @param data Os dados a serem armazenados no cache
  /// @param expiration O tempo de expiração do item (opcional)
  /// @param priority A prioridade do item (opcional, valores maiores indicam maior prioridade)
  Future<void> saveWithOptions(
    String key,
    String data, {
    Duration? expiration,
    int? priority,
  });

  /// Verifica se um item existe no cache
  Future<bool> containsKey(String key);

  /// Obtém estatísticas do cache
  Future<Map<String, dynamic>> getCacheStats();

  /// Atualiza a expiração de um item
  Future<void> updateExpiration(String key, Duration newExpiration);

  /// Atualiza a prioridade de um item
  Future<void> updatePriority(String key, int newPriority);

  /// Obtém o tempo de expiração de um item
  Future<Duration?> getTimeToExpiration(String key);
}
