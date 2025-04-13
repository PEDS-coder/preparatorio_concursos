/// Interface para o serviço de segurança
abstract class ISecurityService {
  /// Gera um token CSRF (Cross-Site Request Forgery)
  Future<String> generateCsrfToken();
  
  /// Valida um token CSRF
  Future<bool> validateCsrfToken(String token);
  
  /// Verifica se um IP está bloqueado por excesso de tentativas
  bool isIpBlocked(String ip);
  
  /// Registra uma requisição de um IP
  void registerRequest(String ip);
  
  /// Verifica se uma requisição é permitida (rate limiting)
  bool isRequestAllowed(String ip);
  
  /// Gera um hash seguro para uma senha
  String hashPassword(String password, String salt);
  
  /// Gera um salt aleatório para uso em hashing
  String generateSalt();
  
  /// Verifica se uma senha corresponde ao hash armazenado
  bool verifyPassword(String password, String salt, String storedHash);
  
  /// Sanitiza uma string para evitar injeção de código
  String sanitizeInput(String input);
  
  /// Sanitiza uma string para uso em SQL
  String sanitizeSql(String input);
}
