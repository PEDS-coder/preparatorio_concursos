import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/services/share_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

import 'share_service_test.mocks.dart';

@GenerateMocks([IAnalyticsService, Logger])
void main() {
  late ShareService shareService;
  late MockIAnalyticsService mockAnalyticsService;
  late MockLogger mockLogger;

  setUp(() {
    mockAnalyticsService = MockIAnalyticsService();
    mockLogger = MockLogger();
    shareService = ShareService(mockAnalyticsService, mockLogger);
  });

  group('ShareService Tests', () {
    test('shareText should return true when successful', () async {
      // Arrange
      const text = 'Test text to share';
      const subject = 'Test Subject';

      // Act
      final result = await shareService.shareText(text, subject: subject);

      // Assert
      expect(result, true);
      verify(mockAnalyticsService.logEvent(
        name: 'share',
        parameters: {'content_type': 'text', 'subject': subject},
      )).called(1);
      verify(mockLogger.info(any, tag: any)).called(1);
    });

    test('shareFile should return true when successful', () async {
      // Arrange
      const filePath = 'test/assets/test_file.txt';
      const text = 'Test text to share with file';
      const subject = 'Test File Subject';

      // Act
      final result = await shareService.shareFile(filePath, text: text, subject: subject);

      // Assert
      expect(result, true);
      verify(mockAnalyticsService.logEvent(
        name: 'share',
        parameters: {'content_type': 'file', 'subject': subject},
      )).called(1);
      verify(mockLogger.info(any, tag: any)).called(1);
    });

    test('sharePlanoEstudo should return true when successful', () async {
      // Arrange
      final plano = PlanoEstudo(
        id: 'test_id',
        userId: 'user_id',
        editalId: 'edital_id',
        cargoIds: ['cargo_id'],
        dataCriacao: DateTime.now(),
        dataInicio: DateTime.now(),
        dataFim: DateTime.now().add(const Duration(days: 30)),
        horasSemanais: {'segunda': 2, 'terca': 2, 'quarta': 2, 'quinta': 2, 'sexta': 2, 'sabado': 1, 'domingo': 1},
        horariosEspecificos: null,
        ferramentas: ['Resumos', 'Flashcards'],
        materiasProficiencia: [],
        recompensas: [],
        sessoesEstudo: [],
        metadados: {'titulo': 'Test Plano', 'materias': []},
      );

      // Act
      final result = await shareService.sharePlanoEstudo(plano);

      // Assert
      expect(result, true);
      verify(mockAnalyticsService.logEvent(
        name: 'share',
        parameters: {'content_type': 'plano_estudo', 'plano_id': plano.id},
      )).called(1);
      verify(mockLogger.info(any, tag: any)).called(1);
    });
  });
}
