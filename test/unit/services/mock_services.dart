import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:preparatorio_concursos/core/services/cache_service.dart';

// Mock para o cliente HTTP
class MockClient extends Mock implements http.Client {
  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    return super.noSuchMethod(
      Invocation.method(#post, [url], {#headers: headers, #body: body, #encoding: encoding}),
      returnValue: Future.value(http.Response('{"candidates":[{"content":{"parts":[{"text":"Mock response"}]}}]}', 200)),
    );
  }
}

// Mock para o serviço de cache
class MockCacheService extends Mock implements CacheService {
  @override
  Future<void> init() {
    return super.noSuchMethod(
      Invocation.method(#init, []),
      returnValue: Future.value(),
    );
  }

  @override
  Future<String?> getFromCache(String key, List<int> dataBytes) {
    return super.noSuchMethod(
      Invocation.method(#getFromCache, [key, dataBytes]),
      returnValue: Future.value(null),
    );
  }

  @override
  Future<bool> saveToCache(String key, List<int> dataBytes, String value) {
    return super.noSuchMethod(
      Invocation.method(#saveToCache, [key, dataBytes, value]),
      returnValue: Future.value(true),
    );
  }
}

// Mock para o serviço de conectividade
class MockConnectivityService {
  static Future<bool> isConnected() async {
    return true;
  }
}
