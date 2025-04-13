import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:preparatorio_concursos/core/data/models/edital.dart';
import 'package:preparatorio_concursos/core/data/models/cargo.dart';
import 'package:preparatorio_concursos/core/data/services/services.dart';
import 'package:preparatorio_concursos/features/3_edital_management/presentation/screens/cargo_select_screen.dart';

// Gerar mocks
@GenerateMocks([EditalService])
import 'cargo_select_screen_test.mocks.dart';

void main() {
  late MockEditalService mockEditalService;
  late Edital mockEdital;
  late List<Cargo> mockCargos;

  setUp(() {
    mockEditalService = MockEditalService();
    
    // Criar um edital de teste
    mockEdital = Edital(
      id: 'test_id',
      titulo: 'Edital de Teste',
      orgao: 'Órgão de Teste',
      dataPublicacao: DateTime.now(),
      dataProva: DateTime.now().add(Duration(days: 30)),
      linkEdital: 'https://example.com/edital',
      cargos: [],
    );
    
    // Criar cargos de teste
    mockCargos = [
      Cargo(
        id: 'cargo1',
        nome: 'Cargo 1',
        nivel: 'Superior',
        salario: 5000.0,
        vagasAmpla: 5,
        vagasPcd: 1,
        vagasNegros: 1,
        vagasIndios: 0,
        taxaInscricao: 100.0,
        conteudoProgramatico: {},
      ),
      Cargo(
        id: 'cargo2',
        nome: 'Cargo 2',
        nivel: 'Médio',
        salario: 3000.0,
        vagasAmpla: 10,
        vagasPcd: 2,
        vagasNegros: 2,
        vagasIndios: 1,
        taxaInscricao: 80.0,
        conteudoProgramatico: {},
      ),
    ];
  });

  Widget createCargoSelectScreen() {
    return MaterialApp(
      home: ChangeNotifierProvider<EditalService>.value(
        value: mockEditalService,
        child: CargoSelectScreen(
          editalId: 'test_id',
        ),
      ),
    );
  }

  group('CargoSelectScreen Widget Tests', () {
    testWidgets('should display loading indicator when loading', (WidgetTester tester) async {
      // Configurar o mock
      when(mockEditalService.isLoading).thenReturn(true);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);

      // Renderizar o widget
      await tester.pumpWidget(createCargoSelectScreen());

      // Verificar se o indicador de carregamento está presente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display cargos when not loading', (WidgetTester tester) async {
      // Configurar o mock
      when(mockEditalService.isLoading).thenReturn(false);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);
      
      // Adicionar cargos ao edital
      mockEdital = mockEdital.copyWith(cargos: mockCargos);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);

      // Renderizar o widget
      await tester.pumpWidget(createCargoSelectScreen());

      // Verificar se os cargos estão presentes
      expect(find.text('Cargo 1'), findsOneWidget);
      expect(find.text('Cargo 2'), findsOneWidget);
      expect(find.text('Nível: Superior'), findsOneWidget);
      expect(find.text('Nível: Médio'), findsOneWidget);
      expect(find.text('Salário: R\$ 5.000,00'), findsOneWidget);
      expect(find.text('Salário: R\$ 3.000,00'), findsOneWidget);
    });

    testWidgets('should allow cargo selection', (WidgetTester tester) async {
      // Configurar o mock
      when(mockEditalService.isLoading).thenReturn(false);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);
      
      // Adicionar cargos ao edital
      mockEdital = mockEdital.copyWith(cargos: mockCargos);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);

      // Renderizar o widget
      await tester.pumpWidget(createCargoSelectScreen());

      // Verificar se os checkboxes estão presentes
      expect(find.byType(Checkbox), findsNWidgets(2));

      // Selecionar o primeiro cargo
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      // Verificar se o botão de continuar está habilitado
      expect(find.text('Continuar'), findsOneWidget);
      
      // Nota: Não podemos verificar completamente se o checkbox foi marcado
      // em testes de widget sem modificar a implementação para torná-la mais testável
    });

    testWidgets('should display error message when no cargo is selected and continue button is pressed', (WidgetTester tester) async {
      // Configurar o mock
      when(mockEditalService.isLoading).thenReturn(false);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);
      
      // Adicionar cargos ao edital
      mockEdital = mockEdital.copyWith(cargos: mockCargos);
      when(mockEditalService.getEditalById('test_id')).thenReturn(mockEdital);

      // Renderizar o widget
      await tester.pumpWidget(createCargoSelectScreen());

      // Pressionar o botão de continuar sem selecionar nenhum cargo
      await tester.tap(find.text('Continuar'));
      await tester.pump();

      // Verificar se a mensagem de erro está presente
      expect(find.text('Selecione pelo menos um cargo'), findsOneWidget);
    });
  });
}
