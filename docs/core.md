# Core

Esta categoria contém as classes e funcionalidades centrais do aplicativo, incluindo:

- **Auth**: Autenticação e autorização
- **Data**: Modelos de dados, repositórios e serviços de dados
- **DI**: Injeção de dependência
- **Services**: Serviços centrais
- **Utils**: Utilitários e helpers

## Arquitetura

O core do aplicativo segue uma arquitetura em camadas, com separação clara de responsabilidades:

1. **Modelos de Dados**: Representam as entidades do domínio
2. **Repositórios**: Encapsulam o acesso aos dados
3. **Serviços**: Implementam a lógica de negócios
4. **Interfaces**: Definem contratos para os serviços e repositórios

## Injeção de Dependência

O aplicativo utiliza o padrão de injeção de dependência para desacoplar os componentes e facilitar os testes. A injeção de dependência é implementada usando os pacotes `get_it` e `injectable`.

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
