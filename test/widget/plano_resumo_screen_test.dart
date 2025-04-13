import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/data/models/plano_estudo.dart';
import 'package:preparatorio_concursos/core/data/models/materia.dart';
import 'package:preparatorio_concursos/core/data/services/services.dart';
import 'package:preparatorio_concursos/features/4_study_plan/presentation/screens/plano_resumo_screen.dart';

// Gerar mocks
@GenerateMocks([PlanoEstudoService, EditalService])
import 'plano_resumo_screen_test.mocks.dart';

void main() {
  late MockPlanoEstudoService mockPlanoEstudoService;
  late MockEditalService mockEditalService;
  late PlanoEstudo mockPlano;

  setUp(() {
    mockPlanoEstudoService = MockPlanoEstudoService();
    mockEditalService = MockEditalService();
    
    // Criar um plano de estudo de teste
    mockPlano = PlanoEstudo(
      id: 'plano_id',
      titulo: 'Plano de Estudo de Teste',
      editalId: 'edital_id',
      cargoIds: ['cargo_id'],
      dataInicio: DateTime.now(),
      dataFim: DateTime.now().add(Duration(days: 90)),
      materias: [
        Materia(
          id: 'materia1',
          nome: 'Português',
          tipo: 'Conhecimentos Básicos',
          assuntos: [
            {'id': 'assunto1', 'nome': 'Interpretação de Texto'},
            {'id': 'assunto2', 'nome': 'Gramática'},
          ],
          prioridade: 5,
          diasEstudo: ['Segunda', 'Quarta'],
          questoes: 20,
        ),
        Materia(
          id: 'materia2',
          nome: 'Matemática',
          tipo: 'Conhecimentos Básicos',
          assuntos: [
            {'id': 'assunto3', 'nome': 'Álgebra'},
            {'id': 'assunto4', 'nome': 'Geometria'},
          ],
          prioridade: 4,
          diasEstudo: ['Terça', 'Quinta'],
          questoes: 15,
        ),
      ],
      calendario: {},
      preferencias: {},
    );
  });

  Widget createPlanoResumoScreen() {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<PlanoEstudoService>.value(value: mockPlanoEstudoService),
          ChangeNotifierProvider<EditalService>.value(value: mockEditalService),
        ],
        child: PlanoResumoScreen(
          planoId: 'plano_id',
        ),
      ),
    );
  }

  group('PlanoResumoScreen Widget Tests', () {
    testWidgets('should display loading indicator when loading', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockPlanoEstudoService.isLoading).thenReturn(true);
      when(mockPlanoEstudoService.getPlanoById('plano_id')).thenReturn(null);

      // Renderizar o widget
      await tester.pumpWidget(createPlanoResumoScreen());

      // Verificar se o indicador de carregamento está presente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display plano details when not loading', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockPlanoEstudoService.isLoading).thenReturn(false);
      when(mockPlanoEstudoService.getPlanoById('plano_id')).thenReturn(mockPlano);

      // Renderizar o widget
      await tester.pumpWidget(createPlanoResumoScreen());

      // Verificar se os detalhes do plano estão presentes
      expect(find.text('Plano de Estudo de Teste'), findsOneWidget);
      expect(find.text('Português'), findsOneWidget);
      expect(find.text('Matemática'), findsOneWidget);
      expect(find.text('Conhecimentos Básicos'), findsAtLeast(1));
    });

    testWidgets('should display calendar', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockPlanoEstudoService.isLoading).thenReturn(false);
      when(mockPlanoEstudoService.getPlanoById('plano_id')).thenReturn(mockPlano);

      // Renderizar o widget
      await tester.pumpWidget(createPlanoResumoScreen());

      // Verificar se o calendário está presente
      expect(find.text('Calendário de Estudos'), findsOneWidget);
      
      // Verificar se os dias da semana estão presentes
      expect(find.text('Seg'), findsOneWidget);
      expect(find.text('Ter'), findsOneWidget);
      expect(find.text('Qua'), findsOneWidget);
      expect(find.text('Qui'), findsOneWidget);
      expect(find.text('Sex'), findsOneWidget);
      expect(find.text('Sáb'), findsOneWidget);
      expect(find.text('Dom'), findsOneWidget);
    });

    testWidgets('should display start button', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockPlanoEstudoService.isLoading).thenReturn(false);
      when(mockPlanoEstudoService.getPlanoById('plano_id')).thenReturn(mockPlano);

      // Renderizar o widget
      await tester.pumpWidget(createPlanoResumoScreen());

      // Verificar se o botão de iniciar está presente
      expect(find.text('Iniciar Jornada'), findsOneWidget);
    });

    testWidgets('should display sync options', (WidgetTester tester) async {
      // Configurar os mocks
      when(mockPlanoEstudoService.isLoading).thenReturn(false);
      when(mockPlanoEstudoService.getPlanoById('plano_id')).thenReturn(mockPlano);

      // Renderizar o widget
      await tester.pumpWidget(createPlanoResumoScreen());

      // Verificar se as opções de sincronização estão presentes
      expect(find.text('Sincronizar com:'), findsOneWidget);
      expect(find.text('Google Calendar'), findsOneWidget);
      expect(find.text('Apple Calendar'), findsOneWidget);
    });
  });
}
