# Padronização de Nomes para o Projeto Concursos IA

## Objetivo

Este documento estabelece diretrizes para padronizar os nomes de arquivos, classes e métodos no projeto Concursos IA, visando maior consistência e facilidade de manutenção.

## Diretrizes Gerais

1. **Idioma**: Utilizar português do Brasil para todos os novos arquivos, classes e métodos.
2. **Sem Acentos**: Não usar acentos ou caracteres especiais em nomes de arquivos.
3. **Separação**: Usar underscore (_) para separar palavras em nomes de arquivos.
4. **Capitalização**: 
   - Arquivos: snake_case (tudo minúsculo com underscore)
   - Classes: PascalCase (primeira letra de cada palavra maiúscula)
   - Métodos e variáveis: camelCase (primeira letra minúscula, demais palavras com inicial maiúscula)

## Padrões para Nomes de Arquivos

| Tipo | Padrão | Exemplo em Português | Exemplo em Inglês (a evitar) |
|------|--------|----------------------|------------------------------|
| Serviços | `servico_[funcionalidade].dart` | `servico_autenticacao.dart` | `auth_service.dart` |
| Utilitários | `[funcionalidade]_util.dart` | `texto_util.dart` | `text_utils.dart` |
| Telas | `tela_[funcionalidade].dart` | `tela_login.dart` | `login_screen.dart` |
| Modelos | `modelo_[entidade].dart` | `modelo_usuario.dart` | `user_model.dart` |
| Widgets | `widget_[funcionalidade].dart` | `widget_botao_personalizado.dart` | `custom_button_widget.dart` |
| Interfaces | `interface_[funcionalidade].dart` | `interface_servico_autenticacao.dart` | `auth_service_interface.dart` |
| Implementações | `impl_[funcionalidade].dart` | `impl_servico_autenticacao.dart` | `auth_service_impl.dart` |
| Testes | `teste_[funcionalidade].dart` | `teste_servico_autenticacao.dart` | `auth_service_test.dart` |

## Padrões para Nomes de Classes

| Tipo | Padrão | Exemplo em Português | Exemplo em Inglês (a evitar) |
|------|--------|----------------------|------------------------------|
| Serviços | `Servico[Funcionalidade]` | `ServicoAutenticacao` | `AuthService` |
| Utilitários | `[Funcionalidade]Util` | `TextoUtil` | `TextUtils` |
| Telas | `Tela[Funcionalidade]` | `TelaLogin` | `LoginScreen` |
| Modelos | `Modelo[Entidade]` | `ModeloUsuario` | `UserModel` |
| Widgets | `Widget[Funcionalidade]` | `WidgetBotaoPersonalizado` | `CustomButtonWidget` |
| Interfaces | `Interface[Funcionalidade]` | `InterfaceServicoAutenticacao` | `AuthServiceInterface` |
| Implementações | `Impl[Funcionalidade]` | `ImplServicoAutenticacao` | `AuthServiceImpl` |

## Implementação

1. **Arquivos Existentes**: Não renomear arquivos existentes para evitar problemas de referência.
2. **Novos Arquivos**: Todos os novos arquivos devem seguir este padrão.
3. **Refatoração Gradual**: Ao modificar significativamente um arquivo existente, considerar renomeá-lo seguindo este padrão.

## Mapeamento de Termos Comuns (Inglês → Português)

| Inglês | Português |
|--------|-----------|
| Service | Servico |
| Manager | Gerenciador |
| Utils | Util |
| Helper | Auxiliar |
| Screen | Tela |
| View | Visualizacao |
| Model | Modelo |
| Widget | Widget |
| Provider | Provedor |
| Repository | Repositorio |
| Controller | Controlador |
| Handler | Manipulador |
| Formatter | Formatador |
| Builder | Construtor |
| Factory | Fabrica |
| Adapter | Adaptador |
| Converter | Conversor |
| Validator | Validador |
| Analyzer | Analisador |
| Extractor | Extrator |
| Loader | Carregador |
| Processor | Processador |
| Generator | Gerador |
| Calculator | Calculador |
| Checker | Verificador |
| Finder | Localizador |
| Sorter | Classificador |
| Filter | Filtro |
| Mapper | Mapeador |
| Transformer | Transformador |
| Logger | Registrador |
| Router | Roteador |
| Navigator | Navegador |
| Storage | Armazenamento |
| Database | BancoDados |
| Preferences | Preferencias |
| Settings | Configuracoes |
| Config | Configuracao |
| Constants | Constantes |
| Tests | Testes |
| Mocks | Simulacoes |

## Observações Finais

Este guia visa estabelecer um padrão para novos arquivos e classes, sem a necessidade de refatorar todo o código existente. A padronização será implementada gradualmente, à medida que novos arquivos forem criados ou arquivos existentes forem significativamente modificados.

Para uma lista mais completa de termos, consulte o arquivo `GUIA_PADRONIZACAO.md`.
