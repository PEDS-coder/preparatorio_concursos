import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/utils/pdf_parallel_processor.dart';

void main() {
  group('PdfParallelProcessor', () {
    late PdfParallelProcessor processor;
    late bool progressCalled;
    late double progressValue;
    late String progressMessage;

    setUp(() {
      progressCalled = false;
      progressValue = 0.0;
      progressMessage = '';

      processor = PdfParallelProcessor(
        onProgress: (value, message) {
          progressCalled = true;
          progressValue = value;
          progressMessage = message;
        },
      );
    });

    test('Pool deve limitar operações concorrentes', () async {
      // Arrange
      final pool = Pool(2);
      int concurrentCount = 0;
      int maxConcurrent = 0;
      
      // Act
      final futures = List.generate(5, (index) {
        return pool.withResource(() async {
          concurrentCount++;
          if (concurrentCount > maxConcurrent) {
            maxConcurrent = concurrentCount;
          }
          
          // Simular trabalho
          await Future.delayed(Duration(milliseconds: 50));
          
          concurrentCount--;
          return index;
        });
      });
      
      final results = await Future.wait(futures);
      
      // Assert
      expect(maxConcurrent, 2); // Nunca deve exceder o limite do pool
      expect(results, [0, 1, 2, 3, 4]); // Todos os trabalhos devem ser concluídos
    });

    // Nota: Testes mais completos para processPdfsInParallel exigiriam
    // mocks para PdfDocument e outros componentes, o que está além
    // do escopo deste teste básico.
    
    test('processPdfsInParallel deve retornar uma lista de strings', () async {
      // Arrange
      final testBytes1 = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      final testBytes2 = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      
      // Act
      final result = await processor.processPdfsInParallel(
        [testBytes1, testBytes2],
        maxConcurrent: 1, // Usar apenas 1 para simplificar o teste
      );
      
      // Assert
      expect(result, isA<List<String>>());
      expect(result.length, 2);
    });
  });
}
