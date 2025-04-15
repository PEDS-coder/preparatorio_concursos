# Documentação de Refatoração

Este documento descreve as principais refatorações realizadas no projeto para melhorar a qualidade do código, resolver problemas de compilação e aumentar a manutenibilidade.

## Índice

1. [Correções de Erros de Compilação](#correções-de-erros-de-compilação)
2. [Refatoração de Código](#refatoração-de-código)
3. [Implementação de Testes](#implementação-de-testes)
4. [Padronização de Código](#padronização-de-código)

## Correções de Erros de Compilação

### Resolução de Conflitos de ThemeMode

Foi identificado um conflito entre o `ThemeMode` do Flutter e o `ThemeMode` definido no `ThemeService`. Para resolver este problema:

- Renomeamos o enum `ThemeMode` para `AppThemeMode` no arquivo `theme_service.dart`
- Adicionamos um método `flutterThemeMode` para converter entre o `AppThemeMode` e o `ThemeMode` do Flutter
- Atualizamos a interface `IThemeService` para refletir as mudanças
- Corrigimos o arquivo `app.dart` para usar o novo método `flutterThemeMode`

### Correção do Uso de GlobalKey no ShareService

Para resolver problemas com o uso de `GlobalKey`:

- Especificamos o tipo genérico para `GlobalKey<State<StatefulWidget>>` para evitar ambiguidades
- Atualizamos a interface `IShareService` e a implementação para usar o tipo correto

### Correção do BetterFeedback

Para resolver problemas com o `BetterFeedback`:

- Modificamos o método `initFeedback` para receber um `Widget` como parâmetro
- Atualizamos a interface `IFeedbackService` para refletir a mudança
- Corrigimos o uso no arquivo `main.dart` para passar o widget corretamente

### Correção do AnimatedRoute

Para resolver problemas com o `AnimatedRoute`:

- Modificamos a classe `AnimatedRoute` para estender `MaterialPageRoute<T>` em vez de `PageRouteBuilder`
- Implementamos o método `buildTransitions` para manter as animações personalizadas
- Atualizamos o `NavigationService` para usar a nova implementação com tipos genéricos corretos

### Resolução de Conflitos com Event no CalendarService

Para resolver conflitos de importação com `Event`:

- Criamos classes específicas para cada tipo de evento de calendário (`Add2CalendarEvent`, `DeviceCalendarEvent`, `GoogleCalendarEvent`)
- Usamos aliases de importação para evitar conflitos de nomes (`add2calendar`, `device_calendar`, `google_calendar`)
- Atualizamos o `CalendarService` para usar as novas classes e aliases

### Correção do PdfBitmap no PdfScannerDetector

Para resolver problemas com o `PdfBitmap`:

- Criamos uma classe personalizada `CustomPdfBitmap` para substituir o `PdfBitmap` da biblioteca syncfusion_flutter_pdf
- Atualizamos o `PdfScannerDetector` para usar nossa classe personalizada
- Modificamos os métodos relacionados para trabalhar com a nova classe

### Correção do ApiConfigService no main.dart

Para resolver problemas com o `ApiConfigService`:

- Adicionamos o `ApiConfigService` ao módulo de serviços para injeção de dependência
- Atualizamos o arquivo main.dart para obter o `ApiConfigService` do container de injeção de dependência
- Removemos a criação manual da instância do `ApiConfigService`

### Resolução de Problemas com o ICacheService no AdvancedCacheService

Para resolver problemas com o `ICacheService`:

- Criamos uma nova interface `IAdvancedCacheService` compatível com a implementação atual
- Atualizamos o `AdvancedCacheService` para implementar a nova interface
- Modificamos a documentação para refletir as mudanças

## Refatoração de Código

### Uso de Parâmetros Nomeados

Refatoramos vários métodos para usar parâmetros nomeados em vez de posicionais, incluindo:

- `extrairConteudoProgramatico`
- `extrairConcursoConteudo`
- `gerarQuestoes`
- `gerarEsquema`
- `gerarFlashcards`

Exemplo de antes:
```dart
Future<String> gerarQuestoes(String texto, String materia, String dificuldade, int quantidade) async {
  // ...
}
```

Exemplo de depois:
```dart
Future<String> gerarQuestoes({
  required String texto,
  required String materia,
  required String dificuldade,
  required int quantidade,
}) async {
  // ...
}
```

### Melhoria da Estrutura de Classes e Interfaces

- Criamos interfaces específicas para evitar conflitos
- Implementamos classes personalizadas para substituir componentes problemáticos
- Melhoramos a organização do código para facilitar a manutenção

## Implementação de Testes

### Testes Unitários

Implementamos testes unitários para os seguintes serviços:

- `ShareService`: Testes para compartilhamento de texto, arquivos e planos de estudo
- `CalendarService`: Testes para verificar disponibilidade, obter calendários e sincronizar planos
- `ApiConfigService`: Testes para configuração, obtenção e limpeza de chaves de API

### Como Executar os Testes

Para executar todos os testes unitários:

```bash
flutter test
```

Para executar um teste específico:

```bash
flutter test test/unit/services/share_service_test.dart
```

## Padronização de Código

### Padrões de Importação

Padronizamos as importações em todo o projeto seguindo esta ordem:

1. Importações do Dart
2. Importações do Flutter
3. Importações de pacotes externos
4. Importações do projeto (usando caminhos relativos)

Exemplo:
```dart
// Importações do Dart
import 'dart:async';
import 'dart:io';

// Importações do Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Importações de pacotes externos
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Importações do projeto
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
```

### Convenções de Nomenclatura

- Classes: PascalCase (ex: `PlanoEstudo`)
- Métodos e variáveis: camelCase (ex: `gerarQuestoes`)
- Constantes: SNAKE_CASE_MAIÚSCULO (ex: `API_KEY`)
- Arquivos: snake_case (ex: `plano_estudo_service.dart`)

### Null Safety

Implementamos null safety em todo o código, usando:

- Tipos não-nulos por padrão
- Operador `?` para tipos que podem ser nulos
- Operador `!` apenas quando temos certeza que o valor não é nulo
- Operador `??` para fornecer valores padrão

## Próximos Passos

- Implementar testes de integração para funcionalidades críticas
- Revisar e corrigir a estrutura de widgets em todas as telas principais
- Configurar testes automatizados para diferentes plataformas
- Implementar testes de UI para as novas telas e widgets
