# Testes do Aplicativo Preparatório Concursos

Este diretório contém os testes automatizados para o aplicativo Preparatório Concursos.

## Estrutura de Testes

Os testes estão organizados seguindo a mesma estrutura do código-fonte:

- `core/`: Testes para componentes do núcleo do aplicativo
  - `services/`: Testes para serviços principais
  - `utils/`: Testes para utilitários
- `features/`: Testes para funcionalidades específicas
- `mocks/`: Classes mock utilizadas nos testes
- `widget_test.dart`: Teste básico de inicialização do aplicativo

## Executando os Testes

### Todos os Testes

Para executar todos os testes:

```bash
flutter test
```

### Testes Específicos

Para executar um teste específico:

```bash
flutter test test/core/utils/logger_test.dart
```

### Testes com Cobertura

Para executar os testes e gerar relatório de cobertura:

```bash
flutter test --coverage
```

Para visualizar o relatório de cobertura (requer lcov):

```bash
genhtml coverage/lcov.info -o coverage/html
```

Então abra `coverage/html/index.html` no navegador.

## Adicionando Novos Testes

Ao adicionar novos recursos ao aplicativo, certifique-se de adicionar testes correspondentes seguindo estas diretrizes:

1. **Testes Unitários**: Para classes e funções individuais
2. **Testes de Widget**: Para componentes de UI
3. **Testes de Integração**: Para fluxos que envolvem múltiplos componentes

### Exemplo de Teste Unitário

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:preparatorio_concursos/core/utils/example_util.dart';

void main() {
  group('ExampleUtil', () {
    test('should perform expected operation', () {
      // Arrange
      final util = ExampleUtil();
      
      // Act
      final result = util.someOperation();
      
      // Assert
      expect(result, expectedValue);
    });
  });
}
```

## Mocks

Para testes que dependem de serviços externos ou componentes complexos, use os mocks disponíveis em `mocks/` ou crie novos conforme necessário.

## CI/CD

Os testes são executados automaticamente em cada pull request e push para as branches principais através do GitHub Actions. Veja o arquivo `.github/workflows/flutter-ci.yml` para mais detalhes.
