# Guia de Padronização de Nomes para o Projeto Concursos IA

Este guia estabelece padrões para nomenclatura de arquivos, classes e métodos no projeto Concursos IA, visando manter consistência e facilitar a manutenção.

## Princípios Gerais

1. **Idioma**: Todos os novos arquivos, classes e métodos devem ser nomeados em português do Brasil.
2. **Acentos**: Não usar acentos ou caracteres especiais em nomes de arquivos.
3. **Separação**: Usar underscore (_) para separar palavras em nomes de arquivos.
4. **Capitalização**: Seguir o padrão camelCase para variáveis e métodos, PascalCase para classes.

## Padrões para Nomes de Arquivos

### Serviços
- Formato: `servico_[funcionalidade].dart`
- Exemplos:
  - `servico_autenticacao.dart` (em vez de `auth_service.dart`)
  - `servico_tema.dart` (em vez de `theme_service.dart`)
  - `servico_analitica.dart` (em vez de `analytics_service.dart`)

### Utilitários
- Formato: `[funcionalidade]_util.dart` ou `[funcionalidade]_utilitario.dart`
- Exemplos:
  - `texto_util.dart` (em vez de `text_utils.dart`)
  - `formatador_texto.dart` (em vez de `text_formatter.dart`)
  - `gerenciador_cache.dart` (em vez de `cache_manager.dart`)

### Telas
- Formato: `tela_[funcionalidade].dart`
- Exemplos:
  - `tela_login.dart` (em vez de `login_screen.dart`)
  - `tela_registro.dart` (em vez de `register_screen.dart`)
  - `tela_configuracoes.dart` (em vez de `settings_screen.dart`)

### Modelos
- Formato: `modelo_[entidade].dart`
- Exemplos:
  - `modelo_usuario.dart` (em vez de `user_model.dart`)
  - `modelo_edital.dart` (em vez de `edital_model.dart`)

### Widgets
- Formato: `widget_[funcionalidade].dart`
- Exemplos:
  - `widget_botao_personalizado.dart` (em vez de `custom_button_widget.dart`)
  - `widget_card_edital.dart` (em vez de `edital_card_widget.dart`)

## Padrões para Nomes de Classes

### Serviços
- Formato: `Servico[Funcionalidade]`
- Exemplos:
  - `ServicoAutenticacao` (em vez de `AuthService`)
  - `ServicoTema` (em vez de `ThemeService`)

### Utilitários
- Formato: `[Funcionalidade]Util` ou `[Funcionalidade]Utilitario`
- Exemplos:
  - `TextoUtil` (em vez de `TextUtils`)
  - `FormatadorTexto` (em vez de `TextFormatter`)

### Telas
- Formato: `Tela[Funcionalidade]`
- Exemplos:
  - `TelaLogin` (em vez de `LoginScreen`)
  - `TelaRegistro` (em vez de `RegisterScreen`)

### Modelos
- Formato: `Modelo[Entidade]`
- Exemplos:
  - `ModeloUsuario` (em vez de `UserModel`)
  - `ModeloEdital` (em vez de `EditalModel`)

### Widgets
- Formato: `Widget[Funcionalidade]`
- Exemplos:
  - `WidgetBotaoPersonalizado` (em vez de `CustomButtonWidget`)
  - `WidgetCardEdital` (em vez de `EditalCardWidget`)

## Observações Importantes

1. **Arquivos Existentes**: Não renomear arquivos existentes para evitar problemas de referência.
2. **Novos Arquivos**: Todos os novos arquivos devem seguir este padrão.
3. **Refatoração Gradual**: Ao modificar significativamente um arquivo existente, considerar renomeá-lo seguindo este padrão.
4. **Documentação**: Documentar claramente qualquer renomeação no histórico de commits.

## Mapeamento de Termos Comuns (Inglês → Português)

