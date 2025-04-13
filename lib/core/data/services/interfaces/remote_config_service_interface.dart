/// Interface para o serviço de configuração remota
abstract class IRemoteConfigService {
  /// Busca e ativa as configurações remotas
  Future<bool> fetchAndActivate();
  
  /// Obtém um valor booleano
  bool getBool(String key);
  
  /// Obtém um valor inteiro
  int getInt(String key);
  
  /// Obtém um valor double
  double getDouble(String key);
  
  /// Obtém um valor string
  String getString(String key);
  
  /// Obtém um valor JSON
  Map<String, dynamic> getJson(String key);
  
  /// Verifica se o aplicativo está em modo de manutenção
  bool get isInMaintenanceMode;
  
  /// Obtém a mensagem de manutenção
  String get maintenanceMessage;
  
  /// Verifica se o aplicativo precisa ser atualizado
  bool get needsUpdate;
  
  /// Verifica se a atualização é forçada
  bool get isForceUpdate;
  
  /// Obtém a mensagem de atualização
  String get updateMessage;
  
  /// Verifica se uma feature está habilitada
  bool isFeatureEnabled(String featureName);
}
