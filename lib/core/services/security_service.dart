import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/secure_storage_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/security_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para proteção contra ataques comuns
@singleton
class SecurityService implements ISecurityService {
  static const String _tag = 'SecurityService';
  static const String _csrfTokenKey = 'csrf_token';
  static const String _rateLimitKey = 'rate_limit';
  static const int _maxRequestsPerMinute = 60;

  final ISecureStorageService _secureStorage;
  final Logger _logger;
  final Map<String, int> _requestCounts = {};
  final Map<String, DateTime> _lastRequestTimes = {};

  SecurityService(this._secureStorage, this._logger);

  /// Gera um token CSRF (Cross-Site Request Forgery)
  @override
  Future<String> generateCsrfToken() async {
    try {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      final token = base64Url.encode(values);

      await _secureStorage.saveSecure(_csrfTokenKey, token);
      _logger.debug('Token CSRF gerado: $token', tag: _tag);

      return token;
    } catch (e) {
      _logger.error('Erro ao gerar token CSRF', tag: _tag, error: e);
      throw Exception('Erro ao gerar token CSRF: $e');
    }
  }

  /// Valida um token CSRF
  @override
  Future<bool> validateCsrfToken(String token) async {
    try {
      final storedToken = await _secureStorage.getSecure(_csrfTokenKey);

      if (storedToken == null || storedToken.isEmpty) {
        _logger.warning('Token CSRF não encontrado', tag: _tag);
        return false;
      }

      final isValid = token == storedToken;

      if (!isValid) {
        _logger.warning('Token CSRF inválido', tag: _tag);
      }

      return isValid;
    } catch (e) {
      _logger.error('Erro ao validar token CSRF', tag: _tag, error: e);
      return false;
    }
  }

  /// Verifica se um IP está bloqueado por excesso de tentativas
  @override
  bool isIpBlocked(String ip) {
    try {
      if (!_requestCounts.containsKey(ip)) {
        return false;
      }

      final lastRequestTime = _lastRequestTimes[ip];
      if (lastRequestTime == null) {
        return false;
      }

      // Verificar se o bloqueio já expirou (10 minutos)
      final now = DateTime.now();
      final difference = now.difference(lastRequestTime);

      if (difference.inMinutes >= 10) {
        // Limpar o bloqueio
        _requestCounts.remove(ip);
        _lastRequestTimes.remove(ip);
        return false;
      }

      // Verificar se excedeu o limite de tentativas
      return _requestCounts[ip]! > _maxRequestsPerMinute * 10;
    } catch (e) {
      _logger.error('Erro ao verificar bloqueio de IP', tag: _tag, error: e);
      return false;
    }
  }

  /// Registra uma requisição de um IP
  @override
  void registerRequest(String ip) {
    try {
      final now = DateTime.now();

      if (!_requestCounts.containsKey(ip)) {
        _requestCounts[ip] = 1;
        _lastRequestTimes[ip] = now;
        return;
      }

      final lastRequestTime = _lastRequestTimes[ip]!;
      final difference = now.difference(lastRequestTime);

      // Se passou mais de 1 minuto, reiniciar a contagem
      if (difference.inMinutes >= 1) {
        _requestCounts[ip] = 1;
        _lastRequestTimes[ip] = now;
        return;
      }

      // Incrementar a contagem
      _requestCounts[ip] = (_requestCounts[ip] ?? 0) + 1;
      _lastRequestTimes[ip] = now;

      // Verificar se excedeu o limite
      if (_requestCounts[ip]! > _maxRequestsPerMinute) {
        _logger.warning('IP $ip excedeu o limite de requisições', tag: _tag);
      }
    } catch (e) {
      _logger.error('Erro ao registrar requisição', tag: _tag, error: e);
    }
  }

  /// Verifica se uma requisição é permitida (rate limiting)
  @override
  bool isRequestAllowed(String ip) {
    try {
      // Verificar se o IP está bloqueado
      if (isIpBlocked(ip)) {
        _logger.warning('IP $ip está bloqueado', tag: _tag);
        return false;
      }

      // Registrar a requisição
      registerRequest(ip);

      // Verificar se excedeu o limite
      if (_requestCounts.containsKey(ip) && _requestCounts[ip]! > _maxRequestsPerMinute) {
        _logger.warning('IP $ip excedeu o limite de requisições', tag: _tag);
        return false;
      }

      return true;
    } catch (e) {
      _logger.error('Erro ao verificar permissão de requisição', tag: _tag, error: e);
      return false;
    }
  }

  /// Gera um hash seguro para uma senha
  @override
  String hashPassword(String password, String salt) {
    try {
      final bytes = utf8.encode(password + salt);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      _logger.error('Erro ao gerar hash de senha', tag: _tag, error: e);
      throw Exception('Erro ao gerar hash de senha: $e');
    }
  }

  /// Gera um salt aleatório para uso em hashing
  @override
  String generateSalt() {
    try {
      final random = Random.secure();
      final values = List<int>.generate(16, (i) => random.nextInt(256));
      return base64Url.encode(values);
    } catch (e) {
      _logger.error('Erro ao gerar salt', tag: _tag, error: e);
      throw Exception('Erro ao gerar salt: $e');
    }
  }

  /// Verifica se uma senha corresponde ao hash armazenado
  @override
  bool verifyPassword(String password, String salt, String storedHash) {
    try {
      final hash = hashPassword(password, salt);
      return hash == storedHash;
    } catch (e) {
      _logger.error('Erro ao verificar senha', tag: _tag, error: e);
      return false;
    }
  }

  /// Sanitiza uma string para evitar injeção de código
  @override
  String sanitizeInput(String input) {
    try {
      if (input.isEmpty) {
        return input;
      }

      // Remover tags HTML
      String sanitized = input.replaceAll(RegExp(r'<[^>]*>'), '');

      // Escapar caracteres especiais
      sanitized = sanitized
          .replaceAll('&', '&amp;')
          .replaceAll('<', '&lt;')
          .replaceAll('>', '&gt;')
          .replaceAll('"', '&quot;')
          .replaceAll("'", '&#x27;')
          .replaceAll('/', '&#x2F;');

      return sanitized;
    } catch (e) {
      _logger.error('Erro ao sanitizar entrada', tag: _tag, error: e);
      return '';
    }
  }

  /// Sanitiza uma string para uso em SQL
  @override
  String sanitizeSql(String input) {
    try {
      if (input.isEmpty) {
        return input;
      }

      // Escapar aspas simples
      String sanitized = input.replaceAll("'", "''");

      // Remover comentários SQL
      sanitized = sanitized.replaceAll(RegExp(r'--.*'), '');
      sanitized = sanitized.replaceAll(RegExp(r'/\*.*\*/'), '');

      return sanitized;
    } catch (e) {
      _logger.error('Erro ao sanitizar SQL', tag: _tag, error: e);
      return '';
    }
  }
}