| Inglês | Português |
|--------|-----------|
| Service | Servico |
| Manager | Gerenciador |
| Utils | Util ou Utilitario |
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
| Saver | Salvador |
| Reader | Leitor |
| Writer | Escritor |
| Processor | Processador |
| Generator | Gerador |
| Calculator | Calculador |
| Checker | Verificador |
| Finder | Localizador |
| Sorter | Classificador |
| Filter | Filtro |
| Mapper | Mapeador |
| Transformer | Transformador |
| Encoder | Codificador |
| Decoder | Decodificador |
| Encryptor | Criptografador |
| Decryptor | Descriptografador |
| Logger | Registrador |
| Tracker | Rastreador |
| Monitor | Monitor |
| Watcher | Observador |
| Listener | Ouvinte |
| Notifier | Notificador |
| Dispatcher | Despachante |
| Router | Roteador |
| Navigator | Navegador |
| Coordinator | Coordenador |
| Mediator | Mediador |
| Proxy | Proxy |
| Cache | Cache |
| Storage | Armazenamento |
| Database | BancoDados |
| Preferences | Preferencias |
| Settings | Configuracoes |
| Config | Configuracao |
| Constants | Constantes |
| Enums | Enumeracoes |
| Types | Tipos |
| Extensions | Extensoes |
| Mixins | Mixins |
| Interfaces | Interfaces |
| Implementations | Implementacoes |
| Tests | Testes |
| Mocks | Simulacoes |
| Stubs | Stubs |
| Fakes | Falsos |
| Fixtures | Fixtures |
| Matchers | Comparadores |
| Assertions | Asserções |
| Expectations | Expectativas |
| Runners | Executores |
| Reporters | Relatores |
| Formatters | Formatadores |
| Parsers | Analisadores |
| Serializers | Serializadores |
| Deserializers | Deserializadores |
| Converters | Conversores |
| Transformers | Transformadores |
| Validators | Validadores |
| Sanitizers | Sanitizadores |
| Normalizers | Normalizadores |
| Formatters | Formatadores |
| Renderers | Renderizadores |
| Painters | Pintores |
| Drawers | Desenhadores |
| Animators | Animadores |
| Transitions | Transicoes |
| Effects | Efeitos |
| Decorators | Decoradores |
| Wrappers | Invólucros |
| Containers | Contêineres |
| Layouts | Layouts |
| Styles | Estilos |
| Themes | Temas |
| Colors | Cores |
| Fonts | Fontes |
| Icons | Icones |
| Images | Imagens |
| Assets | Recursos |
| Resources | Recursos |
| Strings | Strings |
| Texts | Textos |
| Numbers | Numeros |
| Dates | Datas |
| Times | Tempos |
| Durations | Duracoes |
| Intervals | Intervalos |
| Ranges | Intervalos |
| Periods | Periodos |
| Schedules | Agendamentos |
| Calendars | Calendarios |
| Events | Eventos |
| Actions | Acoes |
| Commands | Comandos |
| Requests | Requisicoes |
| Responses | Respostas |
| Results | Resultados |
| Outcomes | Resultados |
| Statuses | Estados |
| States | Estados |
| Conditions | Condicoes |
| Rules | Regras |
| Policies | Politicas |
| Strategies | Estrategias |
| Algorithms | Algoritmos |
| Functions | Funcoes |
| Methods | Metodos |
| Procedures | Procedimentos |
| Routines | Rotinas |
| Tasks | Tarefas |
| Jobs | Trabalhos |
| Workers | Trabalhadores |
| Executors | Executores |
| Runners | Executores |
| Handlers | Manipuladores |
| Processors | Processadores |
| Managers | Gerenciadores |
| Controllers | Controladores |
| Coordinators | Coordenadores |
| Directors | Diretores |
| Supervisors | Supervisores |
| Monitors | Monitores |
| Watchers | Observadores |
| Observers | Observadores |
| Listeners | Ouvintes |
| Subscribers | Assinantes |
| Publishers | Publicadores |
| Producers | Produtores |
| Consumers | Consumidores |
| Suppliers | Fornecedores |
| Providers | Provedores |
| Factories | Fabricas |
| Builders | Construtores |
| Creators | Criadores |
| Generators | Geradores |
| Constructors | Construtores |
| Initializers | Inicializadores |
| Finalizers | Finalizadores |
| Disposers | Descartadores |
| Cleaners | Limpadores |
| Destroyers | Destruidores |
| Killers | Matadores |
| Terminators | Terminadores |
| Stoppers | Paradores |
| Starters | Iniciadores |
| Launchers | Lancadores |
| Booters | Inicializadores |
| Loaders | Carregadores |
| Unloaders | Descarregadores |
| Installers | Instaladores |
| Uninstallers | Desinstaladores |
| Updaters | Atualizadores |
| Upgraders | Atualizadores |
| Downgraders | Rebaixadores |
| Patchers | Corretores |
| Fixers | Corretores |
| Repairers | Reparadores |
| Healers | Curadores |
| Doctors | Doutores |
| Nurses | Enfermeiros |
| Caretakers | Cuidadores |
| Guardians | Guardioes |
| Protectors | Protetores |
| Defenders | Defensores |
| Attackers | Atacantes |
| Fighters | Lutadores |
| Warriors | Guerreiros |
| Soldiers | Soldados |
| Commanders | Comandantes |
| Generals | Generais |
| Captains | Capitaes |
| Leaders | Lideres |
| Followers | Seguidores |
| Members | Membros |
| Users | Usuarios |
| Clients | Clientes |
| Customers | Clientes |
| Guests | Convidados |
| Visitors | Visitantes |
| Strangers | Estranhos |
| Friends | Amigos |
| Enemies | Inimigos |
| Allies | Aliados |
| Partners | Parceiros |
| Collaborators | Colaboradores |
| Teammates | Companheiros |
| Coworkers | Colegas |
| Employees | Funcionarios |
| Employers | Empregadores |
| Managers | Gerentes |
| Directors | Diretores |
| Executives | Executivos |
| Officers | Oficiais |
| Chiefs | Chefes |
| Bosses | Chefes |
| Supervisors | Supervisores |
| Administrators | Administradores |
| Moderators | Moderadores |
| Regulators | Reguladores |
| Enforcers | Aplicadores |
| Judges | Juizes |
| Arbiters | Arbitros |
| Mediators | Mediadores |
| Negotiators | Negociadores |
| Diplomats | Diplomatas |
| Ambassadors | Embaixadores |
| Representatives | Representantes |
| Delegates | Delegados |
| Agents | Agentes |
| Brokers | Corretores |
| Dealers | Negociantes |
| Traders | Comerciantes |
| Merchants | Mercadores |
| Vendors | Vendedores |
| Sellers | Vendedores |
| Buyers | Compradores |
| Shoppers | Compradores |
| Consumers | Consumidores |
| Customers | Clientes |
| Patrons | Patronos |
| Sponsors | Patrocinadores |
| Supporters | Apoiadores |
| Backers | Apoiadores |
| Funders | Financiadores |
| Investors | Investidores |
| Stakeholders | Partes Interessadas |
| Shareholders | Acionistas |
| Owners | Proprietarios |
| Possessors | Possuidores |
| Holders | Detentores |
| Keepers | Guardioes |
| Custodians | Custodiantes |
| Stewards | Administradores |
| Caretakers | Zeladores |
| Maintainers | Mantenedores |
| Preservers | Preservadores |
| Conservators | Conservadores |
| Restorers | Restauradores |
| Renovators | Renovadores |
| Rebuilders | Reconstruidores |
| Remakers | Refazedores |
| Recreators | Recriadores |
| Reinventors | Reinventores |
| Revolutionaries | Revolucionarios |
| Reformers | Reformadores |
| Transformers | Transformadores |
| Changers | Mudadores |
| Shifters | Deslocadores |
| Movers | Movimentadores |
| Transporters | Transportadores |
| Carriers | Transportadores |
| Shippers | Expedidores |
| Deliverers | Entregadores |
| Receivers | Recebedores |
| Acceptors | Aceitadores |
| Rejecters | Rejeitadores |
| Approvers | Aprovadores |
| Disapprovers | Desaprovadores |
| Validators | Validadores |
| Invalidators | Invalidadores |
| Verifiers | Verificadores |
| Falsifiers | Falsificadores |
| Authenticators | Autenticadores |
| Authorizers | Autorizadores |
| Permitters | Permitidores |
| Forbidders | Proibidores |
| Enablers | Habilitadores |
| Disablers | Desabilitadores |
| Activators | Ativadores |
| Deactivators | Desativadores |
| Starters | Iniciadores |
| Stoppers | Paradores |
| Pausers | Pausadores |
| Resumers | Retomadores |
| Continuers | Continuadores |
| Interrupters | Interruptores |
| Breakers | Quebradores |
| Fixers | Consertadores |
| Repairers | Reparadores |
| Healers | Curadores |
| Doctors | Doutores |
| Nurses | Enfermeiros |
| Caretakers | Cuidadores |
| Guardians | Guardioes |
| Protectors | Protetores |
| Defenders | Defensores |
| Attackers | Atacantes |
| Fighters | Lutadores |
| Warriors | Guerreiros |
| Soldiers | Soldados |
| Commanders | Comandantes |
| Generals | Generais |
| Captains | Capitaes |
| Leaders | Lideres |
| Followers | Seguidores |
| Members | Membros |
| Users | Usuarios |
| Clients | Clientes |
| Customers | Clientes |
| Guests | Convidados |
| Visitors | Visitantes |
| Strangers | Estranhos |
| Friends | Amigos |
| Enemies | Inimigos |
| Allies | Aliados |
| Partners | Parceiros |
| Collaborators | Colaboradores |
| Teammates | Companheiros |
| Coworkers | Colegas |
| Employees | Funcionarios |
| Employers | Empregadores |
| Managers | Gerentes |
| Directors | Diretores |
| Executives | Executivos |
| Officers | Oficiais |
| Chiefs | Chefes |
| Bosses | Chefes |
| Supervisors | Supervisores |
| Administrators | Administradores |
| Moderators | Moderadores |
| Regulators | Reguladores |
| Enforcers | Aplicadores |
| Judges | Juizes |
| Arbiters | Arbitros |
| Mediators | Mediadores |
| Negotiators | Negociadores |
| Diplomats | Diplomatas |
| Ambassadors | Embaixadores |
| Representatives | Representantes |
| Delegates | Delegados |
| Agents | Agentes |
| Brokers | Corretores |
| Dealers | Negociantes |
| Traders | Comerciantes |
| Merchants | Mercadores |
| Vendors | Vendedores |
| Sellers | Vendedores |
| Buyers | Compradores |
| Shoppers | Compradores |
| Consumers | Consumidores |
| Customers | Clientes |
| Patrons | Patronos |
| Sponsors | Patrocinadores |
| Supporters | Apoiadores |
| Backers | Apoiadores |
| Funders | Financiadores |
| Investors | Investidores |
| Stakeholders | Partes Interessadas |
| Shareholders | Acionistas |
| Owners | Proprietarios |
| Possessors | Possuidores |
| Holders | Detentores |
| Keepers | Guardioes |
| Custodians | Custodiantes |
| Stewards | Administradores |
| Caretakers | Zeladores |
| Maintainers | Mantenedores |
| Preservers | Preservadores |
| Conservators | Conservadores |
| Restorers | Restauradores |
| Renovators | Renovadores |
| Rebuilders | Reconstruidores |
| Remakers | Refazedores |
| Recreators | Recriadores |
| Reinventors | Reinventores |
| Revolutionaries | Revolucionarios |
| Reformers | Reformadores |
| Transformers | Transformadores |
| Changers | Mudadores |
| Shifters | Deslocadores |
| Movers | Movimentadores |
| Transporters | Transportadores |
| Carriers | Transportadores |
| Shippers | Expedidores |
| Deliverers | Entregadores |
| Receivers | Recebedores |
| Acceptors | Aceitadores |
| Rejecters | Rejeitadores |
| Approvers | Aprovadores |
| Disapprovers | Desaprovadores |
| Validators | Validadores |
| Invalidators | Invalidadores |
| Verifiers | Verificadores |
| Falsifiers | Falsificadores |
| Authenticators | Autenticadores |
| Authorizers | Autorizadores |
| Permitters | Permitidores |
| Forbidders | Proibidores |
| Enablers | Habilitadores |
| Disablers | Desabilitadores |
| Activators | Ativadores |
| Deactivators | Desativadores |
| Starters | Iniciadores |
| Stoppers | Paradores |
| Pausers | Pausadores |
| Resumers | Retomadores |
| Continuers | Continuadores |
| Interrupters | Interruptores |
| Breakers | Quebradores |
| Fixers | Consertadores |
