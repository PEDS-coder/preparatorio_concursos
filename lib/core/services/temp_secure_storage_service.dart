import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/secure_storage_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Implementação temporária do SecureStorageService usando SharedPreferences
/// para contornar problemas com o flutter_secure_storage no Windows
@singleton
class TempSecureStorageService implements ISecureStorageService {
  static const String _tag = 'TempSecureStorageService';
  static const String _prefixKey = 'temp_secure_';

  final Logger _logger;
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Construtor
  TempSecureStorageService(this._logger) {
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      _logger.debug('SharedPreferences inicializado com sucesso', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao inicializar SharedPreferences', tag: _tag, error: e);
    }
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _initPrefs();
    }
  }

  /// Salva um valor de forma segura
  @override
  Future<void> saveSecure(String key, String value) async {
    try {
      await _ensureInitialized();
      await _prefs.setString('$_prefixKey$key', value);
      _logger.debug('Valor salvo com segurança para a chave: $key', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao salvar valor seguro', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Obtém um valor armazenado de forma segura
  @override
  Future<String?> getSecure(String key) async {
    try {
      await _ensureInitialized();
      final value = _prefs.getString('$_prefixKey$key');
      return value;
    } catch (e) {
      _logger.error('Erro ao obter valor seguro', tag: _tag, error: e);
      return null;
    }
  }

  /// Remove um valor armazenado de forma segura
  @override
  Future<void> deleteSecure(String key) async {
    try {
      await _ensureInitialized();
      await _prefs.remove('$_prefixKey$key');
      _logger.debug('Valor seguro removido para a chave: $key', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao remover valor seguro', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Remove todos os valores armazenados de forma segura
  @override
  Future<void> deleteAllSecure() async {
    try {
      await _ensureInitialized();
      // Remover apenas as chaves com o prefixo
      final allKeys = _prefs.getKeys();
      for (final key in allKeys) {
        if (key.startsWith(_prefixKey)) {
          await _prefs.remove(key);
        }
      }
      _logger.debug('Todos os valores seguros foram removidos', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao remover todos os valores seguros', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Verifica se uma chave existe no armazenamento seguro
  @override
  Future<bool> containsKeySecure(String key) async {
    try {
      await _ensureInitialized();
      return _prefs.containsKey('$_prefixKey$key');
    } catch (e) {
      _logger.error('Erro ao verificar existência de chave segura', tag: _tag, error: e);
      return false;
    }
  }

  /// Obtém todas as chaves e valores armazenados de forma segura
  @override
  Future<Map<String, String>> getAllSecure() async {
    try {
      await _ensureInitialized();
      final allKeys = _prefs.getKeys();
      final Map<String, String> result = {};
      
      for (final key in allKeys) {
        if (key.startsWith(_prefixKey)) {
          final value = _prefs.getString(key);
          if (value != null) {
            // Remover o prefixo da chave
            final originalKey = key.substring(_prefixKey.length);
            result[originalKey] = value;
          }
        }
      }
      
      return result;
    } catch (e) {
      _logger.error('Erro ao obter todos os valores seguros', tag: _tag, error: e);
      return {};
    }
  }

  /// Gera um hash seguro para uma senha
  @override
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gera um salt aleatório para uso em hashing
  @override
  String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Verifica se uma senha corresponde ao hash armazenado
  @override
  bool verifyPassword(String password, String salt, String storedHash) {
    final hash = hashPassword(password, salt);
    return hash == storedHash;
  }
}
