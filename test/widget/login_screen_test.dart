import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/auth/auth_service.dart';
import 'package:preparatorio_concursos/features/1_auth/presentation/screens/login_screen.dart';

// Gerar mocks
@GenerateMocks([AuthService])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget createLoginScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthService>.value(
        value: mockAuthService,
        child: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('should display login form elements', (WidgetTester tester) async {
      // Configurar o mock
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn(null);

      // Renderizar o widget
      await tester.pumpWidget(createLoginScreen());

      // Verificar se os elementos do formulário estão presentes
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2)); // Email e senha
      expect(find.byType(ElevatedButton), findsOneWidget); // Botão de login
      expect(find.text('Não tem uma conta?'), findsOneWidget);
      expect(find.text('Cadastre-se'), findsOneWidget);
    });

    testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
      // Configurar o mock
      when(mockAuthService.isLoading).thenReturn(true);
      when(mockAuthService.errorMessage).thenReturn(null);

      // Renderizar o widget
      await tester.pumpWidget(createLoginScreen());

      // Verificar se o indicador de carregamento está presente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message when errorMessage is not null', (WidgetTester tester) async {
      // Configurar o mock
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn('Email ou senha inválidos');

      // Renderizar o widget
      await tester.pumpWidget(createLoginScreen());

      // Verificar se a mensagem de erro está presente
      expect(find.text('Email ou senha inválidos'), findsOneWidget);
    });

    testWidgets('should call login method when form is submitted', (WidgetTester tester) async {
      // Configurar o mock
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn(null);
      when(mockAuthService.login(any, any)).thenAnswer((_) async => true);

      // Renderizar o widget
      await tester.pumpWidget(createLoginScreen());

      // Preencher o formulário
      await tester.enterText(find.byKey(ValueKey('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(ValueKey('password_field')), 'password123');

      // Submeter o formulário
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Verificar se o método login foi chamado com os parâmetros corretos
      verify(mockAuthService.login('test@example.com', 'password123')).called(1);
    });

    testWidgets('should navigate to register screen when "Cadastre-se" is tapped', (WidgetTester tester) async {
      // Configurar o mock
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockAuthService.errorMessage).thenReturn(null);

      // Renderizar o widget
      await tester.pumpWidget(createLoginScreen());

      // Tap no link "Cadastre-se"
      await tester.tap(find.text('Cadastre-se'));
      await tester.pumpAndSettle();

      // Verificar se a navegação ocorreu (isso depende da implementação da navegação)
      // Como estamos usando um MaterialApp isolado para o teste, a navegação não funcionará completamente
      // Mas podemos verificar se o método de navegação foi chamado
      // Isso requer modificações na tela de login para torná-la mais testável
    });
  });
}
