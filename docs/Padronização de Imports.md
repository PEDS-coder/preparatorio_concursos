# Padronização de Imports

Este documento estabelece as diretrizes para a padronização de imports em todo o projeto, com o objetivo de evitar conflitos e melhorar a legibilidade do código.

## Ordem de Imports

Os imports devem seguir a seguinte ordem:

1. **Imports do Dart** (dart:*)
2. **Imports do Flutter** (package:flutter/*)
3. **Imports de pacotes externos** (package:*)
4. **Imports do projeto** (imports relativos)

Exemplo:

```dart
// Imports do Dart
import 'dart:async';
import 'dart:io';

// Imports do Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Imports de pacotes externos
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Imports do projeto
import '../../../../core/theme/app_theme.dart';
import '../../../../core/data/services/plano_estudo_service.dart';
```

## Uso de Aliases

Quando houver conflito de nomes entre diferentes pacotes, use aliases para evitar ambiguidades:

```dart
// Uso de aliases para evitar conflitos
import 'package:add_2_calendar/add_2_calendar.dart' as add2calendar;
import 'package:device_calendar/device_calendar.dart' as device_calendar;
import 'package:googleapis/calendar/v3.dart' as google_calendar;
```

## Imports Específicos

Quando possível, importe apenas os elementos específicos que você precisa, em vez de importar todo o pacote:

```dart
// Preferir isso:
import 'package:flutter/material.dart' show ThemeData, Colors, MediaQuery;

// Em vez disso:
import 'package:flutter/material.dart';
```

No entanto, para pacotes do Flutter que são usados extensivamente, como `material.dart`, é aceitável importar todo o pacote.

## Imports Não Utilizados

Remova todos os imports não utilizados. A maioria dos IDEs tem ferramentas para identificar e remover automaticamente imports não utilizados.

## Imports Duplicados

Evite imports duplicados. Se você precisar importar o mesmo pacote várias vezes com diferentes aliases, certifique-se de que cada import tenha um propósito claro.

## Imports Absolutos vs. Relativos

Para imports dentro do projeto, use imports relativos:

```dart
// Preferir isso:
import '../../../core/theme/app_theme.dart';

// Em vez disso:
import 'package:preparatorio_concursos/core/theme/app_theme.dart';
```

No entanto, para imports muito profundos na hierarquia de diretórios, é aceitável usar imports absolutos para melhorar a legibilidade.

## Exemplos de Padronização

### Exemplo 1: Serviço com Dependências Externas

```dart
// Imports do Dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Imports do Flutter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Imports de pacotes externos
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Imports do projeto
import '../data/models/plano_estudo.dart';
import '../data/services/interfaces/analytics_service_interface.dart';
import '../utils/logger.dart';
```

### Exemplo 2: Widget com Dependências Internas

```dart
// Imports do Flutter
import 'package:flutter/material.dart';

// Imports de pacotes externos
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Imports do projeto
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/custom_button.dart';
import '../../data/models/edital.dart';
import '../../data/services/edital_service.dart';
import '../widgets/edital_card.dart';
```

## Ferramentas de Formatação

Recomendamos o uso de ferramentas de formatação automática para ajudar a manter a padronização dos imports:

- **VS Code**: Extensão "Dart Import Sorter"
- **Android Studio/IntelliJ**: Recurso "Optimize Imports" (Ctrl+Alt+O)
- **Flutter CLI**: `flutter format lib`

## Verificação de Conformidade

Durante as revisões de código, verifique se os imports estão seguindo estas diretrizes. Isso ajudará a manter a consistência em todo o projeto e evitará conflitos futuros.
