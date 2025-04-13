import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

void main() {
  group('Logger', () {
    late Logger logger;

    setUp(() {
      logger = Logger();
    });

    test('deve inicializar com nível de log padrão', () {
      expect(logger.currentLogLevel, LogLevel.info);
    });

    test('deve alterar o nível de log corretamente', () {
      // Act
      logger.setLogLevel(LogLevel.warning);
      
      // Assert
      expect(logger.currentLogLevel, LogLevel.warning);
    });

    test('deve registrar logs com base no nível atual', () {
      // Arrange
      logger.setLogLevel(LogLevel.warning);
      
      // Act
      logger.verbose('Mensagem verbose');
      logger.debug('Mensagem debug');
      logger.info('Mensagem info');
      logger.warning('Mensagem warning');
      logger.error('Mensagem error');
      
      // Assert
      final logs = logger.recentLogs;
      
      // Apenas warning e error devem ser registrados
      expect(logs.length, 2);
      expect(logs[0].level, LogLevel.warning);
      expect(logs[0].message, 'Mensagem warning');
      expect(logs[1].level, LogLevel.error);
      expect(logs[1].message, 'Mensagem error');
    });

    test('deve registrar logs com tags e dados adicionais', () {
      // Arrange
      logger.setLogLevel(LogLevel.debug);
      
      // Act
      logger.debug(
        'Mensagem de teste',
        tag: 'TEST_TAG',
        data: {'key': 'value', 'number': 123},
      );
      
      // Assert
      final logs = logger.recentLogs;
      expect(logs.length, 1);
      expect(logs[0].tag, 'TEST_TAG');
      expect(logs[0].data, {'key': 'value', 'number': 123});
    });

    test('deve registrar erros com stack trace', () {
      // Arrange
      final error = Exception('Erro de teste');
      final stackTrace = StackTrace.current;
      
      // Act
      logger.error(
        'Erro ocorreu',
        tag: 'ERROR_TAG',
        error: error,
        stackTrace: stackTrace,
      );
      
      // Assert
      final logs = logger.recentLogs;
      expect(logs.length, 1);
      expect(logs[0].error, error);
      expect(logs[0].stackTrace, stackTrace);
    });

    test('deve limitar o número de logs recentes', () {
      // Arrange
      logger.setLogLevel(LogLevel.verbose);
      
      // Act - gerar mais logs do que o limite
      for (int i = 0; i < 200; i++) {
        logger.info('Log $i');
      }
      
      // Assert
      expect(logger.recentLogs.length, 100); // Limite padrão
      expect(logger.recentLogs.first.message, 'Log 100'); // Logs mais antigos são removidos
    });
  });
}
