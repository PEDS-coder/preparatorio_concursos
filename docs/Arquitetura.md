# Arquitetura do Aplicativo

## Visão Geral

O aplicativo segue uma arquitetura em camadas, com separação clara de responsabilidades e injeção de dependência para facilitar a manutenção e os testes. A arquitetura é baseada nos princípios SOLID e utiliza padrões de design como Repository, Service e Factory.

## Camadas

### 1. Apresentação (UI)

A camada de apresentação é responsável pela interface do usuário e pela interação com o usuário. Ela é composta por:

- **Screens**: Telas completas do aplicativo
- **Widgets**: Componentes reutilizáveis da interface
- **Controllers**: Controladores que gerenciam o estado da UI
- **ViewModels**: Modelos de dados específicos para a UI

### 2. Lógica de Negócios (Domain)

A camada de lógica de negócios contém as regras de negócio e a lógica central do aplicativo. Ela é composta por:

- **Services**: Serviços que implementam a lógica de negócios
- **Models**: Modelos de dados do domínio
- **Interfaces**: Contratos para os serviços e repositórios

### 3. Acesso a Dados (Data)

A camada de acesso a dados é responsável por acessar e manipular os dados do aplicativo. Ela é composta por:

- **Repositories**: Repositórios que encapsulam o acesso aos dados
- **Data Sources**: Fontes de dados (API, banco de dados local, etc.)
- **DTOs**: Objetos de transferência de dados

### 4. Infraestrutura (Core)

A camada de infraestrutura fornece funcionalidades de suporte para as outras camadas. Ela é composta por:

- **Utils**: Utilitários e helpers
- **DI**: Configuração de injeção de dependência
- **Config**: Configurações do aplicativo
- **Constants**: Constantes globais

## Injeção de Dependência

O aplicativo utiliza o padrão de injeção de dependência para desacoplar os componentes e facilitar os testes. A injeção de dependência é implementada usando os pacotes `get_it` e `injectable`.

### Configuração

A configuração da injeção de dependência é feita no arquivo `lib/core/di/service_locator.dart`. Os módulos de injeção de dependência são definidos em `lib/core/di/modules/`.

### Uso

Para obter uma instância de um serviço ou repositório, use o container de injeção de dependência:

```dart
final service = getIt<MyService>();
```

## Fluxo de Dados

O fluxo de dados no aplicativo segue o padrão unidirecional:

1. A UI solicita dados ou ações através dos serviços
2. Os serviços processam a lógica de negócios
3. Os serviços acessam os dados através dos repositórios
4. Os repositórios obtêm os dados das fontes de dados
5. Os dados são retornados para a UI através dos serviços

## Gerenciamento de Estado

O aplicativo utiliza o padrão Provider para gerenciamento de estado. Os serviços que precisam notificar a UI sobre mudanças de estado implementam a interface `ChangeNotifier`.

## Tratamento de Erros

O aplicativo utiliza um sistema centralizado de tratamento de erros, implementado no serviço `ErrorHandlerService`. Todos os serviços e repositórios utilizam este serviço para tratar e registrar erros.

## Cache e Desempenho

O aplicativo utiliza um sistema avançado de cache para melhorar o desempenho:

- **AdvancedCacheService**: Cache com políticas de expiração e priorização
- **DataLoaderService**: Carregamento paginado e incremental de dados
- **ImageLoaderService**: Carregamento assíncrono e lazy loading de imagens
- **BackgroundProcessorService**: Processamento em segundo plano com isolates

## Segurança

O aplicativo implementa várias medidas de segurança:

- **SecureStorageService**: Armazenamento seguro de credenciais
- **InputValidationService**: Validação de entrada de dados
- **SecurityService**: Proteção contra ataques comuns

## Diagramas

### Diagrama de Camadas

```
+-------------------+
|   Apresentação    |
|  (Screens, Widgets)|
+-------------------+
          |
          v
+-------------------+
| Lógica de Negócios|
|    (Services)     |
+-------------------+
          |
          v
+-------------------+
|  Acesso a Dados   |
|   (Repositories)  |
+-------------------+
          |
          v
+-------------------+
|   Infraestrutura  |
|  (Utils, DI, etc.)|
+-------------------+
```

### Diagrama de Componentes

```
+-------------------+     +-------------------+
|      Screen       |---->|     Service       |
+-------------------+     +-------------------+
                                   |
                                   v
                          +-------------------+
                          |    Repository     |
                          +-------------------+
                                   |
                                   v
                          +-------------------+
                          |   Data Source     |
                          +-------------------+
```

### Diagrama de Sequência (Exemplo: Análise de Edital)

```
+-------+    +------------+    +-------------+    +----------+
|  UI   |    |  Service   |    |  Repository |    |   API    |
+-------+    +------------+    +-------------+    +----------+
    |               |                 |                |
    | analisarEdital|                 |                |
    |-------------->|                 |                |
    |               | saveDocument    |                |
    |               |---------------->|                |
    |               |                 | processarEdital|
    |               |                 |--------------->|
    |               |                 |                |
    |               |                 |   resultado    |
    |               |                 |<---------------|
    |               |    resultado    |                |
    |               |<----------------|                |
    |   resultado   |                 |                |
    |<--------------|                 |                |
    |               |                 |                |
```

## Estrutura de Diretórios

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

## Convenções de Código

- **Nomenclatura**: CamelCase para classes, camelCase para variáveis e métodos
- **Organização**: Um arquivo por classe, agrupados por funcionalidade
- **Comentários**: Documentação para todas as classes e métodos públicos
- **Testes**: Testes unitários para todas as classes de lógica de negócios
- **Tratamento de Erros**: Uso consistente de try/catch e propagação de erros

## Conclusão

A arquitetura do aplicativo foi projetada para ser modular, testável e escalável. A separação clara de responsabilidades e o uso de injeção de dependência facilitam a manutenção e a evolução do aplicativo.
