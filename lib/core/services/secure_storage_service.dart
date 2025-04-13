import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/secure_storage_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para armazenamento seguro de credenciais e dados sensíveis
@singleton
class SecureStorageService implements ISecureStorageService {
  static const String _tag = 'SecureStorageService';

  final FlutterSecureStorage _secureStorage;
  final Logger _logger;

  /// Construtor
  SecureStorageService(this._logger)
      : _secureStorage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            resetOnError: true,
            keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
            storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock,
            synchronizable: false,
          ),
          wOptions: WindowsOptions(
            useBackwardCompatibility: false,
          ),
        );

  /// Salva um valor de forma segura
  Future<void> saveSecure(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      _logger.debug('Valor salvo com segurança para a chave: $key', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao salvar valor seguro', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Obtém um valor armazenado de forma segura
  Future<String?> getSecure(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value;
    } catch (e) {
      _logger.error('Erro ao obter valor seguro', tag: _tag, error: e);
      return null;
    }
  }

  /// Remove um valor armazenado de forma segura
  Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
      _logger.debug('Valor seguro removido para a chave: $key', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao remover valor seguro', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Remove todos os valores armazenados de forma segura
  Future<void> deleteAllSecure() async {
    try {
      await _secureStorage.deleteAll();
      _logger.debug('Todos os valores seguros foram removidos', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao remover todos os valores seguros', tag: _tag, error: e);
      rethrow;
    }
  }

  /// Verifica se uma chave existe no armazenamento seguro
  Future<bool> containsKeySecure(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      _logger.error('Erro ao verificar existência de chave segura', tag: _tag, error: e);
      return false;
    }
  }

  /// Obtém todas as chaves e valores armazenados de forma segura
  Future<Map<String, String>> getAllSecure() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      _logger.error('Erro ao obter todos os valores seguros', tag: _tag, error: e);
      return {};
    }
  }

  /// Gera um hash seguro para uma senha
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Gera um salt aleatório para uso em hashing
  String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Verifica se uma senha corresponde ao hash armazenado
  bool verifyPassword(String password, String salt, String storedHash) {
    final hash = hashPassword(password, salt);
    return hash == storedHash;
  }
}
