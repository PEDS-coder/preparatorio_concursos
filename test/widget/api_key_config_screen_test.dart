import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/services/api_config_service.dart';
import 'package:preparatorio_concursos/features/1_auth/presentation/screens/api_key_config_screen.dart';

// Gerar mocks
@GenerateMocks([ApiConfigService])
import 'api_key_config_screen_test.mocks.dart';

void main() {
  late MockApiConfigService mockApiConfigService;

  setUp(() {
    mockApiConfigService = MockApiConfigService();
  });

  Widget createApiKeyConfigScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider<ApiConfigService>.value(
        value: mockApiConfigService,
        child: ApiKeyConfigScreen(),
      ),
    );
  }

  group('ApiKeyConfigScreen Widget Tests', () {
    testWidgets('should display API key configuration form elements', (WidgetTester tester) async {
      // Configurar o mock
      when(mockApiConfigService.isVerifyingConfig).thenReturn(false);
      when(mockApiConfigService.configErrorMessage).thenReturn(null);
      when(mockApiConfigService.isConfigured).thenReturn(false);

      // Renderizar o widget
      await tester.pumpWidget(createApiKeyConfigScreen());

      // Verificar se os elementos do formulário estão presentes
      expect(find.text('Configuração da API'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(1)); // Campo de chave API
      expect(find.byType(ElevatedButton), findsOneWidget); // Botão de salvar
      expect(find.text('Como Gerar Uma Chave API'), findsOneWidget);
    });

    testWidgets('should show loading indicator when isVerifyingConfig is true', (WidgetTester tester) async {
      // Configurar o mock
      when(mockApiConfigService.isVerifyingConfig).thenReturn(true);
      when(mockApiConfigService.configErrorMessage).thenReturn(null);
      when(mockApiConfigService.isConfigured).thenReturn(false);

      // Renderizar o widget
      await tester.pumpWidget(createApiKeyConfigScreen());

      // Verificar se o indicador de carregamento está presente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when configErrorMessage is not null', (WidgetTester tester) async {
      // Configurar o mock
      when(mockApiConfigService.isVerifyingConfig).thenReturn(false);
      when(mockApiConfigService.configErrorMessage).thenReturn('Chave API inválida');
      when(mockApiConfigService.isConfigured).thenReturn(false);

      // Renderizar o widget
      await tester.pumpWidget(createApiKeyConfigScreen());

      // Verificar se a mensagem de erro está presente
      expect(find.text('Chave API inválida'), findsOneWidget);
    });

    testWidgets('should call verificarConfiguracao when form is submitted', (WidgetTester tester) async {
      // Configurar o mock
      when(mockApiConfigService.isVerifyingConfig).thenReturn(false);
      when(mockApiConfigService.configErrorMessage).thenReturn(null);
      when(mockApiConfigService.isConfigured).thenReturn(false);
      when(mockApiConfigService.verificarConfiguracao()).thenAnswer((_) async => true);

      // Renderizar o widget
      await tester.pumpWidget(createApiKeyConfigScreen());

      // Preencher o formulário
      await tester.enterText(find.byKey(ValueKey('api_key_field')), 'test_api_key');

      // Submeter o formulário
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verificar se o método verificarConfiguracao foi chamado
      verify(mockApiConfigService.verificarConfiguracao()).called(1);
    });

    testWidgets('should show success message when API key is configured', (WidgetTester tester) async {
      // Configurar o mock
      when(mockApiConfigService.isVerifyingConfig).thenReturn(false);
      when(mockApiConfigService.configErrorMessage).thenReturn(null);
      when(mockApiConfigService.isConfigured).thenReturn(true);

      // Renderizar o widget
      await tester.pumpWidget(createApiKeyConfigScreen());

      // Verificar se a mensagem de sucesso está presente
      expect(find.text('API configurada com sucesso!'), findsOneWidget);
    });
  });
}
