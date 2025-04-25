import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/exceptions/app_exception.dart';
import 'package:preparatorio_concursos/core/services/error_handler_service.dart';
import 'package:preparatorio_concursos/core/utils/logger.dart';

import '../../mocks/mock_logger.dart';

void main() {
  group('ErrorHandlerService', () {
    late MockLogger mockLogger;
    late ErrorHandlerService errorHandler;

    setUp(() {
      mockLogger = MockLogger();
      errorHandler = ErrorHandlerService(mockLogger);
    });

    test('convertToAppException deve converter Exception para AppException', () {
      // Arrange
      final exception = Exception('Teste de exceção');
      
      // Act
      final result = errorHandler.convertToAppException(exception);
      
      // Assert
      expect(result, isA<UnknownException>());
      expect(result.message, 'Ocorreu um erro inesperado.');
      expect(result.details, exception.toString());
    });

    test('convertToAppException deve manter AppException inalterada', () {
      // Arrange
      final appException = NetworkException('Erro de rede', code: 'TEST_CODE');
      
      // Act
      final result = errorHandler.convertToAppException(appException);
      
      // Assert
      expect(result, same(appException));
      expect(result.message, 'Erro de rede');
      expect(result.code, 'TEST_CODE');
    });

    test('convertToAppException deve converter FormatException para DataProcessingException', () {
      // Arrange
      const formatException = FormatException('Formato inválido');
      
      // Act
      final result = errorHandler.convertToAppException(formatException);
      
      // Assert
      expect(result, isA<DataProcessingException>());
      expect(result.message, 'Erro ao processar dados. Formato inválido.');
    });

    test('logException deve registrar exceções com o nível apropriado', () async {
      // Arrange
      final networkException = NetworkException('Erro de rede');
      final validationException = ValidationException('Erro de validação');
      final authException = AuthException('Erro de autenticação');
      final apiException = ApiException('Erro de API', statusCode: 500);
      final unknownException = UnknownException('Erro desconhecido');
      
      // Act
      errorHandler.logException(networkException);
      errorHandler.logException(validationException);
      errorHandler.logException(authException);
      errorHandler.logException(apiException);
      errorHandler.logException(unknownException);
      
      // Assert
      expect(mockLogger.warningCalls, 3); // network, auth, api (não 500)
      expect(mockLogger.infoCalls, 1); // validation
      expect(mockLogger.errorCalls, 2); // api (500), unknown
    });

    test('_getUserFriendlyMessage deve retornar mensagens amigáveis para diferentes exceções', () {
      // Arrange & Act
      final networkMessage = errorHandler._getUserFriendlyMessage(
        NetworkException('Erro técnico que o usuário não precisa ver')
      );
      
      final validationMessage = errorHandler._getUserFriendlyMessage(
        ValidationException('Este campo é obrigatório')
      );
      
      final apiMessage = errorHandler._getUserFriendlyMessage(
        ApiException('Erro técnico da API', statusCode: 500)
      );
      
      final notFoundMessage = errorHandler._getUserFriendlyMessage(
        ApiException('Recurso não encontrado', statusCode: 404)
      );
      
      final authMessage = errorHandler._getUserFriendlyMessage(
        ApiException('Não autorizado', statusCode: 401)
      );
      
      // Assert
      expect(networkMessage, 'Erro de conexão. Verifique sua internet e tente novamente.');
      expect(validationMessage, 'Este campo é obrigatório'); // Mensagem original mantida
      expect(apiMessage, 'O servidor está com problemas. Tente novamente mais tarde.');
      expect(notFoundMessage, 'O recurso solicitado não foi encontrado.');
      expect(authMessage, 'Você não tem permissão para acessar este recurso.');
    });

    test('runWithErrorHandling deve capturar e processar exceções', () async {
      // Arrange
      bool functionCalled = false;
      bool errorHandled = false;
      
      // Act & Assert
      try {
        await runWithErrorHandling<void>(
          () async {
            functionCalled = true;
            throw NetworkException('Erro de rede');
          },
          errorHandler,
          context: 'Teste',
        );
      } catch (e) {
        errorHandled = true;
        expect(e, isA<NetworkException>());
      }
      
      expect(functionCalled, true);
      expect(errorHandled, true);
      expect(mockLogger.warningCalls, 1);
    });
  });
}
