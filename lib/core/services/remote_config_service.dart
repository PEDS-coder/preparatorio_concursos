import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/remote_config_service_interface.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

/// Serviço para gerenciar configurações remotas
@singleton
class RemoteConfigService implements IRemoteConfigService {
  static const String _tag = 'RemoteConfigService';

  final Logger _logger;
  final IAnalyticsService _analyticsService;
  late final FirebaseRemoteConfig _remoteConfig;

  /// Valores padrão para as configurações remotas
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
  RemoteConfigService(this._logger, this._analyticsService) {
    _init();
  }

  /// Inicializa o serviço
  Future<void> _init() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Configurar o Remote Config
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: kDebugMode
            ? const Duration(minutes: 5)
            : const Duration(hours: 12),
      ));

      // Definir valores padrão
      await _remoteConfig.setDefaults(_defaults);

      // Buscar valores remotos
      await fetchAndActivate();

      _logger.info('Serviço de configuração remota inicializado', tag: _tag);
    } catch (e) {
      _logger.error('Erro ao inicializar serviço de configuração remota', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao inicializar RemoteConfigService');
    }
  }

  /// Busca e ativa as configurações remotas
  Future<bool> fetchAndActivate() async {
    try {
      final trace = _analyticsService.startTrace('remote_config_fetch');

      // Buscar configurações remotas
      await _remoteConfig.fetchAndActivate();

      _analyticsService.stopTrace(trace);
      _logger.debug('Configurações remotas atualizadas', tag: _tag);

      return true;
    } catch (e) {
      _logger.error('Erro ao buscar configurações remotas', tag: _tag, error: e);
      _analyticsService.recordError(e, StackTrace.current, reason: 'Erro ao buscar configurações remotas');
      return false;
    }
  }

  /// Obtém um valor booleano
  bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      _logger.error('Erro ao obter valor booleano: $key', tag: _tag, error: e);
      return _defaults[key] as bool? ?? false;
    }
  }

  /// Obtém um valor inteiro
  int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      _logger.error('Erro ao obter valor inteiro: $key', tag: _tag, error: e);
      return _defaults[key] as int? ?? 0;
    }
  }

  /// Obtém um valor double
  double getDouble(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      _logger.error('Erro ao obter valor double: $key', tag: _tag, error: e);
      return _defaults[key] as double? ?? 0.0;
    }
  }

  /// Obtém um valor string
  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      _logger.error('Erro ao obter valor string: $key', tag: _tag, error: e);
      return _defaults[key] as String? ?? '';
    }
  }

  /// Obtém um valor JSON
  Map<String, dynamic> getJson(String key) {
    try {
      final jsonString = _remoteConfig.getString(key);
      if (jsonString.isEmpty) {
        return _defaults[key] != null
            ? json.decode(_defaults[key] as String)
            : {};
      }
      return json.decode(jsonString);
    } catch (e) {
      _logger.error('Erro ao obter valor JSON: $key', tag: _tag, error: e);
      return {};
    }
  }

  /// Verifica se o aplicativo está em modo de manutenção
  bool get isInMaintenanceMode => getBool('maintenance_mode');

  /// Obtém a mensagem de manutenção
  String get maintenanceMessage => getString('maintenance_message');

  /// Verifica se o aplicativo precisa ser atualizado
  bool get needsUpdate {
    final minVersion = getString('min_app_version');
    final currentVersion = '1.0.0'; // TODO: Obter versão atual do aplicativo

    return _compareVersions(currentVersion, minVersion) < 0;
  }

  /// Verifica se a atualização é forçada
  bool get isForceUpdate => getBool('force_update');

  /// Obtém a mensagem de atualização
  String get updateMessage => getString('update_message');

  /// Verifica se uma feature está habilitada
  bool isFeatureEnabled(String featureName) {
    try {
      final features = getJson('features');
      return features[featureName] as bool? ?? false;
    } catch (e) {
      _logger.error('Erro ao verificar feature: $featureName', tag: _tag, error: e);
      return false;
    }
  }

  /// Compara duas versões
  int _compareVersions(String version1, String version2) {
    final v1 = version1.split('.');
    final v2 = version2.split('.');

    for (var i = 0; i < v1.length && i < v2.length; i++) {
      final num1 = int.parse(v1[i]);
      final num2 = int.parse(v2[i]);

      if (num1 < num2) {
        return -1;
      } else if (num1 > num2) {
        return 1;
      }
    }

    return v1.length.compareTo(v2.length);
  }
}
