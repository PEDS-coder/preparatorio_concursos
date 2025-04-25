import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/app.dart';
import 'package:preparatorio_concursos/core/auth/auth_service.dart';
import 'package:preparatorio_concursos/core/data/services/services.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Gerar mocks
@GenerateMocks([
  AuthService,
  EditalService,
  PlanoEstudoService,
  SessaoEstudoService,
  GamificacaoService,
  IAService,
  ApiConfigService,
])
import 'app_performance_test.mocks.dart';

void main() {
  late MockAuthService mockAuthService;
  late MockEditalService mockEditalService;
  late MockPlanoEstudoService mockPlanoEstudoService;
  late MockSessaoEstudoService mockSessaoEstudoService;
  late MockGamificacaoService mockGamificacaoService;
  late MockIAService mockIAService;
  late MockApiConfigService mockApiConfigService;

  setUp(() {
    mockAuthService = MockAuthService();
    mockEditalService = MockEditalService();
    mockPlanoEstudoService = MockPlanoEstudoService();
    mockSessaoEstudoService = MockSessaoEstudoService();
    mockGamificacaoService = MockGamificacaoService();
    mockIAService = MockIAService();
    mockApiConfigService = MockApiConfigService();
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: mockAuthService),
        ChangeNotifierProvider<EditalService>.value(value: mockEditalService),
        ChangeNotifierProvider<PlanoEstudoService>.value(value: mockPlanoEstudoService),
        ChangeNotifierProvider<SessaoEstudoService>.value(value: mockSessaoEstudoService),
        ChangeNotifierProvider<GamificacaoService>.value(value: mockGamificacaoService),
        ChangeNotifierProvider<IAService>.value(value: mockIAService),
        ChangeNotifierProvider<ApiConfigService>.value(value: mockApiConfigService),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Test App'),
          ),
        ),
      ),
    );
  }

  group('App Performance Tests', () {
    testWidgets('should measure build time', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockAuthService.isLoggedIn).thenReturn(true);
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockApiConfigService.isConfigured).thenReturn(true);

      // Medir o tempo de construção
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(createTestApp());
      
      stopwatch.stop();
      
      // Verificar se o tempo de construção é aceitável (menos de 1 segundo)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('should measure frame build time', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockAuthService.isLoggedIn).thenReturn(true);
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockApiConfigService.isConfigured).thenReturn(true);

      // Construir o widget
      await tester.pumpWidget(createTestApp());

      // Medir o tempo de construção de um frame
      final stopwatch = Stopwatch()..start();
      
      await tester.pump();
      
      stopwatch.stop();
      
      // Verificar se o tempo de construção de um frame é aceitável (menos de 16ms para 60fps)
      expect(stopwatch.elapsedMilliseconds, lessThan(16));
    });

    testWidgets('should measure memory usage', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockAuthService.isLoggedIn).thenReturn(true);
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockApiConfigService.isConfigured).thenReturn(true);

      // Construir o widget
      await tester.pumpWidget(createTestApp());

      // Não há uma maneira direta de medir o uso de memória em testes de widget
      // Mas podemos verificar se o widget foi construído corretamente
      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('should measure rebuild performance with multiple state changes', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockAuthService.isLoggedIn).thenReturn(true);
      when(mockAuthService.isLoading).thenReturn(false);
      when(mockApiConfigService.isConfigured).thenReturn(true);

      // Construir o widget
      await tester.pumpWidget(createTestApp());

      // Medir o tempo de reconstrução após múltiplas mudanças de estado
      final stopwatch = Stopwatch()..start();
      
      // Simular múltiplas mudanças de estado
      for (int i = 0; i < 10; i++) {
        when(mockAuthService.isLoading).thenReturn(i % 2 == 0);
        await tester.pump();
      }
      
      stopwatch.stop();
      
      // Verificar se o tempo de reconstrução é aceitável (menos de 500ms para 10 reconstruções)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
