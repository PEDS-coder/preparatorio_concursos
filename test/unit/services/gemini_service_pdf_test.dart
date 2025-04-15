import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:preparatorio_concursos/core/data/services/gemini_service.dart';
import 'package:preparatorio_concursos/core/services/cache_service.dart';
import 'package:preparatorio_concursos/core/services/connectivity_service.dart';

// Importar os mocks manuais
import 'mock_services.dart';
void main() {
  group('GeminiService - processarPdf', () {
    late GeminiService geminiService;
    late MockClient mockClient;
    late MockCacheService mockCacheService;

    setUp(() {
      mockClient = MockClient();
      mockCacheService = MockCacheService();

      // Injetar os mocks no construtor
      geminiService = GeminiService(
        httpClient: mockClient,
        cacheService: mockCacheService
      );
    });

    test('processarPdf deve chamar callGeminiApiWithPdf com os parâmetros corretos', () async {
      // Arrange
      final Uint8List pdfBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      const String prompt = 'Test prompt';
      const String expectedResult = 'Test result';

      // Configurar o mock para retornar um resultado de cache
      when(mockCacheService.getFromCache(any, any)).thenAnswer((_) async => null);
      when(mockCacheService.saveToCache(any, any, any)).thenAnswer((_) async => true);
      when(mockCacheService.init()).thenAnswer((_) async => null);

      // Configurar o mock para retornar uma resposta HTTP válida
      when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
          .thenAnswer((_) async => http.Response(
                '{"candidates":[{"content":{"parts":[{"text":"$expectedResult"}]}}]}',
                200,
              ));

      // Act
      // Configurar a API key
      await geminiService.setApiKey('test_api_key', 'gemini');

      // Chamar o método
      final result = await geminiService.processarPdf(prompt, pdfBytes);

      // Assert
      expect(result, contains(expectedResult));

      // Verificar se o método post foi chamado com os parâmetros corretos
      verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body')
      )).called(greaterThan(0));

      // Verificar se o cache foi consultado
      verify(mockCacheService.getFromCache(any, any)).called(1);

      // Verificar se o resultado foi salvo no cache
      verify(mockCacheService.saveToCache(any, any, any)).called(1);
    });

    test('processarPdf deve lançar exceção quando a API key não está configurada', () async {
      // Arrange
      final Uint8List pdfBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      const String prompt = 'Test prompt';

      // Act & Assert
      expect(() => geminiService.processarPdf(prompt, pdfBytes),
             throwsA(isA<Exception>().having(
               (e) => e.toString(),
               'message',
               contains('API Key não configurada')
             )));
    });

    test('processarPdf deve lançar exceção quando o PDF é muito grande', () async {
      // Arrange
      // Criar um PDF "grande" (na verdade, apenas um array grande)
      final Uint8List pdfBytes = Uint8List(21 * 1024 * 1024); // 21 MB
      const String prompt = 'Test prompt';

      // Configurar mocks
      when(mockCacheService.getFromCache(any, any)).thenAnswer((_) async => null);
      when(mockCacheService.init()).thenAnswer((_) async => null);

      // Configurar conectividade
      // Nota: Precisamos de um mock para ConnectivityService ou uma forma de injetá-lo

      // Act & Assert
      await geminiService.setApiKey('test_api_key', 'gemini');

      expect(() => geminiService.processarPdf(prompt, pdfBytes),
             throwsA(isA<Exception>().having(
               (e) => e.toString(),
               'message',
               contains('PDF muito grande')
             )));
    });
  });
}
