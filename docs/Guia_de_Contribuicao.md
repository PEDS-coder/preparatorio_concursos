# Guia de Contribuição

Este documento fornece orientações para desenvolvedores que desejam contribuir com o projeto. Siga estas diretrizes para garantir que suas contribuições sejam aceitas e integradas ao projeto de forma eficiente.

## Configuração do Ambiente de Desenvolvimento

### Requisitos

- Flutter SDK (versão 3.10.0 ou superior)
- Dart SDK (versão 3.0.0 ou superior)
- Android Studio ou Visual Studio Code
- Git

### Configuração Inicial

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/preparatorio-concursos.git
   cd preparatorio-concursos
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Configure o arquivo `.env`:
   ```
   # Crie um arquivo .env na raiz do projeto com as seguintes variáveis
   API_KEY=sua_chave_api
   API_URL=https://api.example.com
   ```

4. Execute o aplicativo:
   ```bash
   flutter run
   ```

## Estrutura do Projeto

O projeto segue uma arquitetura em camadas com injeção de dependência. Familiarize-se com a estrutura de diretórios:

```
lib/
  ├── app.dart                  # Ponto de entrada do aplicativo
  ├── main.dart                 # Configuração inicial
  ├── core/                     # Funcionalidades centrais
  │   ├── auth/                 # Autenticação
  │   ├── data/                 # Acesso a dados
  │   │   ├── models/           # Modelos de dados
  │   │   ├── repositories/     # Repositórios
  │   │   └── services/         # Serviços de dados
  │   ├── di/                   # Injeção de dependência
  │   ├── services/             # Serviços centrais
  │   └── utils/                # Utilitários
  └── features/                 # Funcionalidades do aplicativo
      ├── 1_login/              # Feature de login
      ├── 2_edital/             # Feature de edital
      ├── 3_cargo/              # Feature de cargo
      ├── 4_study_plan/         # Feature de plano de estudo
      └── 5_mercado/            # Feature de mercado
```

## Fluxo de Trabalho de Desenvolvimento

### 1. Criação de Branch

Crie uma branch para sua feature ou correção:

```bash
git checkout -b feature/nome-da-feature
# ou
git checkout -b fix/nome-do-bug
```

### 2. Desenvolvimento

Siga as convenções de código e arquitetura do projeto:

- **Nomenclatura**: CamelCase para classes, camelCase para variáveis e métodos
- **Organização**: Um arquivo por classe, agrupados por funcionalidade
- **Comentários**: Documentação para todas as classes e métodos públicos
- **Testes**: Testes unitários para todas as classes de lógica de negócios
- **Tratamento de Erros**: Uso consistente de try/catch e propagação de erros

### 3. Testes

Execute os testes antes de enviar sua contribuição:

```bash
flutter test
```

### 4. Commit

Faça commits com mensagens claras e descritivas:

```bash
git add .
git commit -m "feat: adiciona funcionalidade X"
# ou
git commit -m "fix: corrige problema Y"
```

Siga o padrão de mensagens de commit:
- `feat`: Nova funcionalidade
- `fix`: Correção de bug
- `docs`: Alterações na documentação
- `style`: Alterações de formatação
- `refactor`: Refatoração de código
- `test`: Adição ou correção de testes
- `chore`: Alterações em arquivos de build, configurações, etc.

### 5. Pull Request

Envie um Pull Request para a branch principal:

1. Atualize sua branch com a branch principal:
   ```bash
   git checkout main
   git pull
   git checkout feature/nome-da-feature
   git rebase main
   ```

2. Resolva conflitos, se houver

3. Envie sua branch:
   ```bash
   git push origin feature/nome-da-feature
   ```

4. Crie um Pull Request no GitHub

## Diretrizes de Código

### Injeção de Dependência

Use o padrão de injeção de dependência para desacoplar os componentes:

```dart
// Registrar um serviço
@singleton
class MyService {
  // ...
}

// Usar um serviço
final service = getIt<MyService>();
```

### Tratamento de Erros

Use o serviço de tratamento de erros para lidar com exceções:

```dart
try {
  // Código que pode gerar exceção
} catch (e) {
  errorHandlerService.handleError(e, 'Contexto do erro');
}
```

### Acesso a Dados

Use repositórios para acessar dados:

```dart
// Definir um repositório
@singleton
class MyRepository {
  Future<Data> getData() async {
    // ...
  }
}

// Usar um repositório
final data = await myRepository.getData();
```

### UI

Use widgets reutilizáveis e siga o padrão de design do aplicativo:

```dart
// Widget reutilizável
class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({Key? key, required this.title}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      // ...
    );
  }
}
```

## Documentação

### Documentação de Código

Use comentários Dart Doc para documentar classes e métodos:

```dart
/// Classe que representa um usuário
class Usuario {
  final String nome;
  final String email;
  
  /// Cria um novo usuário
  ///
  /// [nome] é o nome do usuário
  /// [email] é o email do usuário
  Usuario({required this.nome, required this.email});
  
  /// Retorna uma representação em string do usuário
  @override
  String toString() {
    return 'Usuario(nome: $nome, email: $email)';
  }
}
```

### Documentação de Funcionalidades

Documente novas funcionalidades no arquivo README.md ou em arquivos de documentação específicos.

## Testes

### Testes Unitários

Escreva testes unitários para todas as classes de lógica de negócios:

```dart
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

Escreva testes de widget para componentes de UI importantes:

```dart
void main() {
  testWidgets('MyWidget should display title', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(MaterialApp(
      home: MyWidget(title: 'Test Title'),
    ));
    
    // Act & Assert
    expect(find.text('Test Title'), findsOneWidget);
  });
}
```

## Recursos Adicionais

- [Documentação do Flutter](https://flutter.dev/docs)
- [Documentação do Dart](https://dart.dev/guides)
- [Guia de Estilo do Dart](https://dart.dev/guides/language/effective-dart/style)
- [Documentação do get_it](https://pub.dev/packages/get_it)
- [Documentação do injectable](https://pub.dev/packages/injectable)

## Contato

Se você tiver dúvidas ou precisar de ajuda, entre em contato com a equipe de desenvolvimento:

- Email: equipe@example.com
- Discord: https://discord.gg/example

## Agradecimentos

Agradecemos por contribuir com o projeto! Suas contribuições são valiosas e ajudam a melhorar o aplicativo para todos os usuários.
