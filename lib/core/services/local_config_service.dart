import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/remote_config_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar configurações locais
/// Esta é uma substituição temporária para o Firebase Remote Config
@singleton
class LocalConfigService implements IRemoteConfigService {
  static const String _tag = 'LocalConfigService';
  static const String _prefsKey = 'local_config';

  final Logger _logger;
  final IAnalyticsService _analyticsService;
  late Map<String, dynamic> _config;
  late SharedPreferences _prefs;
  bool _initialized = false;

  /// Valores padrão para as configurações
  static final Map<String, dynamic> _defaults = {
    'max_cache_size_mb': 50,
    'max_cached_pages': 10,
    'default_expiration_hours': 24,
    'enable_analytics': true,
    'enable_crashlytics': true,
    'enable_performance': true,
    'enable_feedback': true,
    'maintenance_mode': false,
    'maintenance_message': 'O aplicativo está em manutenção. Tente novamente mais tarde.',
    'min_app_version': '1.0.0',
    'force_update': false,
    'update_message': 'Uma nova versão do aplicativo está disponível. Atualize para continuar.',
    'features': json.encode({
      'gamification': true,
      'mercado': true,
      'calendar_sync': false,
      'social_sharing': false,
      'cloud_backup': false,
    }),
  };

  /// Construtor
  LocalConfigService(this._logger, this._analyticsService) {
    _config = Map.from(_defaults);
    _init();
  }

  /// Inicializa o serviço
  Future<void> _init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Carregar configurações salvas
      final savedConfig = _prefs.getString(_prefsKey);
      if (savedConfig != null) {
        final Map<String, dynamic> parsed = json.decode(savedConfig);
        _config = {..._defaults, ...parsed};
      }
      
      _initialized = true;
      _logger.info('Serviço de configuração local inicializado', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao inicializar serviço de configuração local', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao inicializar LocalConfigService');
    }
  }

  /// Garante que o serviço está inicializado
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  /// Salva as configurações
  Future<void> _saveConfig() async {
    await _ensureInitialized();
    await _prefs.setString(_prefsKey, json.encode(_config));
  }

  /// Busca e ativa as configurações
  @override
  Future<bool> fetchAndActivate() async {
    try {
      await _ensureInitialized();
      _logger.debug('Configurações locais atualizadas', tag: _tag);
      return true;
    } catch (e) {
      _logger.error('Erro ao buscar configurações locais', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao buscar configurações locais');
      return false;
    }
  }

  /// Obtém um valor booleano
  @override
  bool getBool(String key) {
    try {
      return _config[key] as bool? ?? _defaults[key] as bool? ?? false;
    } catch (e) {
      _logger.error('Erro ao obter valor booleano: $key', tag: _tag, error: e);
      return _defaults[key] as bool? ?? false;
    }
  }

  /// Obtém um valor inteiro
  @override
  int getInt(String key) {
    try {
      return _config[key] as int? ?? _defaults[key] as int? ?? 0;
    } catch (e) {
      _logger.error('Erro ao obter valor inteiro: $key', tag: _tag, error: e);
      return _defaults[key] as int? ?? 0;
    }
  }

  /// Obtém um valor double
  @override
  double getDouble(String key) {
    try {
      return _config[key] as double? ?? _defaults[key] as double? ?? 0.0;
    } catch (e) {
      _logger.error('Erro ao obter valor double: $key', tag: _tag, error: e);
      return _defaults[key] as double? ?? 0.0;
    }
  }

  /// Obtém um valor string
  @override
  String getString(String key) {
    try {
      return _config[key] as String? ?? _defaults[key] as String? ?? '';
    } catch (e) {
      _logger.error('Erro ao obter valor string: $key', tag: _tag, error: e);
      return _defaults[key] as String? ?? '';
    }
  }

  /// Obtém um valor JSON
  @override
  Map<String, dynamic> getJson(String key) {
    try {
      final jsonString = _config[key] as String? ?? _defaults[key] as String? ?? '{}';
      return json.decode(jsonString);
    } catch (e) {
      _logger.error('Erro ao obter valor JSON: $key', tag: _tag, error: e);
      return {};
    }
  }

  /// Define um valor
  Future<void> setValue(String key, dynamic value) async {
    try {
      _config[key] = value;
      await _saveConfig();
      _logger.debug('Valor definido: $key = $value', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao definir valor: $key', tag: _tag, error: e);
    }
  }

  /// Verifica se o aplicativo está em modo de manutenção
  @override
  bool get isInMaintenanceMode => getBool('maintenance_mode');

  /// Obtém a mensagem de manutenção
  @override
  String get maintenanceMessage => getString('maintenance_message');

  /// Verifica se o aplicativo precisa ser atualizado
  @override
  bool get needsUpdate {
    try {
      final minVersion = getString('min_app_version');
      const currentVersion = '1.0.0'; // TODO: Obter versão atual do aplicativo

      return _compareVersions(currentVersion, minVersion) < 0;
    } catch (e) {
      _logger.error('Erro ao verificar necessidade de atualização', tag: _tag, error: e);
      return false; // Em caso de erro, não exigir atualização
    }
  }

  /// Compara duas versões semânticas
  /// Retorna um número negativo se a versão atual for menor que a versão mínima
  int _compareVersions(String current, String minimum) {
    final currentParts = current.split('.').map(int.parse).toList();
    final minimumParts = minimum.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final minimumPart = i < minimumParts.length ? minimumParts[i] : 0;

      if (currentPart != minimumPart) {
        return currentPart - minimumPart;
      }
    }

    return 0;
  }

  /// Verifica se a atualização é forçada
  @override
  bool get isForceUpdate => getBool('force_update');

  /// Obtém a mensagem de atualização
  @override
  String get updateMessage => getString('update_message');

  /// Verifica se uma feature está habilitada
  @override
  bool isFeatureEnabled(String featureName) {
    try {
      final features = getJson('features');
      return features[featureName] as bool? ?? false;
    } catch (e) {
      _logger.error('Erro ao verificar feature: $featureName', tag: _tag, error: e);
      return false;
    }
  }
}
