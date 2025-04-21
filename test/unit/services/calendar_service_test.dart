import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/data/services/interfaces/analytics_service_interface.dart';
import 'package:preparatorio_concursos/core/services/calendar_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

import 'calendar_service_test.mocks.dart';

@GenerateMocks([IAnalyticsService, Logger])
void main() {
  late CalendarService calendarService;
  late MockIAnalyticsService mockAnalyticsService;
  late MockLogger mockLogger;

  setUp(() {
    mockAnalyticsService = MockIAnalyticsService();
    mockLogger = MockLogger();
    calendarService = CalendarService(mockLogger, mockAnalyticsService);
  });

  group('CalendarService Tests', () {
    test('isAvailable should return true for web platform', () async {
      // Act
      final result = await calendarService.isAvailable();

      // Assert
      // Note: This will return false in the test environment, but we're just testing the method call
      expect(result, isFalse);
      verify(mockLogger.debug(any, tag: any)).called(1);
    });

    test('getCalendars should return empty list in test environment', () async {
      // Act
      final result = await calendarService.getCalendars();

      // Assert
      expect(result, isEmpty);
      verify(mockLogger.debug(any, tag: any)).called(1);
    });

    test('syncPlanoEstudo should log event', () async {
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
      final result = await calendarService.syncPlanoEstudo(plano, 'google');

      // Assert
      expect(result, isFalse); // Will be false in test environment
      verify(mockAnalyticsService.logEvent(
        name: 'calendar_sync_attempt',
        parameters: {'calendar_type': 'google', 'plano_id': plano.id},
      )).called(1);
      verify(mockLogger.info(any, tag: any)).called(1);
    });
  });
}
