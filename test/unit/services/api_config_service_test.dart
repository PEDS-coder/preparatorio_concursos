import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/secure_storage_service_interface.dart';
import 'package:preparatorio_concursos/core/services/api_config_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

import 'api_config_service_test.mocks.dart';

@GenerateMocks([ISecureStorageService, Logger])
void main() {
  late ApiConfigService apiConfigService;
  late MockISecureStorageService mockSecureStorage;
  late MockLogger mockLogger;

  setUp(() {
    mockSecureStorage = MockISecureStorageService();
    mockLogger = MockLogger();
    apiConfigService = ApiConfigService(mockSecureStorage, mockLogger);
  });

  group('ApiConfigService Tests', () {
    test('setApiKey should store key in secure storage', () async {
      // Arrange
      const apiKey = 'test_api_key';
      const apiType = 'gemini';
      when(mockSecureStorage.write(key: any, value: any)).thenAnswer((_) async => true);

      // Act
      final result = await apiConfigService.setApiKey(apiKey, apiType);

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['success'], isTrue);
      verify(mockSecureStorage.write(key: 'api_key', value: apiKey)).called(1);
      verify(mockSecureStorage.write(key: 'api_type', value: apiType)).called(1);
      verify(mockLogger.info(any, tag: any)).called(1);
    });

    test('getApiKey should retrieve key from secure storage', () async {
      // Arrange
      const apiKey = 'test_api_key';
      when(mockSecureStorage.read(key: 'api_key')).thenAnswer((_) async => apiKey);

      // Act
      final result = await apiConfigService.getApiKey();

      // Assert
      expect(result, equals(apiKey));
      verify(mockSecureStorage.read(key: 'api_key')).called(1);
    });

    test('getApiType should retrieve type from secure storage', () async {
      // Arrange
      const apiType = 'gemini';
      when(mockSecureStorage.read(key: 'api_type')).thenAnswer((_) async => apiType);

      // Act
      final result = await apiConfigService.getApiType();

      // Assert
      expect(result, equals(apiType));
      verify(mockSecureStorage.read(key: 'api_type')).called(1);
    });

    test('clearApiConfig should remove keys from secure storage', () async {
      // Arrange
      when(mockSecureStorage.delete(key: any)).thenAnswer((_) async => true);

      // Act
      final result = await apiConfigService.clearApiConfig();

      // Assert
      expect(result, isTrue);
      verify(mockSecureStorage.delete(key: 'api_key')).called(1);
      verify(mockSecureStorage.delete(key: 'api_type')).called(1);
      verify(mockLogger.info(any, tag: any)).called(1);
    });

    test('isConfigured should return true when API key exists', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'api_key')).thenAnswer((_) async => 'test_api_key');

      // Act
      final result = await apiConfigService.isConfigured();

      // Assert
      expect(result, isTrue);
      verify(mockSecureStorage.read(key: 'api_key')).called(1);
    });

    test('isConfigured should return false when API key does not exist', () async {
      // Arrange
      when(mockSecureStorage.read(key: 'api_key')).thenAnswer((_) async => null);

      // Act
      final result = await apiConfigService.isConfigured();

      // Assert
      expect(result, isFalse);
      verify(mockSecureStorage.read(key: 'api_key')).called(1);
    });
  });
}
