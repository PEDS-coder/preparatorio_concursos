# Guia de Testes

Este documento fornece informações sobre os testes implementados no projeto, como executá-los e como criar novos testes.

## Tipos de Testes

O projeto utiliza vários tipos de testes para garantir a qualidade do código:

1. **Testes Unitários**: Testam unidades individuais de código (classes, métodos, funções)
2. **Testes de Widget**: Testam widgets e suas interações
3. **Testes de Integração**: Testam fluxos completos do aplicativo
4. **Testes de Performance**: Testam o desempenho do aplicativo

## Estrutura de Diretórios

```
test/
  ├── unit/                  # Testes unitários
  ├── widget/                # Testes de widget
  ├── integration/           # Testes de integração
  └── performance/           # Testes de performance
```

## Executando os Testes

### Todos os Testes

Para executar todos os testes:

```bash
flutter test
```

### Testes Específicos

Para executar um teste específico:

```bash
flutter test test/widget/login_screen_test.dart
```

Para executar todos os testes de um diretório:

```bash
flutter test test/widget/
```

### Testes com Cobertura

Para executar os testes com cobertura:

```bash
flutter test --coverage
```

Para visualizar o relatório de cobertura:

```bash
genhtml coverage/lcov.info -o coverage/html
```

Abra `coverage/html/index.html` no navegador para ver o relatório.

## Criando Novos Testes

### Testes Unitários

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/services/my_service.dart';

void main() {
  group('MyService', () {
    late MyService service;
    
    setUp(() {
      service = MyService();
    });
    
    test('should do something', () {
      // Arrange
      final input = 'input';
      
      // Act
      final result = service.doSomething(input);
      
      // Assert
      expect(result, 'expected output');
    });
  });
}
```

### Testes de Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/features/my_feature/presentation/screens/my_screen.dart';

void main() {
  testWidgets('MyScreen should display title', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: MyScreen(title: 'Test Title'),
    ));
    
    // Act & Assert
    expect(find.text('Test Title'), findsOneWidget);
  });
}
```

### Testes de Integração

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/app.dart';

void main() {
  testWidgets('Complete flow test', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MyApp());
    
    // Act
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    
    // Assert
    expect(find.text('Welcome'), findsOneWidget);
  });
}
```

### Testes de Performance

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/app.dart';

void main() {
  testWidgets('Performance test', (WidgetTester tester) async {
    // Arrange
    final stopwatch = Stopwatch()..start();
    
    // Act
    await tester.pumpWidget(MyApp());
    
    // Assert
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(1000));
  });
}
```

## Mocks

O projeto utiliza o pacote `mockito` para criar mocks para testes. Para gerar mocks:

1. Adicione a anotação `@GenerateMocks` ao arquivo de teste:

```dart
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:preparatorio_concursos/core/services/my_service.dart';

@GenerateMocks([MyService])
import 'my_test.mocks.dart';
```

2. Execute o comando para gerar os mocks:

```bash
flutter pub run build_runner build
```

3. Use os mocks nos testes:

```dart
void main() {
  late MockMyService mockMyService;
  
  setUp(() {
    mockMyService = MockMyService();
  });
  
  test('should do something', () {
    // Configurar o mock
    when(mockMyService.doSomething('input')).thenReturn('mocked output');
    
    // Usar o mock
    final result = mockMyService.doSomething('input');
    
    // Verificar o resultado
    expect(result, 'mocked output');
  });
}
```

## Integração Contínua

O projeto utiliza GitHub Actions para executar os testes automaticamente em cada push e pull request. A configuração está no arquivo `.github/workflows/flutter_tests.yml`.

## Boas Práticas

1. **Nomenclatura**: Use nomes descritivos para os testes
2. **Organização**: Siga o padrão AAA (Arrange, Act, Assert)
3. **Isolamento**: Cada teste deve ser independente dos outros
4. **Cobertura**: Tente atingir pelo menos 80% de cobertura de código
5. **Manutenção**: Mantenha os testes atualizados com as mudanças no código

## Recursos Adicionais

- [Documentação de Testes do Flutter](https://flutter.dev/docs/testing)
- [Documentação do Mockito](https://pub.dev/packages/mockito)
- [Guia de Testes de Widget](https://flutter.dev/docs/cookbook/testing/widget/introduction)
- [Guia de Testes de Integração](https://flutter.dev/docs/testing/integration-tests)
