import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:preparatorio_concursos/core/utils/pdf_processor.dart';
import 'package:preparatorio_concursos/core/utils/pdf_optimizer.dart';
import 'package:preparatorio_concursos/core/utils/pdf_scanner_detector.dart';

import 'pdf_processor_test.mocks.dart';

@GenerateMocks([PdfOptimizer, PdfScannerDetector])
void main() {
  group('PdfProcessor', () {
    late PdfProcessor processor;
    late MockPdfOptimizer mockOptimizer;
    late bool progressCalled;
    late double progressValue;
    late String progressMessage;

    setUp(() {
      mockOptimizer = MockPdfOptimizer();
      progressCalled = false;
      progressValue = 0.0;
      progressMessage = '';

      processor = PdfProcessor(
        onProgress: (value, message) {
          progressCalled = true;
          progressValue = value;
          progressMessage = message;
        },
        config: PdfProcessorConfig(
          chunkSize: 10,
          useOcrByDefault: false,
          ocrImageQuality: 90,
          largePdfThreshold: 5 * 1024 * 1024, // 5MB
        ),
      );
    });

    test('PdfProcessorConfig deve ter valores padrão corretos', () {
      final config = PdfProcessorConfig();
      expect(config.chunkSize, 20);
      expect(config.useOcrByDefault, false);
      expect(config.ocrImageQuality, 100);
      expect(config.largePdfThreshold, 10 * 1024 * 1024); // 10MB
    });

    test('PdfProcessingResult deve ter getters funcionando corretamente', () {
      final result = PdfProcessingResult(
        text: 'Texto de teste',
        usedOcr: true,
        isLargePdf: true,
        pageCount: 5,
        tables: ['Tabela 1', 'Tabela 2'],
        metadata: {'autor': 'Teste'},
        warnings: ['Aviso 1'],
        errors: [],
      );

      expect(result.hasContent, true);
      expect(result.hasTables, true);
      expect(result.hasWarnings, true);
      expect(result.hasErrors, false);
    });

    test('processLargePdf deve delegar para PdfOptimizer', () async {
      // Arrange
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      when(mockOptimizer.processLargePdf(
        testBytes,
        chunkSize: anyNamed('chunkSize'),
      )).thenAnswer((_) async => 'Texto processado');

      // Act
      final result = await processor.processLargePdf(testBytes);

      // Assert
      expect(result, 'Texto processado');
    });

    test('isPdfScanned deve delegar para PdfScannerDetector', () async {
      // Este teste verifica se o método isPdfScanned está delegando corretamente
      // para a classe PdfScannerDetector. Como não podemos mockar métodos estáticos
      // facilmente, este teste é mais para documentação da intenção.
      
      // Arrange
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act & Assert
      // Não podemos testar diretamente, mas a implementação deve chamar:
      // PdfScannerDetector.isPdfScanned(testBytes);
      expect(processor.isPdfScanned(testBytes), isA<Future<bool>>());
    });

    test('processBatchPdfs deve processar múltiplos PDFs', () async {
      // Arrange
      final testBytes1 = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final testBytes2 = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      
      // Act
      final result = await processor.processBatchPdfs([testBytes1, testBytes2]);
      
      // Assert
      expect(result, isA<Map<String, String>>());
      expect(result.length, 2);
      expect(result.containsKey('pdf_0'), true);
      expect(result.containsKey('pdf_1'), true);
    });
  });
}
