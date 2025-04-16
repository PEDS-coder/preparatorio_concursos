import 'package:preparatorio_concursos/core/data/services/interfaces/http_method.dart';

// Mock para Firebase
class FirebaseAnalytics {
  static FirebaseAnalytics get instance => FirebaseAnalytics();
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {}
  Future<void> setUserId({String? id}) async {}
  Future<void> logLogin({String? loginMethod}) async {}
  Future<void> logEvent({required String name, Map<String, dynamic>? parameters}) async {}
}

class FirebaseCrashlytics {
  static FirebaseCrashlytics get instance => FirebaseCrashlytics();
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {}
  Future<void> setUserIdentifier(String identifier) async {}
  Future<void> setCustomKey(String key, dynamic value) async {}
  Future<void> recordError(dynamic exception, StackTrace? stack, {String? reason, bool printDetails = false}) async {}
}

class FirebasePerformance {
  static FirebasePerformance get instance => FirebasePerformance();
  Future<void> setPerformanceCollectionEnabled(bool enabled) async {}
  Trace newTrace(String name) => Trace();
  HttpMetric newHttpMetric(String url, HttpMethod method) => HttpMetric();
}

class Trace {
  void start() {}
  Future<void> stop() async {}
}

class HttpMetric {
  void start() {}
  Future<void> stop() async {}
  int? httpResponseCode;
  int? responsePayloadSize;
}

enum HttpMethod { Get, Post, Put, Delete, Patch, Options, Head }

// Mock para Firebase Remote Config
class FirebaseRemoteConfig {
  static FirebaseRemoteConfig get instance => FirebaseRemoteConfig();
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {}
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}
  Future<bool> fetchAndActivate() async => true;
  bool getBool(String key) => false;
  int getInt(String key) => 0;
  double getDouble(String key) => 0.0;
  String getString(String key) => '';
}

class RemoteConfigSettings {
  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  
  const RemoteConfigSettings({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
  });
}
