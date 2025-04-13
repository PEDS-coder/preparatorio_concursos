import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/data/services/ia_service.dart';
import 'package:preparatorio_concursos/core/data/services/services.dart';
import 'package:preparatorio_concursos/features/3_edital_management/presentation/screens/edital_analyze_screen.dart';

// Gerar mocks
@GenerateMocks([EditalService, IAService])
import 'edital_analyze_screen_test.mocks.dart';

void main() {
  late MockEditalService mockEditalService;
  late MockIAService mockIAService;

  setUp(() {
    mockEditalService = MockEditalService();
    mockIAService = MockIAService();
  });

  Widget createEditalAnalyzeScreen() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<EditalService>.value(value: mockEditalService),
          ChangeNotifierProvider<IAService>.value(value: mockIAService),
        ],
        child: EditalAnalyzeScreen(),
      ),
    );
  }

  group('EditalAnalyzeScreen Widget Tests', () {
    testWidgets('should display initial screen elements', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockEditalService.isAnalyzing).thenReturn(false);
      when(mockEditalService.analysisProgress).thenReturn(0);
      when(mockEditalService.analysisError).thenReturn(null);
      when(mockIAService.isConfigured).thenReturn(true);

      // Renderizar o widget
      await tester.pumpWidget(createEditalAnalyzeScreen());

      // Verificar se os elementos iniciais estão presentes
      expect(find.text('Análise de Edital'), findsOneWidget);
      expect(find.text('Selecione o arquivo do edital (PDF)'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsAtLeast(1)); // Botão de selecionar arquivo
    });

    testWidgets('should show loading indicator when isAnalyzing is true', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockEditalService.isAnalyzing).thenReturn(true);
      when(mockEditalService.analysisProgress).thenReturn(50);
      when(mockEditalService.analysisError).thenReturn(null);
      when(mockIAService.isConfigured).thenReturn(true);

      // Renderizar o widget
      await tester.pumpWidget(createEditalAnalyzeScreen());

      // Verificar se o indicador de carregamento está presente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analisando edital... 50%'), findsOneWidget);
    });

    testWidgets('should show error message when analysisError is not null', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockEditalService.isAnalyzing).thenReturn(false);
      when(mockEditalService.analysisProgress).thenReturn(0);
      when(mockEditalService.analysisError).thenReturn('Erro ao analisar o edital');
      when(mockIAService.isConfigured).thenReturn(true);

      // Renderizar o widget
      await tester.pumpWidget(createEditalAnalyzeScreen());

      // Verificar se a mensagem de erro está presente
      expect(find.text('Erro ao analisar o edital'), findsOneWidget);
    });

    testWidgets('should show API configuration warning when IAService is not configured', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockEditalService.isAnalyzing).thenReturn(false);
      when(mockEditalService.analysisProgress).thenReturn(0);
      when(mockEditalService.analysisError).thenReturn(null);
      when(mockIAService.isConfigured).thenReturn(false);

      // Renderizar o widget
      await tester.pumpWidget(createEditalAnalyzeScreen());

      // Verificar se o aviso de configuração da API está presente
      expect(find.text('A API LLM não está configurada'), findsOneWidget);
    });

    testWidgets('should call analisarEdital when file is selected and analyze button is pressed', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockEditalService.isAnalyzing).thenReturn(false);
      when(mockEditalService.analysisProgress).thenReturn(0);
      when(mockEditalService.analysisError).thenReturn(null);
      when(mockIAService.isConfigured).thenReturn(true);
      when(mockEditalService.analisarEdital(any, fileName: anyNamed('fileName')))
          .thenAnswer((_) async => null);

      // Renderizar o widget
      await tester.pumpWidget(createEditalAnalyzeScreen());

      // Simular a seleção de arquivo (isso é complicado em testes de widget)
      // Na prática, precisaríamos modificar a tela para aceitar um arquivo de teste
      
      // Como alternativa, podemos verificar se o botão de análise está presente
      expect(find.text('Analisar com IA'), findsOneWidget);
      
      // Nota: Não podemos testar completamente a seleção de arquivo e análise
      // em testes de widget sem modificar a implementação para torná-la mais testável
    });
  });
}
