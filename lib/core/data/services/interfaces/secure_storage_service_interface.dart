/// Interface para o serviço de armazenamento seguro
abstract class ISecureStorageService {
  /// Salva um valor de forma segura
  Future<void> saveSecure(String key, String value);
  
  /// Obtém um valor armazenado de forma segura
  Future<String?> getSecure(String key);
  
  /// Remove um valor armazenado de forma segura
  Future<void> deleteSecure(String key);
  
  /// Remove todos os valores armazenados de forma segura
  Future<void> deleteAllSecure();
  
  /// Verifica se uma chave existe no armazenamento seguro
  Future<bool> containsKeySecure(String key);
  
  /// Obtém todas as chaves e valores armazenados de forma segura
  Future<Map<String, String>> getAllSecure();
  
  /// Gera um hash seguro para uma senha
  String hashPassword(String password, String salt);
  
  /// Gera um salt aleatório para uso em hashing
  String generateSalt();
  
  /// Verifica se uma senha corresponde ao hash armazenado
  bool verifyPassword(String password, String salt, String storedHash);
}
